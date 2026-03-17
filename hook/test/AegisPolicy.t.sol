// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {IAegisPolicy} from "../src/interfaces/IAegisPolicy.sol";
import {AegisPolicy} from "../src/AegisPolicy.sol";

contract AegisPolicyTest is Test {
    AegisPolicy public policy;

    function setUp() public {
        policy = new AegisPolicy(address(this));
    }

    /* =========================================================================
       calculatePremium()
       ========================================================================= */

    function test_Success_calculatePremium_Basic() public view {
        IAegisPolicy.PolicyParams memory params = IAegisPolicy.PolicyParams({
            swapSize: 1000 ether,
            poolLiquidity: 1000000 ether,
            baseFee: 3000,
            volatilitySignal: 0,
            tier: IAegisPolicy.CoverageTier.Basic
        });

        uint256 premium = policy.calculatePremium(params);
        // Basic = 5 bps of swapSize = (1000 * 5) / 10000 = 0.5 ether
        assertEq(premium, 0.5 ether);
    }

    function test_Success_calculatePremium_PremiumTierWithVolatility() public view {
        IAegisPolicy.PolicyParams memory params = IAegisPolicy.PolicyParams({
            swapSize: 1000 ether,
            poolLiquidity: 1000000 ether,
            baseFee: 3000,
            volatilitySignal: 2000, // 20% volatility > 1000 bps threshold
            tier: IAegisPolicy.CoverageTier.Premium
        });

        // Premium tier = 20 bps base
        // Volatility > 1000 bps surcharge = +50% of base = 20 + 10 = 30 bps
        // premium = (1000 * 30) / 10000 = 3 ether
        uint256 premium = policy.calculatePremium(params);
        assertEq(premium, 3 ether);
    }

    function testFuzz_calculatePremium(uint8 tierIdx, uint256 swapSize, uint256 volatility) public view {
        vm.assume(tierIdx > 0 && tierIdx <= 3); // Basic, Standard, Premium
        vm.assume(swapSize < 1e30); // Prevent overflow
        
        IAegisPolicy.CoverageTier tier = IAegisPolicy.CoverageTier(tierIdx);
        
        IAegisPolicy.PolicyParams memory params = IAegisPolicy.PolicyParams({
            swapSize: swapSize,
            poolLiquidity: 1e30,
            baseFee: 3000,
            volatilitySignal: volatility,
            tier: tier
        });

        uint256 premium = policy.calculatePremium(params);
        
        uint256 expectedBps;
        if (tier == IAegisPolicy.CoverageTier.Basic) expectedBps = 5;
        else if (tier == IAegisPolicy.CoverageTier.Standard) expectedBps = 10;
        else if (tier == IAegisPolicy.CoverageTier.Premium) expectedBps = 20;

        if (volatility > 1000) {
            expectedBps += expectedBps / 2;
        }

        uint256 expectedPremium = (swapSize * expectedBps) / 10000;
        assertEq(premium, expectedPremium);
    }

    /* =========================================================================
       calculateCompensation() - Exact Input
       ========================================================================= */

    function test_Success_calculateCompensation_Breach() public view {
        // Standard tier = 0.5% threshold
        uint256 expectedOut = 1000 ether;
        uint256 actualOut = 994 ether; // 0.6% slippage ( > 0.5% threshold)

        uint256 comp = policy.calculateCompensation(expectedOut, actualOut, IAegisPolicy.CoverageTier.Standard);
        assertEq(comp, 6 ether, "Compensation should be full deviation");
    }

    function test_Success_calculateCompensation_NoBreach() public view {
        // Standard tier = 0.5% threshold = 5 ether
        uint256 expectedOut = 1000 ether;
        uint256 actualOut = 996 ether; // 0.4% slippage ( < 0.5% threshold)

        uint256 comp = policy.calculateCompensation(expectedOut, actualOut, IAegisPolicy.CoverageTier.Standard);
        assertEq(comp, 0, "Compensation should be 0");
    }

    /* =========================================================================
       calculateExactOutputCompensation()
       ========================================================================= */

    function test_Success_calculateExactOutputCompensation_Breach() public view {
        // Premium tier = 0.2% threshold
        uint256 expectedIn = 1000 ether;
        uint256 actualIn = 1003 ether; // 0.3% slippage ( > 0.2% threshold)

        uint256 comp = policy.calculateExactOutputCompensation(expectedIn, actualIn, IAegisPolicy.CoverageTier.Premium);
        assertEq(comp, 3 ether, "Compensation should be full deviation");
    }

    function testFuzz_Compensation(uint8 tierIdx, uint256 expected, uint256 actual, bool isExactInput) public view {
        vm.assume(tierIdx > 0 && tierIdx <= 3);
        IAegisPolicy.CoverageTier tier = IAegisPolicy.CoverageTier(tierIdx);
        vm.assume(expected > 0 && expected < 1e30);
        vm.assume(actual > 0 && actual < 1e30);

        uint256 thresholdBps;
        if (tier == IAegisPolicy.CoverageTier.Basic) thresholdBps = 100;
        else if (tier == IAegisPolicy.CoverageTier.Standard) thresholdBps = 50;
        else thresholdBps = 20;

        uint256 thresholdAmt = (expected * thresholdBps) / 10000;

        if (isExactInput) {
            uint256 comp = policy.calculateCompensation(expected, actual, tier);
            if (actual < expected && (expected - actual) > thresholdAmt) {
                assertEq(comp, expected - actual);
            } else {
                assertEq(comp, 0);
            }
        } else {
            uint256 comp = policy.calculateExactOutputCompensation(expected, actual, tier);
            if (actual > expected && (actual - expected) > thresholdAmt) {
                assertEq(comp, actual - expected);
            } else {
                assertEq(comp, 0);
            }
        }
    }
}
