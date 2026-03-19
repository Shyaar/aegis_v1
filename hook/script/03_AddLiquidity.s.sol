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

contract AddLiquidity is Script {
    // Deployed addresses
    address constant POSITION_MANAGER = 0xf969Aee60879C54bAAed9F3eD26147Db216Fd664;
    address constant PERMIT2          = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    address constant mUSDC = 0x665D2ce2a1c0De6D1a633f7E64C2383CB624662A;
    address constant mWETH = 0xad86B4C5048Fdc15550543C45cdD70f70D0A63EF;
    address constant HOOK   = 0x2042d29d9FC03a225c6a1d56b5a138C9e61960C8;

    // mUSDC < mWETH (sorted), so currency0 = mUSDC, currency1 = mWETH
    // tick range around current price (tick ~-200311), ±6000 ticks
    int24 constant TICK_LOWER = -206340;
    int24 constant TICK_UPPER = -194340;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);

        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(mWETH),
            currency1: Currency.wrap(mUSDC),
            fee: LPFeeLibrary.DYNAMIC_FEE_FLAG,
            tickSpacing: 60,
            hooks: IHooks(HOOK)
        });

        // ~1 mWETH + ~2034 mUSDC (with buffer)
        uint256 wethAmount = 1.1e18;
        uint256 usdcAmount = 2_100e6;

        vm.startBroadcast(pk);

        // Permit2 flow: approve Permit2 on the ERC20, then approve PositionManager via Permit2
        IERC20(mWETH).approve(PERMIT2, type(uint256).max);
        IERC20(mUSDC).approve(PERMIT2, type(uint256).max);

        // approve PositionManager on Permit2 (type(uint160).max amount, far-future expiry)
        IAllowanceTransfer(PERMIT2).approve(mWETH, POSITION_MANAGER, type(uint160).max, type(uint48).max);
        IAllowanceTransfer(PERMIT2).approve(mUSDC, POSITION_MANAGER, type(uint160).max, type(uint48).max);

        bytes memory actions = abi.encodePacked(uint8(Actions.MINT_POSITION), uint8(Actions.SETTLE_PAIR));

        bytes[] memory params = new bytes[](2);
        params[0] = abi.encode(
            key,
            TICK_LOWER,
            TICK_UPPER,
            uint256(173269286841088),  // liquidity for ~1 mWETH + ~4712 mUSDC
            uint128(1.1e18),           // amount0Max (mWETH, 10% buffer)
            uint128(5200e6),           // amount1Max (mUSDC, generous buffer)
            deployer,
            bytes("")
        );
        params[1] = abi.encode(Currency.wrap(mWETH), Currency.wrap(mUSDC));

        IPositionManager(POSITION_MANAGER).modifyLiquidities(
            abi.encode(actions, params),
            block.timestamp + 60
        );

        console.log("Liquidity added successfully");
        vm.stopBroadcast();
    }
}
