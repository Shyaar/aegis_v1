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

    // mUSDC < mWETH by address, so currency0=mUSDC, currency1=mWETH
    address constant mUSDC  = 0x665D2ce2a1c0De6D1a633f7E64C2383CB624662A;
    address constant mWETH  = 0xad86B4C5048Fdc15550543C45cdD70f70D0A63EF;
    address constant HOOK    = 0x2042d29d9FC03a225c6a1d56b5a138C9e61960C8;
    address constant RESERVE = 0x404362df39d9352D439eAA00cFaD2074498883d0;

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
            currency0: Currency.wrap(mUSDC),
            currency1: Currency.wrap(mWETH),
            fee: LPFeeLibrary.DYNAMIC_FEE_FLAG,
            tickSpacing: 60,
            hooks: IHooks(HOOK)
        });

        vm.startBroadcast(pk);

        // Mint tokens
        MockERC20(mWETH).mint(deployer, 50e18);
        MockERC20(mUSDC).mint(deployer, 100_000e6);

        // Seed reserve
        MockERC20(mUSDC).approve(RESERVE, 10_000e6);
        MockERC20(mWETH).approve(RESERVE, 5e18);
        AegisReserve(payable(RESERVE)).seedReserve(mUSDC, 10_000e6);
        AegisReserve(payable(RESERVE)).seedReserve(mWETH, 5e18);
        console.log("Reserve seeded");

        // Initialize pool (triggers beforeInitialize on hook)
        IPoolManager(POOL_MANAGER).initialize(key, SQRT_PRICE_X96);
        console.log("Pool initialized");

        // Permit2 approvals
        IERC20(mUSDC).approve(PERMIT2, type(uint256).max);
        IERC20(mWETH).approve(PERMIT2, type(uint256).max);
        IAllowanceTransfer(PERMIT2).approve(mUSDC, POSITION_MANAGER, type(uint160).max, type(uint48).max);
        IAllowanceTransfer(PERMIT2).approve(mWETH, POSITION_MANAGER, type(uint160).max, type(uint48).max);

        // Add liquidity
        bytes memory actions = abi.encodePacked(uint8(Actions.MINT_POSITION), uint8(Actions.SETTLE_PAIR));
        bytes[] memory params = new bytes[](2);
        params[0] = abi.encode(
            key,
            TICK_LOWER,
            TICK_UPPER,
            uint256(173269286841088),
            uint128(5200e6),   // amount0Max mUSDC
            uint128(1.1e18),   // amount1Max mWETH
            deployer,
            bytes("")
        );
        params[1] = abi.encode(Currency.wrap(mUSDC), Currency.wrap(mWETH));

        IPositionManager(POSITION_MANAGER).modifyLiquidities(
            abi.encode(actions, params),
            block.timestamp + 60
        );
        console.log("Liquidity added");

        vm.stopBroadcast();
    }
}
