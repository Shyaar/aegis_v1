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
    BeforeSwapDeltaLibrary
} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {IAegisPolicy} from "./interfaces/IAegisPolicy.sol";
import {IAegisReserve} from "./interfaces/IAegisReserve.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";

contract AegisHook is BaseHook {
    using PoolIdLibrary for PoolKey;
    using StateLibrary for IPoolManager;

    // --- State ---
    IAegisPolicy public policy;
    IAegisReserve public reserve;

    struct SwapQuote {
        uint160 sqrtPriceX96;
        IAegisPolicy.CoverageTier tier;
        uint256 premium;
    }

    // Maps swapper to their current swap quote (recorded in beforeSwap)
    // In production, this should use Transient Storage
    mapping(address => SwapQuote) public activeQuotes;

    // --- Events ---
    event InsuranceQuoted(address indexed swapper, uint160 price, IAegisPolicy.CoverageTier tier);
    event CompensationTriggered(address indexed swapper, uint256 amount);

    constructor(IPoolManager _poolManager, address _policy, address _reserve) BaseHook(_poolManager) {
        policy = IAegisPolicy(_policy);
        reserve = IAegisReserve(_reserve);
    }

    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        return
            Hooks.Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: false,
                afterAddLiquidity: false,
                beforeRemoveLiquidity: false,
                afterRemoveLiquidity: false,
                beforeSwap: true,
                afterSwap: true,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: false,
                afterSwapReturnDelta: false,
                afterAddLiquidityReturnDelta: false,
                afterRemoveLiquidityReturnDelta: false
            });
    }

    function _beforeSwap(
        address swapper,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata hookData
    ) internal override returns (bytes4, BeforeSwapDelta, uint24) {
        // 1. Get Market Influx (Volatility Signal)
        // For simplicity, we use the distance from current tick to a reference point or just mock
        uint256 volatilitySignal = 100; // 1% movement (mock)
        
        // 2. Calculate Dynamic Fee
        // In v4, if the pool uses a hook fee, we return the fee here
        uint24 dynamicFee = policy.calculateDynamicFee(key.fee, volatilitySignal);

        // 3. Handle Insurance Tier (passed via hookData)
        IAegisPolicy.CoverageTier tier = IAegisPolicy.CoverageTier.Standard;
        if (hookData.length > 0) {
            tier = abi.decode(hookData, (IAegisPolicy.CoverageTier));
        }

        // 4. Record Quote
        (uint160 sqrtPriceX96,,,) = poolManager.getSlot0(key.toId());
        
        uint256 premium = policy.calculatePremium(IAegisPolicy.PolicyParams({
            swapSize: params.amountSpecified > 0 ? uint256(params.amountSpecified) : uint256(-params.amountSpecified),
            poolLiquidity: poolManager.getLiquidity(key.toId()),
            baseFee: key.fee,
            volatilitySignal: volatilitySignal,
            tier: tier
        }));

        activeQuotes[swapper] = SwapQuote({
            sqrtPriceX96: sqrtPriceX96,
            tier: tier,
            premium: premium
        });

        // 5. Collect Premium
        reserve.depositPremium(premium);

        emit InsuranceQuoted(swapper, sqrtPriceX96, tier);

        return (
            BaseHook.beforeSwap.selector,
            BeforeSwapDeltaLibrary.ZERO_DELTA,
            dynamicFee | uint24(1 << 23) // Signal override fee if pool allows
        );
    }

    function _afterSwap(
        address swapper,
        PoolKey calldata,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata
    ) internal override returns (bytes4, int128) {
        SwapQuote memory quote = activeQuotes[swapper];
        
        // Calculate Expected vs Actual
        // This is a simplified comparison for the POC
        uint256 expectedOut = 1000; // Mock calculation based on quote.sqrtPriceX96
        uint256 actualOut;
        int128 a1 = delta.amount1();
        if (a1 > 0) {
            actualOut = uint128(a1);
        } else {
            actualOut = uint128(-a1);
        }

        uint256 compensation = policy.calculateCompensation(expectedOut, actualOut, quote.tier);

        if (compensation > 0) {
            reserve.recordClaim(swapper, compensation);
            emit CompensationTriggered(swapper, compensation);
        }

        // Clean up
        delete activeQuotes[swapper];

        return (BaseHook.afterSwap.selector, 0);
    }
}
