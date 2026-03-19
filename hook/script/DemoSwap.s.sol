// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {LPFeeLibrary} from "@uniswap/v4-core/src/libraries/LPFeeLibrary.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {PoolSwapTest} from "@uniswap/v4-core/src/test/PoolSwapTest.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IAegisPolicy} from "../src/interfaces/IAegisPolicy.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

contract DemoSwap is Script {
    address constant SWAP_ROUTER = 0x9140a78c1A137c7fF1c151EC8231272aF78a99A4;
    address constant mUSDC = 0x16A1234F95E6cDeFAaE4d7ECd352AFE4B9946A35;
    address constant mWETH = 0x1dE340Ae93AC4896AC5feD63b73306325395f195;
    address constant HOOK  = 0xDcdcBDe6Ec7209Ad97dB4CbE5e40C16127d820C8;

    function run() external {
        uint256 swapAmount = vm.envUint("SWAP_AMOUNT");
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address trader = vm.addr(pk);

        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(mUSDC),  // mUSDC < mWETH by address
            currency1: Currency.wrap(mWETH),
            fee: LPFeeLibrary.DYNAMIC_FEE_FLAG,
            tickSpacing: 60,
            hooks: IHooks(HOOK)
        });

        vm.startBroadcast(pk);

        // Mint mWETH to trader, approve router and hook for premium
        MockERC20(mWETH).mint(trader, swapAmount * 2);
        IERC20(mWETH).approve(SWAP_ROUTER, type(uint256).max);
        IERC20(mWETH).approve(HOOK, type(uint256).max);

        // Swap mWETH -> mUSDC (currency1 -> currency0, zeroForOne=false)
        PoolSwapTest(SWAP_ROUTER).swap(
            key,
            SwapParams({
                zeroForOne: false,
                amountSpecified: -int256(swapAmount),
                sqrtPriceLimitX96: TickMath.MAX_SQRT_PRICE - 1
            }),
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
            abi.encode(IAegisPolicy.CoverageTier.Premium)
        );

        vm.stopBroadcast();
    }
}
