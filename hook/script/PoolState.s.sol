// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {LPFeeLibrary} from "@uniswap/v4-core/src/libraries/LPFeeLibrary.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";

contract PoolState is Script {
    using PoolIdLibrary for PoolKey;
    using StateLibrary for IPoolManager;

    IPoolManager constant PM = IPoolManager(0x00B036B58a818B1BC34d502D3fE730Db729e62AC);

    function run() external view {
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(0x16A1234F95E6cDeFAaE4d7ECd352AFE4B9946A35), // mUSDC (lower addr)
            currency1: Currency.wrap(0x1dE340Ae93AC4896AC5feD63b73306325395f195), // mWETH
            fee: LPFeeLibrary.DYNAMIC_FEE_FLAG,
            tickSpacing: 60,
            hooks: IHooks(0xDcdcBDe6Ec7209Ad97dB4CbE5e40C16127d820C8)
        });
        PoolId id = key.toId();
        console.log("PoolId:"); console.logBytes32(PoolId.unwrap(id));
        (uint160 sqrtPrice, int24 tick,,) = PM.getSlot0(id);
        uint128 liq = PM.getLiquidity(id);
        console.log("sqrtPriceX96:", sqrtPrice);
        console.log("tick:", tick);
        console.log("liquidity:", liq);
    }
}
