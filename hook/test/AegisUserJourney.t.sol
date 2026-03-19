// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {Deployers} from "test/utils/Deployers.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {LPFeeLibrary} from "@uniswap/v4-core/src/libraries/LPFeeLibrary.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {ModifyLiquidityParams, SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";

import {AegisHook} from "../src/AegisHook.sol";
import {AegisPolicy} from "../src/AegisPolicy.sol";
import {AegisReserve} from "../src/AegisReserve.sol";
import {AegisOracle} from "../src/AegisOracle.sol";
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";
import {IAegisPolicy} from "../src/interfaces/IAegisPolicy.sol";
import {PoolSwapTest} from "@uniswap/v4-core/src/test/PoolSwapTest.sol";
import {PoolModifyLiquidityTest} from "@uniswap/v4-core/src/test/PoolModifyLiquidityTest.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";

/**
 * @title AegisUserJourneyTest
 * @notice End-to-end user journey tests.
 *
 * A named `user` swaps with protection via hookData(tier, user).
 * The hook records the user as the swapper — not the router.
 *
 * Two scenarios:
 *  1. Deep pool  → no slippage → no claim → assert actualOut >= expectedOut
 *  2. Thin pool  → slippage    → claim recorded for user → user settles → balance restored
 */
contract AegisUserJourneyTest is Test, Deployers {
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

    PoolSwapTest public swapRouter;
    PoolModifyLiquidityTest public modifyLiquidityRouter;

    address public user = makeAddr("user");

    uint160 constant SQRT_PRICE_1_1 = 79228162514264337593543950336;

    function setUp() public {
        manager = IPoolManager(address(new PoolManager(address(0))));
        swapRouter = new PoolSwapTest(manager);
        modifyLiquidityRouter = new PoolModifyLiquidityTest(manager);

        (currency0, currency1) = deployCurrencyPair();

        policy = new AegisPolicy(address(this), address(this));
        reserve = new AegisReserve(address(this));
        oracle = new AegisOracle();

        uint160 flags = uint160(
            Hooks.BEFORE_INITIALIZE_FLAG |
            Hooks.BEFORE_SWAP_FLAG |
            Hooks.AFTER_SWAP_FLAG |
            Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG
        );

        bytes memory constructorArgs = abi.encode(address(manager), address(policy), address(reserve), address(oracle));
        (, bytes32 salt) = HookMiner.find(address(this), flags, type(AegisHook).creationCode, constructorArgs);
        hook = new AegisHook{salt: salt}(manager, address(policy), address(reserve), address(oracle));
        reserve.setHook(address(hook));

        key = PoolKey(currency0, currency1, LPFeeLibrary.DYNAMIC_FEE_FLAG, 60, IHooks(address(hook)));
        manager.initialize(key, SQRT_PRICE_1_1);

        // Approve routers from test contract (LP)
        MockERC20(Currency.unwrap(currency0)).approve(address(modifyLiquidityRouter), type(uint256).max);
        MockERC20(Currency.unwrap(currency1)).approve(address(modifyLiquidityRouter), type(uint256).max);

        // Fund swapRouter so it can settle premiums via PoolManager
        MockERC20(Currency.unwrap(currency0)).mint(address(swapRouter), 1_000_000 ether);
        MockERC20(Currency.unwrap(currency1)).mint(address(swapRouter), 1_000_000 ether);

        // Fund and approve user
        MockERC20(Currency.unwrap(currency0)).mint(user, 1_000_000 ether);
        MockERC20(Currency.unwrap(currency1)).mint(user, 1_000_000 ether);
        vm.startPrank(user);
        MockERC20(Currency.unwrap(currency0)).approve(address(swapRouter), type(uint256).max);
        MockERC20(Currency.unwrap(currency1)).approve(address(swapRouter), type(uint256).max);
        vm.stopPrank();
    }

    // =========================================================================
    // Helpers
    // =========================================================================

    function _addLiquidity(int128 liquidity) internal {
        modifyLiquidityRouter.modifyLiquidity(
            key,
            ModifyLiquidityParams({tickLower: -887220, tickUpper: 887220, liquidityDelta: liquidity, salt: 0}),
            ""
        );
    }

    function _seedReserve(uint256 amount) internal {
        MockERC20(Currency.unwrap(currency0)).mint(address(this), amount);
        MockERC20(Currency.unwrap(currency0)).approve(address(reserve), amount);
        reserve.seedReserve(Currency.unwrap(currency0), amount);

        MockERC20(Currency.unwrap(currency1)).mint(address(this), amount);
        MockERC20(Currency.unwrap(currency1)).approve(address(reserve), amount);
        reserve.seedReserve(Currency.unwrap(currency1), amount);
    }

    /// @dev Swap as `user`, passing their address in hookData so the hook records them.
    function _userSwap(int256 amountSpecified, IAegisPolicy.CoverageTier tier)
        internal
        returns (uint256 claimsBefore, uint256 actualOut, uint256 balanceBefore)
    {
        claimsBefore = reserve.nextClaimId();
        balanceBefore = MockERC20(Currency.unwrap(currency1)).balanceOf(user);

        vm.prank(user);
        swapRouter.swap(
            key,
            SwapParams({
                zeroForOne: true,
                amountSpecified: amountSpecified,
                sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1
            }),
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
            abi.encode(uint8(tier), user)
        );

        uint256 balanceAfter = MockERC20(Currency.unwrap(currency1)).balanceOf(user);
        actualOut = balanceAfter - balanceBefore;
    }

    // =========================================================================
    // Journey 1: Deep pool - no slippage, no claim
    // =========================================================================

    /**
     * User swaps on a deep pool with Premium protection.
     * Price impact is negligible → no claim recorded.
     * Assert: actualOut >= expectedOut (user got at least what was quoted).
     */
    function test_Journey_DeepPool_NoSlippage_NoClaimNeeded() public {
        _addLiquidity(10_000 ether);
        _seedReserve(10_000 ether);

        uint256 swapAmount = 0.001 ether;

        // Capture expected output from oracle price before swap (1:1 pool, so expectedOut ≈ swapAmount)
        // We use a simple lower bound: user should receive at least 99.5% of input (< 0.5% slippage)
        uint256 expectedOutMin = (swapAmount * 995) / 1000;

        (uint256 claimsBefore, uint256 actualOut,) = _userSwap(-int256(swapAmount), IAegisPolicy.CoverageTier.Premium);

        // No claim should be recorded
        assertEq(reserve.nextClaimId(), claimsBefore, "No claim should be recorded on deep pool");

        // User received at least the expected minimum
        assertGe(actualOut, expectedOutMin, "actualOut should be >= expectedOut on deep pool");

        console.log("Deep pool swap - no slippage detected");
        console.log("  swapAmount :", swapAmount);
        console.log("  actualOut  :", actualOut);
        console.log("  expectedMin:", expectedOutMin);
    }

    // =========================================================================
    // Journey 2: Thin pool - slippage triggers claim, user settles and is made whole
    // =========================================================================

    /**
     * User swaps on a thin pool with Premium protection.
     * Large price impact → claim recorded for `user` (not router).
     * User calls settleClaim → receives compensation → net balance restored.
     */
    function test_Journey_ThinPool_Slippage_UserSettlesAndIsCompensated() public {
        _addLiquidity(1 ether); // thin pool
        _seedReserve(10_000 ether);

        uint256 swapAmount = 0.5 ether;

        (uint256 claimsBefore, uint256 actualOut,) =
            _userSwap(-int256(swapAmount), IAegisPolicy.CoverageTier.Premium);

        // Claim must have been recorded
        assertEq(reserve.nextClaimId(), claimsBefore + 1, "Claim should be recorded on thin pool");

        uint256 claimId = claimsBefore;
        (address claimSwapper, address token, uint256 compensation, bool settled,) = reserve.claims(claimId);

        // Claim is attributed to the real user, not the router
        assertEq(claimSwapper, user, "Claim must be attributed to user, not swapRouter");
        assertFalse(settled, "Claim should not be settled yet");
        assertGt(compensation, 0, "Compensation must be > 0");

        console.log("Thin pool swap - slippage detected");
        console.log("  swapAmount  :", swapAmount);
        console.log("  actualOut   :", actualOut);
        console.log("  compensation:", compensation);

        // User settles the claim
        uint256 userBalanceBefore = MockERC20(token).balanceOf(user);
        reserve.settleClaim(claimId);
        uint256 userBalanceAfter = MockERC20(token).balanceOf(user);

        assertEq(userBalanceAfter - userBalanceBefore, compensation, "User should receive full compensation");

        (, , , settled,) = reserve.claims(claimId);
        assertTrue(settled, "Claim should be marked settled");

        uint256 netOut = actualOut + compensation;
        console.log("  netOut (actualOut + compensation):", netOut);
        console.log("  User is made whole after settlement");
    }
}
