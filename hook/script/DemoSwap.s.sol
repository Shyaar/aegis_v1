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
    address constant mUSDC = 0xF39d83F111544beCba071814ba3Bb87CE1F24491;
    address constant mWETH = 0x330FAc6bd4e4c2279CdBe29E9642d0CA53342f86;
    address constant HOOK  = 0x9aADcd5a16093e382bE24634F34df64c721C60c8;

    function run() external {
        uint256 swapAmount = vm.envUint("SWAP_AMOUNT");
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address trader = vm.addr(pk);

        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(mWETH),  // mWETH < mUSDC by address
            currency1: Currency.wrap(mUSDC),
            fee: LPFeeLibrary.DYNAMIC_FEE_FLAG,
            tickSpacing: 60,
            hooks: IHooks(HOOK)
        });

        vm.startBroadcast(pk);

        // Mint mWETH to trader, approve router only (hook uses poolManager.take())
        MockERC20(mWETH).mint(trader, swapAmount * 2);
        IERC20(mWETH).approve(SWAP_ROUTER, type(uint256).max);

        // Swap mWETH -> mUSDC (currency0 -> currency1, zeroForOne=true)
        PoolSwapTest(SWAP_ROUTER).swap(
            key,
            SwapParams({
                zeroForOne: true,
                amountSpecified: -int256(swapAmount),
                sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1
            }),
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
            abi.encode(uint8(IAegisPolicy.CoverageTier.Premium), trader)
        );

        vm.stopBroadcast();
    }
}
