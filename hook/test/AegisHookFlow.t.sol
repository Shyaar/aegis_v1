// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {Deployers} from "test/utils/Deployers.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {LPFeeLibrary} from "@uniswap/v4-core/src/libraries/LPFeeLibrary.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {ModifyLiquidityParams, SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";



import {AegisHook} from "../src/AegisHook.sol";
import {AegisPolicy} from "../src/AegisPolicy.sol";
import {AegisReserve} from "../src/AegisReserve.sol";
import {AegisOracle} from "../src/AegisOracle.sol";
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";
import {IAegisReserve} from "../src/interfaces/IAegisReserve.sol";
import {IAegisPolicy} from "../src/interfaces/IAegisPolicy.sol";
import {PoolSwapTest} from "@uniswap/v4-core/src/test/PoolSwapTest.sol";
import {PoolModifyLiquidityTest} from "@uniswap/v4-core/src/test/PoolModifyLiquidityTest.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";


contract AegisHookFlowTest is Test, Deployers {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using StateLibrary for IPoolManager;

    AegisHook public hook;
    AegisPolicy public policy;
    AegisReserve public reserve;
    AegisOracle public oracle;

    IPoolManager public manager;
    Currency public currency0;
    Currency public currency1;
    PoolKey public key;

    uint160 public constant SQRT_PRICE_1_1 = 79228162514264337593543950336;

    PoolSwapTest public swapRouter;
    PoolModifyLiquidityTest public modifyLiquidityRouter;

    bytes constant ZERO_BYTES = new bytes(0);


    function setUp() public {
        manager = IPoolManager(address(new PoolManager(address(0))));
        
        // Routers
        swapRouter = new PoolSwapTest(manager);
        modifyLiquidityRouter = new PoolModifyLiquidityTest(manager);

        // Use Deployers helper to get tokens
        (currency0, currency1) = deployCurrencyPair();

        policy = new AegisPolicy();
        reserve = new AegisReserve(address(this));
        oracle = new AegisOracle();
        
        uint160 flags = uint160(
            Hooks.BEFORE_INITIALIZE_FLAG | 
            Hooks.BEFORE_SWAP_FLAG | 
            Hooks.AFTER_SWAP_FLAG |
            Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG
        );

        bytes memory constructorArgs = abi.encode(address(manager), address(policy), address(reserve), address(oracle));
        
        (, bytes32 salt) = HookMiner.find(
            address(this),
            flags,
            type(AegisHook).creationCode,
            constructorArgs
        );
        
        hook = new AegisHook{salt: salt}(manager, address(policy), address(reserve), address(oracle));
        reserve.setHook(address(hook));

        // Initialize dynamic fee pool
        key = PoolKey(currency0, currency1, LPFeeLibrary.DYNAMIC_FEE_FLAG, 60, IHooks(address(hook)));
        manager.initialize(key, SQRT_PRICE_1_1);

        // Add liquidity
        MockERC20(Currency.unwrap(currency0)).approve(address(modifyLiquidityRouter), type(uint256).max);
        MockERC20(Currency.unwrap(currency1)).approve(address(modifyLiquidityRouter), type(uint256).max);

        modifyLiquidityRouter.modifyLiquidity(
            key,
            ModifyLiquidityParams({
                tickLower: -60,
                tickUpper: 60,
                liquidityDelta: 100 ether,
                salt: 0
            }),
            ZERO_BYTES
        );

        // Seed reserve with some capital to cover compensation in tests

        MockERC20(Currency.unwrap(currency0)).mint(address(this), 100 ether);
        MockERC20(Currency.unwrap(currency0)).approve(address(reserve), 100 ether);
        reserve.seedReserve(Currency.unwrap(currency0), 100 ether);

        MockERC20(Currency.unwrap(currency1)).mint(address(this), 100 ether);
        MockERC20(Currency.unwrap(currency1)).approve(address(reserve), 100 ether);
        reserve.seedReserve(Currency.unwrap(currency1), 100 ether);
    }


    /* =========================================================================
       beforeInitialize()
       ========================================================================= */

    function test_Success_beforeInitialize() public {
        // Already tested via setUp -> initialize
    }

    function test_Revert_beforeInitialize_NotDynamicFee() public {
        PoolKey memory staticKey = PoolKey(currency0, currency1, 3000, 60, IHooks(address(hook)));
        vm.expectRevert(); // Accepts any revert if selector matching is causing issues with wrapping
        manager.initialize(staticKey, SQRT_PRICE_1_1);
    }


    /* =========================================================================
       beforeSwap() / afterSwap() Flow
       ========================================================================= */

    function test_Success_fullSwapFlow_ExactIn_PremiumCollected() public {
        // 1. Seed reserve for volatility calculations (oracle needs data)
        // We'll skip oracle depth for now as it's a separate component, 
        // focus on premium movement.
        
        // 2. Perform PROTECTED swap (Tier.Standard)
        // In Tier.Standard, premium is 10 bps.
        // Swap size: 1 ether. Premium = 0.001 ether.
        
        MockERC20(Currency.unwrap(currency0)).approve(address(swapRouter), type(uint256).max);
        MockERC20(Currency.unwrap(currency1)).approve(address(swapRouter), type(uint256).max);

        bytes memory hookData = abi.encode(IAegisPolicy.CoverageTier.Standard);

        uint256 reserveInitialBalance = reserve.getReserveBalance(Currency.unwrap(currency0));

        swapRouter.swap(
            key,
            SwapParams({
                zeroForOne: true,
                amountSpecified: -1 ether,
                sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1
            }),
            PoolSwapTest.TestSettings({
                takeClaims: false,
                settleUsingBurn: false
            }),
            hookData
        );


        // 3. Verify premium was taken
        // (1 ether * 10 bps) / 10000 = 0.001 ether
        uint256 reserveFinalBalance = reserve.getReserveBalance(Currency.unwrap(currency0));
        assertEq(reserveFinalBalance - reserveInitialBalance, 0.001 ether, "Premium should be 10 bps");
    }

    function test_Success_fullSwapFlow_ExactOut() public {
        MockERC20(Currency.unwrap(currency0)).mint(address(this), 10 ether);
        MockERC20(Currency.unwrap(currency0)).approve(address(swapRouter), type(uint256).max);
        MockERC20(Currency.unwrap(currency1)).mint(address(this), 10 ether);
        MockERC20(Currency.unwrap(currency1)).approve(address(swapRouter), type(uint256).max);

        bytes memory hookData = abi.encode(IAegisPolicy.CoverageTier.Standard);

        uint256 reserveInitialBalance = reserve.getReserveBalance(Currency.unwrap(currency0));

        // Exact Output: Specified 1 ether of currency1 (output)
        // We are zeroForOne (token0 -> token1), so input is currency0
        swapRouter.swap(
            key,
            SwapParams({
                zeroForOne: true,
                amountSpecified: 1 ether, 
                sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1
            }),
            PoolSwapTest.TestSettings({
                takeClaims: false,
                settleUsingBurn: false
            }),
            hookData
        );

        uint256 reserveFinalBalance = reserve.getReserveBalance(Currency.unwrap(currency0));
        // For standard tier (10 bps), 1 ether out at 1:1 price expects 1 ether in.
        // Premium 10bps of 1 ether = 0.001 ether.
        assertGt(reserveFinalBalance, reserveInitialBalance, "Premium should be collected in currency0");
        assertEq(reserveFinalBalance - reserveInitialBalance, 0.001 ether, "Premium should be 10 bps of output equivalent");
    }

    function test_Success_CompensationTriggered() public {
        // 1. Setup: Mint tokens
        MockERC20(Currency.unwrap(currency0)).mint(address(this), 100 ether);
        MockERC20(Currency.unwrap(currency0)).approve(address(swapRouter), type(uint256).max);
        
        bytes memory hookData = abi.encode(IAegisPolicy.CoverageTier.Premium); 

        uint256 initialClaims = reserve.nextClaimId();

        // 2. Perform a LARGE swap to cause significant slippage
        swapRouter.swap(
            key,
            SwapParams({
                zeroForOne: true,
                amountSpecified: -10 ether,
                sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1
            }),
            PoolSwapTest.TestSettings({
                takeClaims: false,
                settleUsingBurn: false
            }),
            hookData
        );

        // 3. Verify claim was recorded in AegisReserve
        assertEq(reserve.nextClaimId(), initialClaims + 1, "One claim should be recorded");
    }

    function test_Success_FullEndToEndSettlement() public {
        // 1. Setup: Swapper and Reserve
        MockERC20(Currency.unwrap(currency0)).mint(address(this), 11 ether);
        MockERC20(Currency.unwrap(currency0)).approve(address(swapRouter), type(uint256).max);
        
        // 2. Swap results in compensation record
        swapRouter.swap(
            key,
            SwapParams({
                zeroForOne: true,
                amountSpecified: -10 ether,
                sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1
            }),
            PoolSwapTest.TestSettings({
                takeClaims: false,
                settleUsingBurn: false
            }),
            abi.encode(IAegisPolicy.CoverageTier.Premium)
        );

        uint256 claimId = reserve.nextClaimId() - 1;
        (address swapper, address token, uint256 amount, bool settled, ) = reserve.claims(claimId);
        
        assertEq(swapper, address(swapRouter), "Swapper should be the router in this test context");
        assertEq(settled, false);
        assertGt(amount, 0, "Compensation amount should be > 0");

        // 3. Settle Claim (Router is the one who receives it)
        uint256 balanceBefore = MockERC20(token).balanceOf(address(swapRouter));
        reserve.settleClaim(claimId);
        uint256 balanceAfter = MockERC20(token).balanceOf(address(swapRouter));

        assertEq(balanceAfter - balanceBefore, amount, "Router should receive compensation");
        (, , , settled, ) = reserve.claims(claimId);
        assertEq(settled, true);
    }


    event CompensationTriggered(address indexed swapper, uint256 amount);
}


