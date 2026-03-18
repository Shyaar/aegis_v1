// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IAegisPolicy} from "./interfaces/IAegisPolicy.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AbstractCallback} from "./reactive/AbstractPayer.sol";

/**
 * @title AegisPolicy
 * @author Aegis Team
 * @notice Logic for insurance premiums and dynamic fee scaling.
 * @dev Extends AbstractCallback so that updateBasePremium/clearBasePremium are
 *      restricted to the Callback Proxy via authorizedSenderOnly.
 *      Pass the Reactive Network Callback Proxy address as _callbackSender on deployment.
 */
contract AegisPolicy is IAegisPolicy, Ownable, AbstractCallback {
    uint256 public constant BPS = 10000;

    uint16 public extraBps;

    constructor(address initialOwner, address _callbackSender)
        Ownable(initialOwner)
        AbstractCallback(_callbackSender)
    {}

    /**
     * @inheritdoc IAegisPolicy
     */
    function updateBasePremium(address /* rvm */, uint16 additionalBps) external authorizedSenderOnly {
        extraBps = additionalBps;
    }

    /**
     * @inheritdoc IAegisPolicy
     */
    function clearBasePremium(address /* rvm */) external authorizedSenderOnly {
        extraBps = 0;
    }

    /**
     * @inheritdoc IAegisPolicy
     */
    function calculatePremium(
        PolicyParams calldata params
    ) external view returns (uint256) {
        if (params.tier == CoverageTier.None) {
            return 0;
        }

        uint256 basePremiumBps;
        if (params.tier == CoverageTier.Basic) {
            basePremiumBps = 5;
        } else if (params.tier == CoverageTier.Standard) {
            basePremiumBps = 10;
        } else if (params.tier == CoverageTier.Premium) {
            basePremiumBps = 20;
        } else {
            revert InvalidTier();
        }

        basePremiumBps += extraBps;

        if (params.volatilitySignal > 1000) {
            basePremiumBps += basePremiumBps / 2;
        }

        return (params.swapSize * basePremiumBps) / BPS;
    }

    /**
     * @inheritdoc IAegisPolicy
     */
    function calculateCompensation(
        uint256 expectedOut,
        uint256 actualOut,
        CoverageTier tier
    ) external pure returns (uint256) {
        if (tier == CoverageTier.None || actualOut >= expectedOut) return 0;

        uint256 deviation = expectedOut - actualOut;
        uint256 thresholdBps;

        if (tier == CoverageTier.Basic) {
            thresholdBps = 100;
        } else if (tier == CoverageTier.Standard) {
            thresholdBps = 50;
        } else if (tier == CoverageTier.Premium) {
            thresholdBps = 20;
        } else {
            revert InvalidTier();
        }

        uint256 thresholdAmount = (expectedOut * thresholdBps) / BPS;
        if (deviation > thresholdAmount) {
            return deviation;
        }
        return 0;
    }

    /**
     * @inheritdoc IAegisPolicy
     */
    function calculateExactOutputCompensation(
        uint256 expectedIn,
        uint256 actualIn,
        CoverageTier tier
    ) external pure returns (uint256) {
        if (tier == CoverageTier.None || actualIn <= expectedIn) return 0;

        uint256 deviation = actualIn - expectedIn;
        uint256 thresholdBps;

        if (tier == CoverageTier.Basic) {
            thresholdBps = 100;
        } else if (tier == CoverageTier.Standard) {
            thresholdBps = 50;
        } else if (tier == CoverageTier.Premium) {
            thresholdBps = 20;
        } else {
            revert InvalidTier();
        }

        uint256 thresholdAmount = (expectedIn * thresholdBps) / BPS;
        if (deviation > thresholdAmount) {
            return deviation;
        }
        return 0;
    }
}
