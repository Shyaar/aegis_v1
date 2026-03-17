// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IReactive, ISystemContract, LogRecord} from "./interfaces/IReactive.sol";

/**
 * @title AegisReactive
 * @notice Reactive Contract that monitors claim activity and adjusts AegisPolicy premiums.
 * @dev This contract runs on the Reactive Network and triggers callbacks to the destination chain.
 * Inspired by the Reactive Network demos.
 */
contract AegisReactive is IReactive {
    uint256 public constant REACTIVE_IGNORE = 0xa65f96489a2442436f6d00000000000000000000000000000000000000000000;
    uint64 private constant CALLBACK_GAS_LIMIT = 1000000;

    // Event Topic for ClaimPaid(address,uint256)
    // keccak256("ClaimPaid(address,uint256)")
    uint256 public constant CLAIM_PAID_TOPIC_0 = 0x226d5b41cfec7a0db2f4ccda923f0125d13c8d5bf194e7d3beced0ec21bc70c9;

    // Thresholds for triggering adjustments
    uint256 public constant RESET_WINDOW = 50; // blocks
    uint256 public constant CLAIM_THRESHOLD = 5 ether; // total compensation threshold

    // Immutable configuration
    address public immutable policyAddress;
    uint256 public immutable destinationChainId;
    address public immutable hookAddress;

    // The system contract for subscriptions (standardized across RMN)
    ISystemContract public constant service = ISystemContract(0x00000000000000000000000000000000000000ff);

    // State tracked in ReactVM
    uint256 public totalClaimsInWindow;
    uint256 public lastClaimBlock;
    bool public isPremiumRaised;
    
    // Detect if we are in ReactVM
    bool public immutable vm;

    constructor(
        address _policy,
        uint256 _chainId,
        address _hook
    ) {
        policyAddress = _policy;
        destinationChainId = _chainId;
        hookAddress = _hook;

        // Check for VM by calling system contract (standard RMN pattern)
        uint256 codeSize;
        address systemAddr = address(service);
        assembly {
            codeSize := extcodesize(systemAddr)
        }
        vm = (codeSize > 0);

        if (!vm) {
            // Subscribe to ClaimPaid events on the destination chain
            service.subscribe(
                destinationChainId,
                hookAddress,
                CLAIM_PAID_TOPIC_0,
                REACTIVE_IGNORE,
                REACTIVE_IGNORE,
                REACTIVE_IGNORE
            );
        }
    }
    
    modifier vmOnly() {
        require(vm, "ReactVM only");
        _;
    }

    /**
     * @inheritdoc IReactive
     */
    function react(LogRecord calldata record) external override vmOnly {
        // Only listen to ClaimPaid events from our hook on the correct chain
        if (
            record.chain_id == destinationChainId &&
            record._contract == hookAddress &&
            record.topic_0 == CLAIM_PAID_TOPIC_0
        ) {
            _handleClaimPaid(record);
        }
        
        // Check for "quiet" period to reset premiums
        if (isPremiumRaised && record.block_number > lastClaimBlock + RESET_WINDOW) {
            _resetPremium();
        }
    }

    function _handleClaimPaid(LogRecord calldata record) internal {
        // Decode compensation amount from data
        uint256 compensation = abi.decode(record.data, (uint256));
        
        totalClaimsInWindow += compensation;
        lastClaimBlock = record.block_number;

        if (!isPremiumRaised && totalClaimsInWindow >= CLAIM_THRESHOLD) {
            _raisePremium();
        }
    }

    function _raisePremium() internal {
        isPremiumRaised = true;
        
        // Trigger callback to AegisPolicy.updateBasePremium(50)
        // 50 BPS = 0.5% extra premium
        emit Callback(
            destinationChainId,
            policyAddress,
            CALLBACK_GAS_LIMIT,
            abi.encodeWithSignature("updateBasePremium(uint16)", 50)
        );
    }

    function _resetPremium() internal {
        isPremiumRaised = false;
        totalClaimsInWindow = 0;
        
        // Trigger callback to AegisPolicy.clearBasePremium()
        emit Callback(
            destinationChainId,
            policyAddress,
            CALLBACK_GAS_LIMIT,
            abi.encodeWithSignature("clearBasePremium()")
        );
    }
}
