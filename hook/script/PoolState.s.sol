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
            currency0: Currency.wrap(0x330FAc6bd4e4c2279CdBe29E9642d0CA53342f86), // mWETH (lower addr)
            currency1: Currency.wrap(0xF39d83F111544beCba071814ba3Bb87CE1F24491), // mUSDC
            fee: LPFeeLibrary.DYNAMIC_FEE_FLAG,
            tickSpacing: 60,
            hooks: IHooks(0x9aADcd5a16093e382bE24634F34df64c721C60c8)
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
