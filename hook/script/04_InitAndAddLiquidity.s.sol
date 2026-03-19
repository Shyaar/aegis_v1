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
import {AegisReserve} from "../src/AegisReserve.sol";

contract InitAndAddLiquidity is Script {
    address constant POOL_MANAGER    = 0x00B036B58a818B1BC34d502D3fE730Db729e62AC;
    address constant POSITION_MANAGER = 0xf969Aee60879C54bAAed9F3eD26147Db216Fd664;
    address constant PERMIT2         = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    // currency0=mWETH (lower address), currency1=mUSDC
    address constant mWETH  = 0xcf841F89753158557091E0C28781f09E27Aa3B55;
    address constant mUSDC  = 0xEc8856122E88C4E10b2Ba448e63933D5A41028CC;
    address constant HOOK    = 0xbBA8aC1dEcC79495bfb10Cb0368A82Ca185f20C8;
    address constant RESERVE = 0x6662DA476699739d3dd9e2B3D11B82017A013A02;

    // 1 mWETH = 2000 mUSDC
    // price = mWETH_raw / mUSDC_raw = 1e18 / 2000e6 = 500_000_000
    // sqrtPriceX96 = sqrt(500_000_000) * 2^96
    uint160 constant SQRT_PRICE_X96 = 1771595571142957166518320255467520;

    // tick ~200311, ±6000 ticks aligned to tickSpacing=60
    int24 constant TICK_LOWER = 194340;
    int24 constant TICK_UPPER = 206340;

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

        vm.startBroadcast(pk);

        // Mint tokens — need large mUSDC amount due to pool price ratio
        MockERC20(mWETH).mint(deployer, 50e18);
        MockERC20(mUSDC).mint(deployer, 1_000_000_000e6); // 1 billion mUSDC

        // Seed reserve
        MockERC20(mWETH).approve(RESERVE, 5e18);
        MockERC20(mUSDC).approve(RESERVE, 1_000_000e6);
        AegisReserve(payable(RESERVE)).seedReserve(mWETH, 5e18);
        AegisReserve(payable(RESERVE)).seedReserve(mUSDC, 1_000_000e6);
        console.log("Reserve seeded");

        // Pool already initialized — skip initialize call

        // Permit2 approvals
        IERC20(mWETH).approve(PERMIT2, type(uint256).max);
        IERC20(mUSDC).approve(PERMIT2, type(uint256).max);
        IAllowanceTransfer(PERMIT2).approve(mWETH, POSITION_MANAGER, type(uint160).max, type(uint48).max);
        IAllowanceTransfer(PERMIT2).approve(mUSDC, POSITION_MANAGER, type(uint160).max, type(uint48).max);

        // Add liquidity: tickLower/tickUpper around current tick ~200311
        bytes memory actions = abi.encodePacked(uint8(Actions.MINT_POSITION), uint8(Actions.SETTLE_PAIR));
        bytes[] memory params = new bytes[](2);
        params[0] = abi.encode(
            key,
            TICK_LOWER,
            TICK_UPPER,
            uint256(44721359549996),
            uint128(6000000000),              // amount0Max mWETH raw
            uint128(type(uint128).max / 2),   // amount1Max mUSDC raw (very generous)
            deployer,
            bytes("")
        );
        params[1] = abi.encode(Currency.wrap(mWETH), Currency.wrap(mUSDC));

        IPositionManager(POSITION_MANAGER).modifyLiquidities(
            abi.encode(actions, params),
            block.timestamp + 60
        );
        console.log("Liquidity added");

        vm.stopBroadcast();
    }
}
