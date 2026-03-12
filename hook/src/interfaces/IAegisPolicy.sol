// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title IAegisPolicy
 * @notice Pure stateless logic for Aegis Protocol pricing and risk evaluation.
 */
interface IAegisPolicy {
    enum CoverageTier { None, Basic, Standard, Full }

    struct PolicyParams {
        uint256 swapSize;
        uint128 poolLiquidity;
        uint24 baseFee;
        uint256 volatilitySignal; // e.g., tick movement over last N blocks
        CoverageTier tier;
    }

    /**
     * @notice Calculates the premium a swapper must pay for insurance.
     */
    function calculatePremium(PolicyParams calldata params) external pure returns (uint256);

    /**
     * @notice Suggests a dynamic swap fee based on market influx.
     * @return dynamicFee in basis points (e.g., 3000 = 0.3%)
     */
    function calculateDynamicFee(uint24 currentFee, uint256 volatilitySignal) external pure returns (uint24);

    /**
     * @notice Calculates the owed compensation if slippage is breached.
     */
    function calculateCompensation(
        uint256 expectedOut,
        uint256 actualOut,
        CoverageTier tier
    ) external pure returns (uint256);
}
