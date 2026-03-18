// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IReactive, LogRecord} from "./interfaces/IReactive.sol";
import {AbstractReactive} from "./reactive/AbstractReactive.sol";

/**
 * @title AegisReactive
 * @notice Reactive Contract that monitors claim activity and adjusts AegisPolicy premiums.
 * @dev Runs on the Reactive Network (RNK). Extends AbstractReactive for proper vm detection,
 *      vmOnly/rnOnly modifiers, and system contract integration.
 *
 *      Deployment flow:
 *        1. Deploy with ETH value (e.g. 0.01 ether)
 *        2. Call coverDebt() to pay subscription debt to system contract
 *        3. Call subscribe() to register the event subscription
 */
contract AegisReactive is AbstractReactive {
    uint64 private constant CALLBACK_GAS_LIMIT = 1000000;

    // keccak256("ClaimPaid(address,uint256)")
    uint256 public constant CLAIM_PAID_TOPIC_0 = 0xf42cf8c29487b42c009006cba2a2a0ca0388229f3183e6e957e0a0b163585cb4;

    uint256 public constant RESET_WINDOW = 50;
    uint256 public constant CLAIM_THRESHOLD = 5 ether;

    address public immutable policyAddress;
    uint256 public immutable destinationChainId;
    address public immutable hookAddress;

    uint256 public totalClaimsInWindow;
    uint256 public lastClaimBlock;
    bool public isPremiumRaised;

    constructor(
        address _policy,
        uint256 _chainId,
        address _hook
    ) payable AbstractReactive() {
        policyAddress = _policy;
        destinationChainId = _chainId;
        hookAddress = _hook;
    }

    /// @notice Step 2: pay subscription debt, then step 3: register subscription.
    function subscribe() external rnOnly {
        uint256 debt = vendor.debt(address(this));
        _pay(payable(address(vendor)), debt);
        service.subscribe(
            destinationChainId,
            hookAddress,
            CLAIM_PAID_TOPIC_0,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE
        );
    }

    /// @inheritdoc IReactive
    function react(LogRecord calldata record) external override vmOnly {
        if (
            record.chain_id == destinationChainId &&
            record._contract == hookAddress &&
            record.topic_0 == CLAIM_PAID_TOPIC_0
        ) {
            _handleClaimPaid(record);
        }

        if (isPremiumRaised && record.block_number > lastClaimBlock + RESET_WINDOW) {
            _resetPremium();
        }
    }

    function _handleClaimPaid(LogRecord calldata record) internal {
        uint256 compensation = abi.decode(record.data, (uint256));
        totalClaimsInWindow += compensation;
        lastClaimBlock = record.block_number;

        if (!isPremiumRaised && totalClaimsInWindow >= CLAIM_THRESHOLD) {
            _raisePremium();
        }
    }

    function _raisePremium() internal {
        isPremiumRaised = true;
        emit Callback(
            destinationChainId,
            policyAddress,
            CALLBACK_GAS_LIMIT,
            abi.encodeWithSignature("updateBasePremium(address,uint16)", address(0), uint16(50))
        );
    }

    function _resetPremium() internal {
        isPremiumRaised = false;
        totalClaimsInWindow = 0;
        emit Callback(
            destinationChainId,
            policyAddress,
            CALLBACK_GAS_LIMIT,
            abi.encodeWithSignature("clearBasePremium(address)", address(0))
        );
    }
}
