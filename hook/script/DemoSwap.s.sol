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
    address constant mUSDC = 0xE55C5Ace3b0645AeAD6d685D29DFEC35245619Bc;
    address constant mWETH = 0x83190Ed6aBa775d7910EF2f5F94845Ca79ccC29E;
    address constant HOOK  = 0x1b1e38436421512DE424B666F3aaC28c8c99e0C8;

    function run() external {
        uint256 swapAmount = vm.envUint("SWAP_AMOUNT");
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address trader = vm.addr(pk);

        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(mWETH),  // mWETH < mUSDC
            currency1: Currency.wrap(mUSDC),
            fee: LPFeeLibrary.DYNAMIC_FEE_FLAG,
            tickSpacing: 60,
            hooks: IHooks(HOOK)
        });

        vm.startBroadcast(pk);

        // Mint mWETH to trader and approve router
        MockERC20(mWETH).mint(trader, swapAmount);
        IERC20(mWETH).approve(SWAP_ROUTER, swapAmount);

        // Swap mWETH -> mUSDC (currency0 -> currency1, zeroForOne=true)
        PoolSwapTest(SWAP_ROUTER).swap(
            key,
            SwapParams({
                zeroForOne: true,
                amountSpecified: -int256(swapAmount),
                sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1
            }),
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
            abi.encode(IAegisPolicy.CoverageTier.Premium)
        );

        vm.stopBroadcast();
    }
}
