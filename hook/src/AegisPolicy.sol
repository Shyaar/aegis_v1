// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IAegisPolicy} from "./interfaces/IAegisPolicy.sol";

/**
 * @title AegisPolicy
 * @author Aegis Team
 * @notice Logic for insurance premiums and dynamic fee scaling.
 */
contract AegisPolicy is IAegisPolicy {
    // Basis Points (10000 = 100%)
    uint256 public constant BPS = 10000;

    /**
     * @inheritdoc IAegisPolicy
     */
    function calculatePremium(PolicyParams calldata params) external pure returns (uint256) {
        uint256 basePremiumBps;
        
        if (params.tier == CoverageTier.Basic) {
            basePremiumBps = 5; // 0.05%
        } else if (params.tier == CoverageTier.Standard) {
            basePremiumBps = 10; // 0.1%
        } else {
            basePremiumBps = 20; // 0.2%
        }

        // Add volatility surcharge
        // If volatility is > 1000 bps (10%), add 50% more premium
        if (params.volatilitySignal > 1000) {
            basePremiumBps += 5;
        }

        // premium = (size * bps) / 10000
        return (params.swapSize * basePremiumBps) / BPS;
    }

    /**
     * @inheritdoc IAegisPolicy
     */
    function calculateDynamicFee(uint24 currentFee, uint256 volatilitySignal) external pure returns (uint24) {
        // Simple scaling: if volatilitySignal (BPS) is high, increase fee
        // volatilitySignal is deviation in BPS over last window
        
        if (volatilitySignal > 500) { // > 5% move
            return 3000; // 0.3%
        } else if (volatilitySignal < 50) { // < 0.5% move
            return 100; // 0.01%
        }
        
        return currentFee; // stable
    }

    /**
     * @inheritdoc IAegisPolicy
     */
    function calculateCompensation(
        uint256 expectedOut,
        uint256 actualOut,
        CoverageTier tier
    ) external pure returns (uint256) {
        if (actualOut >= expectedOut) return 0;

        uint256 deviation = expectedOut - actualOut;
        uint256 thresholdBps;

        if (tier == CoverageTier.Basic) {
            thresholdBps = 100; // 1%
        } else if (tier == CoverageTier.Standard) {
            thresholdBps = 50;  // 0.5%
        } else {
            thresholdBps = 20;  // 0.2%
        }

        uint256 thresholdAmount = (expectedOut * thresholdBps) / BPS;

        if (deviation > thresholdAmount) {
            // Pay the full deviation once threshold is breached
            return deviation;
        }

        return 0;
    }
}
