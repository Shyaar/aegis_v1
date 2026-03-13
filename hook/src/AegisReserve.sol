// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IAegisReserve} from "./interfaces/IAegisReserve.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title AegisReserve
 * @notice Treasury for premiums and settlement for Aegis Protocol.
 */
contract AegisReserve is IAegisReserve, Ownable {
    using SafeERC20 for IERC20;

    mapping(uint256 => Claim) public claims;
    uint256 public nextClaimId;
    uint256 public totalReserve;
    address public hook;

    event PremiumDeposited(uint256 amount);
    event ClaimRecorded(
        uint256 indexed claimId,
        address swapper,
        uint256 amount
    );
    event ClaimSettled(
        uint256 indexed claimId,
        address swapper,
        uint256 amount
    );

    modifier onlyHook() {
        require(msg.sender == hook, "Only hook can call");
        _;
    }

    constructor(address _initialOwner) Ownable(_initialOwner) {}

    function setHook(address _hook) external onlyOwner {
        hook = _hook;
    }

    /**
     * @inheritdoc IAegisReserve
     */
    function recordClaim(
        address swapper,
        address token,
        uint256 amount
    ) external onlyHook {
        uint256 claimId = nextClaimId++;
        claims[claimId] = Claim({
            swapper: swapper,
            token: token,
            amount: amount,
            settled: false,
            timestamp: block.timestamp
        });

        emit ClaimRecorded(claimId, swapper, amount);
    }

    /**
     * @notice Seeds the reserve with initial capital (owner only).
     * @param amount The amount of capital to record in the reserve.
     */
    function seedReserve(uint256 amount) external onlyOwner {
        totalReserve += amount;
    }

    /**
     * @inheritdoc IAegisReserve
     */
    function depositPremium(uint256 amount) external onlyHook {
        totalReserve += amount;
        emit PremiumDeposited(amount);
    }

    /**
     * @inheritdoc IAegisReserve
     */
    function settleClaim(uint256 claimId) external {
        Claim storage claim = claims[claimId];
        require(!claim.settled, "Already settled");
        // For POC: In production, totalReserve would be per-token.
        require(totalReserve >= claim.amount, "Insufficient reserve");

        claim.settled = true;
        totalReserve -= claim.amount;

        IERC20(claim.token).safeTransfer(claim.swapper, claim.amount);

        emit ClaimSettled(claimId, claim.swapper, claim.amount);
    }

    /**
     * @inheritdoc IAegisReserve
     */
    function getReserveBalance() external view returns (uint256) {
        return totalReserve;
    }
}
