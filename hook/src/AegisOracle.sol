// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IAegisOracle} from "./interfaces/IAegisOracle.sol";
import {PoolId} from "@uniswap/v4-core/src/types/PoolId.sol";

/**
 * @title AegisOracle
 * @notice A custom Uniswap v4-compatible oracle that tracks tick volatility over a rolling window.
 * @dev Storing a ring buffer of recent ticks per pool to measure the min/max deviation (volatility).
 */
contract AegisOracle is IAegisOracle {
    // Number of observations to keep in the rolling window
    uint16 public constant WINDOW_SIZE = 10;
    
    struct Observation {
        uint32 timestamp;
        int24 tick;
    }

    struct OracleState {
        uint16 index;
        uint16 count; // Up to WINDOW_SIZE
        Observation[WINDOW_SIZE] observations;
    }

    // Mapping from PoolId to its Oracle State
    mapping(PoolId => OracleState) public poolObservations;

    /**
     * @inheritdoc IAegisOracle
     */
    function updateObservation(PoolId id, int24 tick) external {
        OracleState storage state = poolObservations[id];
        
        // Basic debounce: only record one observation per block
        if (state.count > 0 && state.observations[(state.index + WINDOW_SIZE - 1) % WINDOW_SIZE].timestamp == uint32(block.timestamp)) {
            return;
        }

        // Write to ring buffer
        state.observations[state.index] = Observation({
            timestamp: uint32(block.timestamp),
            tick: tick
        });

        // Advance index
        state.index = (state.index + 1) % WINDOW_SIZE;
        if (state.count < WINDOW_SIZE) {
            state.count++;
        }
    }

    /**
     * @inheritdoc IAegisOracle
     */
    function getVolatilitySignal(PoolId id) external view returns (uint256 volatilityBps) {
        OracleState storage state = poolObservations[id];
        
        // Not enough data to determine volatility
        if (state.count < 2) return 0;
        
        int24 minTick = type(int24).max;
        int24 maxTick = type(int24).min;

        for (uint16 i = 0; i < state.count; i++) {
            int24 t = state.observations[i].tick;
            if (t < minTick) minTick = t;
            if (t > maxTick) maxTick = t;
        }

        // tick deviation (1 tick ~ 0.01% price movement in 1-BPS tick spacing)
        // volatility = maxTick - minTick difference.
        // Return difference in BPS. Eg: 100 ticks diff = ~100 BPS = 1% movement.
        uint256 tickDiff = uint256(int256(maxTick - minTick));
        
        return tickDiff;
    }
}
