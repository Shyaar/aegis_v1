// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.21;

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {
    BalanceDelta,
    toBalanceDelta
} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {
    Currency,
    CurrencyLibrary
} from "@uniswap/v4-core/src/types/Currency.sol";
import {
    IPositionManager
} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {Actions} from "@uniswap/v4-periphery/src/libraries/Actions.sol";
import {SafeCast} from "@uniswap/v4-core/src/libraries/SafeCast.sol";
import {
    PositionInfo,
    PositionInfoLibrary
} from "@uniswap/v4-periphery/src/libraries/PositionInfoLibrary.sol";

library EasyPosm {
    using CurrencyLibrary for Currency;
    using SafeCast for uint256;
    using SafeCast for int256;
    using PositionInfoLibrary for PositionInfo;

    struct MintData {
        uint256 balance0Before;
        uint256 balance1Before;
        bytes[] params;
        bytes actions;
    }

    function getCurrencies(
        IPositionManager posm,
        uint256 tokenId
    ) internal view returns (Currency currency0, Currency currency1) {
        (PoolKey memory key, ) = posm.getPoolAndPositionInfo(tokenId);
        return (key.currency0, key.currency1);
    }
}
