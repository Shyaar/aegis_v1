// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {PoolModifyLiquidityTest} from "@uniswap/v4-core/src/test/PoolModifyLiquidityTest.sol";
import {PoolSwapTest} from "@uniswap/v4-core/src/test/PoolSwapTest.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {IAegisPolicy} from "../src/interfaces/IAegisPolicy.sol";
import {IAegisReserve} from "../src/interfaces/IAegisReserve.sol";
import {AegisReserve} from "../src/AegisReserve.sol";
import {MockERC20} from "@uniswap/v4-periphery/lib/v4-core/lib/solmate/src/test/utils/mocks/MockERC20.sol";

import {ModifyLiquidityParams, SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";

contract VerifyAegis is Script {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    // Deployed addresses (from run-latest.json)
    address constant AEGIS_ADDR = address(uint160(0x00610178da211fef7d417bc0e6fed39f05609ad788));
    address constant USDC_ADDR = address(uint160(0x00b7f8bc63bbcad18155201308c8f3540b07f84f5e));
    address constant MANAGER_ADDR = address(uint160(0x00a51c1fc2f0d1a1b8494ed1fe312d7c3a78ed91c0));
    address constant HOOK_ADDR = address(uint160(0x00c8f0ecb7e8393af5f29bf46f1ab106ed1d2640c0));
    address constant RESERVE_ADDR = address(uint160(0x009a676e781a523b5d0c0e43731313a708cb607508));

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddr = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);

        // 0. Mint tokens to deployer
        MockERC20(AEGIS_ADDR).mint(deployerAddr, 10000 ether);
        MockERC20(USDC_ADDR).mint(deployerAddr, 10000 ether);

        // 0.5 seed reserve capital (owner is deployer)
        AegisReserve reserveInstance = AegisReserve(RESERVE_ADDR);
        console.log("Reserve Address:", RESERVE_ADDR);
        console.log("Deployer Address:", deployerAddr);
        console.log("Reserve Owner:", reserveInstance.owner());

        reserveInstance.seedReserve(100000 ether);

        // 1. Deploy Test Routers
        PoolModifyLiquidityTest lpRouter = new PoolModifyLiquidityTest(IPoolManager(MANAGER_ADDR));
        PoolSwapTest swapRouter = new PoolSwapTest(IPoolManager(MANAGER_ADDR));

        // 2. Setup Pool Key
        (Currency currency0, Currency currency1) = AEGIS_ADDR < USDC_ADDR 
            ? (Currency.wrap(AEGIS_ADDR), Currency.wrap(USDC_ADDR))
            : (Currency.wrap(USDC_ADDR), Currency.wrap(AEGIS_ADDR));

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(HOOK_ADDR)
        });

        // 3. Provide Liquidity
        MockERC20(Currency.unwrap(currency0)).approve(address(lpRouter), 1000 ether);
        MockERC20(Currency.unwrap(currency1)).approve(address(lpRouter), 1000 ether);

        lpRouter.modifyLiquidity(
            key,
            ModifyLiquidityParams({
                tickLower: -120,
                tickUpper: 120,
                liquidityDelta: 100 ether,
                salt: 0
            }),
            ""
        );
        console.log("Liquidity provided to pool");

        // 4. Perform Swap with Aegis Insurance
        // hookData = abi.encode(CoverageTier.Full) = 2
        bytes memory hookData = abi.encode(IAegisPolicy.CoverageTier.Full);
        
        MockERC20(Currency.unwrap(currency0)).approve(address(swapRouter), 10 ether);

        swapRouter.swap(
            key,
            SwapParams({
                zeroForOne: true,
                amountSpecified: -1 ether, // Exact input
                sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1
            }),
            PoolSwapTest.TestSettings({
                takeClaims: false,
                settleUsingBurn: false
            }),
            hookData
        );
        console.log("Swap with Aegis insurance completed");

        // 5. Verify Claim in Reserve
        IAegisReserve reserve = IAegisReserve(RESERVE_ADDR);
        uint256 claimId = reserve.nextClaimId() - 1;
        (address swapper, address token, uint256 amount, bool settled,) = reserve.claims(claimId);
        
        console.log("Claim Recorded:");
        console.log("- Swapper:", swapper);
        console.log("- Token:", token);
        console.log("- Amount:", amount);
        console.log("- Settled:", settled);

        // 6. Settle Claim
        reserve.settleClaim(claimId);
        (,,, settled,) = reserve.claims(claimId);
        console.log("Claim settled:", settled);

        vm.stopBroadcast();
    }
}
