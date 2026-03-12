// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title IAegisReserve
 * @notice Interface for the Aegis insurance treasury and claim settlement.
 */
interface IAegisReserve {
    struct Claim {
        address swapper;
        address token;
        uint256 amount;
        bool settled;
        uint256 timestamp;
    }

    function nextClaimId() external view returns (uint256);
    function claims(uint256 claimId) external view returns (address swapper, address token, uint256 amount, bool settled, uint256 timestamp);

    /**
     * @notice Records a claim for a swapper.
     * @param swapper The address of the insured swapper.
     * @param token The address of the token for compensation.
     * @param amount The compensation amount owed.
     */
    function recordClaim(address swapper, address token, uint256 amount) external;

    /**
     * @notice Deposits premiums into the reserve.
     * @param amount The premium amount collected.
     */
    function depositPremium(uint256 amount) external;

    /**
     * @notice Allows a swapper to claim their deferred compensation.
     * @param claimId The ID of the recorded claim.
     */
    function settleClaim(uint256 claimId) external;

    /**
     * @notice Returns the depth of the insurance reserve for a given pool.
     */
    function getReserveBalance() external view returns (uint256);
}
