// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseHook} from "@uniswap/v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {
    BeforeSwapDelta,
    BeforeSwapDeltaLibrary,
    toBeforeSwapDelta
} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";

import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {IAegisPolicy} from "./interfaces/IAegisPolicy.sol";
import {IAegisReserve} from "./interfaces/IAegisReserve.sol";
import {IAegisOracle} from "./interfaces/IAegisOracle.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {LPFeeLibrary} from "@uniswap/v4-core/src/libraries/LPFeeLibrary.sol";
import {FullMath} from "@uniswap/v4-core/src/libraries/FullMath.sol";
import {FixedPoint96} from "@uniswap/v4-core/src/libraries/FixedPoint96.sol";
import {SafeCast} from "@uniswap/v4-core/src/libraries/SafeCast.sol";

import {
    Currency,
    CurrencyLibrary
} from "@uniswap/v4-core/src/types/Currency.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AegisHook is BaseHook {
    using PoolIdLibrary for PoolKey;
    using StateLibrary for IPoolManager;
    using CurrencyLibrary for Currency;
    using LPFeeLibrary for uint24;
    using SafeERC20 for IERC20;

    // --- State ---
    IAegisPolicy public policy;
    IAegisReserve public reserve;
    IAegisOracle public oracle;

    struct SwapQuote {
        uint160 sqrtPriceX96;
        IAegisPolicy.CoverageTier tier;
        uint256 premium;
        bool zeroForOne;
        uint24 fee;
    }

    // Maps swapper to their current swap quote (recorded in beforeSwap)
    mapping(address => SwapQuote) public activeQuotes;

    // --- Market Influx Tracking (Dynamic Fees) ---
    uint128 public movingAverageGasPrice;
    uint104 public movingAverageGasPriceCount;

    // Base fee is statically set at 30 bps (0.3%)
    uint24 public constant BASE_FEE = 3000;

    // --- Events and Errors ---
    event InsuranceQuoted(
        address indexed swapper,
        uint160 price,
        IAegisPolicy.CoverageTier tier
    );
    event CompensationTriggered(address indexed swapper, uint256 amount);
    event SwapCovered(address indexed swapper, uint256 premium, uint256 amount);
    event ClaimPaid(address indexed swapper, uint256 compensation);

    error MustUseDynamicFee();

    constructor(
        IPoolManager _poolManager,
        address _policy,
        address _reserve,
        address _oracle
    ) BaseHook(_poolManager) {
        policy = IAegisPolicy(_policy);
        reserve = IAegisReserve(_reserve);
        oracle = IAegisOracle(_oracle);

        // Initialize moving average with current gas price
        updateMovingAverage();
    }

    // --- Dynamic Fee Logic ---
    function updateMovingAverage() internal {
        uint128 gasPrice = uint128(tx.gasprice);

        // New Average = ((Old Average * # of Txns Tracked) + Current Gas Price) / (# of Txns Tracked + 1)
        movingAverageGasPrice =
            ((movingAverageGasPrice * movingAverageGasPriceCount) + gasPrice) /
            (movingAverageGasPriceCount + 1);

        movingAverageGasPriceCount++;
    }

    function getFee() internal view returns (uint24) {
        uint128 gasPrice = uint128(tx.gasprice);

        // If gas price is > 10% higher than average, reduce fee to keep swaps attractive
        if (gasPrice > (movingAverageGasPrice * 11) / 10) {
            return BASE_FEE / 2;
        }

        // If gas price is < 10% lower than average, increase fee to capture value in quiet blocks
        if (gasPrice < (movingAverageGasPrice * 9) / 10) {
            return BASE_FEE * 2;
        }

        return BASE_FEE;
    }

    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        return
            Hooks.Permissions({
                beforeInitialize: true,
                afterInitialize: false,
                beforeAddLiquidity: false,
                afterAddLiquidity: false,
                beforeRemoveLiquidity: false,
                afterRemoveLiquidity: false,
                beforeSwap: true,
                afterSwap: true,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: true,
                afterSwapReturnDelta: false,

                afterAddLiquidityReturnDelta: false,
                afterRemoveLiquidityReturnDelta: false
            });
    }

    function _beforeInitialize(
        address,
        PoolKey calldata key,
        uint160
    ) internal pure override returns (bytes4) {
        if (!key.fee.isDynamicFee()) revert MustUseDynamicFee();
        return BaseHook.beforeInitialize.selector;
    }

    function _beforeSwap(
        address swapper,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata hookData
    ) internal override returns (bytes4, BeforeSwapDelta, uint24) {
        // 1. Get Market Volatility Signal from Oracle for Insurance Premium
        uint256 volatilitySignal = oracle.getVolatilitySignal(key.toId());

        // 2. Calculate dynamic fee based on network influx (gas price)
        uint24 dynamicFee = getFee();

        uint256 amountSpecified = params.amountSpecified > 0
            ? uint256(params.amountSpecified)
            : uint256(-params.amountSpecified);

        // 3. Handle Insurance Tier (passed via hookData)
        IAegisPolicy.CoverageTier tier = IAegisPolicy.CoverageTier.None;
        if (hookData.length > 0) {
            tier = abi.decode(hookData, (IAegisPolicy.CoverageTier));
        }

        // 4. Record Quote & Update Oracle
        (uint160 sqrtPriceX96, int24 tick, , ) = poolManager.getSlot0(
            key.toId()
        );

        oracle.updateObservation(key.toId(), tick);

        // 5. Calculate and Collect Premium (In production, pull from swapper)
        if (tier != IAegisPolicy.CoverageTier.None) {
            // Calculate premium
            uint256 premium = policy.calculatePremium(
                IAegisPolicy.PolicyParams({
                    swapSize: amountSpecified,
                    poolLiquidity: poolManager.getLiquidity(key.toId()),
                    baseFee: dynamicFee,
                    volatilitySignal: volatilitySignal,
                    tier: tier
                })
            );

            // save quote with calculated premium
            activeQuotes[swapper] = SwapQuote({
                sqrtPriceX96: sqrtPriceX96,
                tier: tier,
                premium: premium,
                zeroForOne: params.zeroForOne,
                fee: dynamicFee
            });

            // Collect premium directly from swapper via transferFrom
            Currency inputCurrency = params.zeroForOne ? key.currency0 : key.currency1;
            address inputToken = Currency.unwrap(inputCurrency);
            IERC20(inputToken).safeTransferFrom(swapper, address(reserve), premium);
            reserve.depositPremium(inputToken, premium);

            // BeforeSwapDelta: tell PoolManager the hook consumed `premium` from the input side
            // so the swap proceeds on (amountSpecified - premium)
            BeforeSwapDelta hookDelta;
            if (params.amountSpecified < 0) {
                // Exact In: reduce input by premium
                hookDelta = toBeforeSwapDelta(int128(int256(premium)), 0);
            } else {
                // Exact Out: charge premium on unspecified (input) side
                hookDelta = toBeforeSwapDelta(0, int128(int256(premium)));
            }


            emit InsuranceQuoted(swapper, sqrtPriceX96, tier);
            emit SwapCovered(swapper, premium, amountSpecified);

            return (
                BaseHook.beforeSwap.selector,
                hookDelta,
                dynamicFee | LPFeeLibrary.OVERRIDE_FEE_FLAG
            );
        }

        return (
            BaseHook.beforeSwap.selector,
            BeforeSwapDeltaLibrary.ZERO_DELTA,
            dynamicFee | LPFeeLibrary.OVERRIDE_FEE_FLAG // Signal override fee
        );

    }

    function _afterSwap(
        address swapper,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata
    ) internal override returns (bytes4, int128) {
        SwapQuote memory quote = activeQuotes[swapper];

        // If no quote exists, swapper had None tier - skip everything
        if (quote.sqrtPriceX96 == 0) {
            updateMovingAverage();

            return (BaseHook.afterSwap.selector, 0);
        }

        // Split logic based on Exact Input vs Exact Output
        uint256 compensation = 0;
        Currency compCurrency;

        // Get actual amounts swapped from delta
        int128 amount0Delta = delta.amount0();
        int128 amount1Delta = delta.amount1();

        uint256 actualIn = uint256(SafeCast.toUint128(
            quote.zeroForOne ? (amount0Delta > 0 ? amount0Delta : -amount0Delta) : (amount1Delta > 0 ? amount1Delta : -amount1Delta)
        ));
        uint256 actualOut = uint256(SafeCast.toUint128(
            quote.zeroForOne ? (amount1Delta > 0 ? amount1Delta : -amount1Delta) : (amount0Delta > 0 ? amount0Delta : -amount0Delta)
        ));

        if (params.amountSpecified < 0) {
            // --- EXACT INPUT ---
            // Calculate expected output based on the ACTUAL input amount
            uint256 amountInAfterFee = actualIn - FullMath.mulDiv(actualIn, quote.fee, 1_000_000);


            // Step 2: Calculate expected output using FullMath to avoid overflow
            uint256 expectedOut;
            if (quote.zeroForOne) {
                // selling token0 for token1
                // expectedOut = amountInAfterFee * price
                expectedOut = FullMath.mulDiv(
                    amountInAfterFee,
                    FullMath.mulDiv(
                        uint256(quote.sqrtPriceX96),
                        uint256(quote.sqrtPriceX96),
                        FixedPoint96.Q96
                    ),
                    FixedPoint96.Q96
                );
            } else {
                // selling token1 for token0
                // expectedOut = amountInAfterFee / price
                expectedOut = FullMath.mulDiv(
                    amountInAfterFee,
                    FixedPoint96.Q96,
                    FullMath.mulDiv(
                        uint256(quote.sqrtPriceX96),
                        uint256(quote.sqrtPriceX96),
                        FixedPoint96.Q96
                    )
                );
            }


            compensation = policy.calculateCompensation(
                expectedOut,
                actualOut,
                quote.tier
            );
            compCurrency = quote.zeroForOne ? key.currency1 : key.currency0;

        } else {
            // --- EXACT OUTPUT ---
            // Calculate expected input based on the ACTUAL output amount
            uint256 expectedInNoFee;

            if (quote.zeroForOne) {
                // selling token0 for token1
                // expectedIn = amountOut / price
                expectedInNoFee = FullMath.mulDiv(
                    actualOut,
                    FixedPoint96.Q96,
                    FullMath.mulDiv(
                        uint256(quote.sqrtPriceX96),
                        uint256(quote.sqrtPriceX96),
                        FixedPoint96.Q96
                    )
                );
            } else {

                expectedInNoFee = FullMath.mulDiv(
                    actualOut,
                    FullMath.mulDiv(
                        uint256(quote.sqrtPriceX96),
                        uint256(quote.sqrtPriceX96),
                        FixedPoint96.Q96
                    ),
                    FixedPoint96.Q96
                );
            }


            // Step 2: Adjust for fee
            uint256 expectedIn = FullMath.mulDiv(
                expectedInNoFee,
                1_000_000,
                1_000_000 - quote.fee
            );

            compensation = policy.calculateExactOutputCompensation(
                expectedIn,
                actualIn,
                quote.tier
            );
            compCurrency = quote.zeroForOne ? key.currency0 : key.currency1;

        }

        delete activeQuotes[swapper];

        if (compensation > 0) {
            reserve.recordClaim(
                swapper,
                Currency.unwrap(compCurrency),
                compensation
            );
            emit CompensationTriggered(swapper, compensation);
            emit ClaimPaid(swapper, compensation);
        }

        // Update Moving Average for Dynamic Fees after swap
        updateMovingAverage();

        return (BaseHook.afterSwap.selector, 0);
    }
}
