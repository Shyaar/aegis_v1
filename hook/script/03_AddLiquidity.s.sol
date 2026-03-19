// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {LPFeeLibrary} from "@uniswap/v4-core/src/libraries/LPFeeLibrary.sol";
import {Actions} from "@uniswap/v4-periphery/src/libraries/Actions.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

contract AddLiquidity is Script {
    address constant POSITION_MANAGER = 0xf969Aee60879C54bAAed9F3eD26147Db216Fd664;
    address constant PERMIT2          = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);

        address mUSDC = vm.envAddress("MUSDC_ADDRESS");
        address mWETH = vm.envAddress("MWETH_ADDRESS");
        address hook  = vm.envAddress("HOOK_ADDRESS");

        // Sort tokens — v4 requires currency0 < currency1
        (address token0, address token1) = mUSDC < mWETH
            ? (mUSDC, mWETH)
            : (mWETH, mUSDC);

        // Tick range: price = 1 mWETH = 2000 mUSDC
        // If mUSDC < mWETH: currency0=mUSDC, currency1=mWETH
        //   price_raw = mWETH_units / mUSDC_units = 1e18 / 2000e6 = 500_000_000 → tick ~+200311
        // If mWETH < mUSDC: currency0=mWETH, currency1=mUSDC
        //   price_raw = mUSDC_units / mWETH_units = 2000e6 / 1e18 = 2e-12 → tick ~-200311
        int24 tickLower;
        int24 tickUpper;
        uint128 amount0Max;
        uint128 amount1Max;

        if (mUSDC < mWETH) {
            // currency0=mUSDC(6dec), currency1=mWETH(18dec), tick ~+200311
            tickLower = 194340;
            tickUpper = 206340;
            amount0Max = 5_200e6;   // mUSDC
            amount1Max = 1.1e18;    // mWETH
        } else {
            // currency0=mWETH(18dec), currency1=mUSDC(6dec), tick ~-200311
            tickLower = -206340;
            tickUpper = -194340;
            amount0Max = 1.1e18;    // mWETH
            amount1Max = 5_200e6;   // mUSDC
        }

        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: LPFeeLibrary.DYNAMIC_FEE_FLAG,
            tickSpacing: 60,
            hooks: IHooks(hook)
        });

        vm.startBroadcast(pk);

        // Mint tokens for liquidity
        MockERC20(mWETH).mint(deployer, 10e18);
        MockERC20(mUSDC).mint(deployer, 25_000e6);

        // Permit2 approvals
        IERC20(token0).approve(PERMIT2, type(uint256).max);
        IERC20(token1).approve(PERMIT2, type(uint256).max);
        IAllowanceTransfer(PERMIT2).approve(token0, POSITION_MANAGER, type(uint160).max, type(uint48).max);
        IAllowanceTransfer(PERMIT2).approve(token1, POSITION_MANAGER, type(uint160).max, type(uint48).max);

        bytes memory actions = abi.encodePacked(uint8(Actions.MINT_POSITION), uint8(Actions.SETTLE_PAIR));
        bytes[] memory params = new bytes[](2);
        params[0] = abi.encode(
            key,
            tickLower,
            tickUpper,
            uint256(173269286841088),
            amount0Max,
            amount1Max,
            deployer,
            bytes("")
        );
        params[1] = abi.encode(Currency.wrap(token0), Currency.wrap(token1));

        IPositionManager(POSITION_MANAGER).modifyLiquidities(
            abi.encode(actions, params),
            block.timestamp + 60
        );

        console.log("Liquidity added successfully");
        console.log("currency0:", token0);
        console.log("currency1:", token1);
        console.log("tickLower:", tickLower);
        console.log("tickUpper:", tickUpper);

        vm.stopBroadcast();
    }
}
