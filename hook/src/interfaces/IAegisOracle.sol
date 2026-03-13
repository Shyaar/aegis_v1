// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {PoolId} from "@uniswap/v4-core/src/types/PoolId.sol";

/**
 * @title IAegisOracle
 * @notice Provides volatility signaling for the Aegis Protocol.
 */
interface IAegisOracle {
    /**
     * @notice Retrieves the volatility signal for a given pool.
     * @dev The signal represents the tick deviation over the oracle's observation window.
     * @param id The PoolId to query.
     * @return volatilityBps The observed volatility expressed in basis points.
     */
    function getVolatilitySignal(PoolId id) external view returns (uint256 volatilityBps);
    
    /**
     * @notice Updates the oracle's latest observation with the current pool tick.
     * @param id The PoolId being updated.
     * @param tick The current pool tick.
     */
    function updateObservation(PoolId id, int24 tick) external;
}
