// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title LogRecord
 * @notice Structure representing an event log captured by the Reactive Network.
 */
struct LogRecord {
    uint256 chain_id;
    address _contract;
    uint256 topic_0;
    uint256 topic_1;
    uint256 topic_2;
    uint256 topic_3;
    bytes data;
    uint256 block_number;
    uint256 block_hash;
    uint256 tx_hash;
    uint256 log_index;
}

/**
 * @title IReactive
 * @notice Interface for Reactive Contracts to handle events and trigger callbacks.
 */
interface IReactive {
    /**
     * @notice Emitted when the Reactive Contract triggers a callback transaction on a destination chain.
     */
    event Callback(
        uint256 chain_id,
        address _contract,
        uint64 gas_limit,
        bytes payload
    );

    /**
     * @notice Entry point for the Reactive Network to pass captured event logs.
     * @dev The demo contracts use `react` but the older standard used `onEvent`.
     */
    function react(LogRecord calldata record) external;
}

/**
 * @title ISystemContract
 * @notice Interface for the Reactive Network system contract to manage subscriptions.
 */
interface ISystemContract {
    function subscribe(
        uint256 chain_id,
        address _contract,
        uint256 topic_0,
        uint256 topic_1,
        uint256 topic_2,
        uint256 topic_3
    ) external;

    function unsubscribe(
        uint256 chain_id,
        address _contract,
        uint256 topic_0,
        uint256 topic_1,
        uint256 topic_2,
        uint256 topic_3
    ) external;
}
