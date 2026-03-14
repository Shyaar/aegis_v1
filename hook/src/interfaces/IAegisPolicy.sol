// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title IAegisPolicy
 * @notice Pure stateless logic for Aegis Protocol pricing and risk evaluation.
 */
interface IAegisPolicy {

    error InvalidTier();
    
    enum CoverageTier { None, Basic, Standard, Premium }

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
     * @notice Calculates the owed compensation if slippage is breached on an exact input swap.
     */
    function calculateCompensation(
        uint256 expectedOut,
        uint256 actualOut,
        CoverageTier tier
    ) external pure returns (uint256);

    /**
     * @notice Calculates the owed compensation if slippage is breached on an exact output swap.
     */
    function calculateExactOutputCompensation(
        uint256 expectedIn,
        uint256 actualIn,
        CoverageTier tier
    ) external pure returns (uint256);
}
