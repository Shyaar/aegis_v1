// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// Vendored from https://github.com/Reactive-Network/reactive-lib

import {IReactive, LogRecord} from "../interfaces/IReactive.sol";
import {AbstractPayer, IPayable} from "./AbstractPayer.sol";

interface ISubscriptionService {
    function subscribe(uint256 chain_id, address _contract, uint256 topic_0, uint256 topic_1, uint256 topic_2, uint256 topic_3) external;
    function unsubscribe(uint256 chain_id, address _contract, uint256 topic_0, uint256 topic_1, uint256 topic_2, uint256 topic_3) external;
}

interface ISystemContract is ISubscriptionService {
    receive() external payable;
    function debt(address _contract) external view returns (uint256);
}

abstract contract AbstractReactive is IReactive, AbstractPayer {
    uint256 internal constant REACTIVE_IGNORE = 0xa65f96fc951c35ead38878e0f0b7a3c744a6f5ccc1476b313353ce31712313ad;

    ISystemContract internal constant SERVICE_ADDR = ISystemContract(payable(0x0000000000000000000000000000000000fffFfF));

    /// @notice True when running inside a ReactVM instance, false on the Reactive Network itself.
    bool internal vm;

    ISystemContract internal service;

    constructor() {
        vendor = IPayable(payable(address(SERVICE_ADDR)));
        service = SERVICE_ADDR;
        addAuthorizedSender(address(SERVICE_ADDR));
        detectVm();
    }

    modifier rnOnly() {
        require(!vm, 'Reactive Network only');
        _;
    }

    modifier vmOnly() {
        require(vm, 'VM only');
        _;
    }

    /// @notice vm = true when system contract has NO code (i.e. we are in ReactVM, not on RNK).
    function detectVm() internal {
        uint256 size;
        assembly { size := extcodesize(0x0000000000000000000000000000000000fffFfF) }
        vm = size == 0;
    }
}
