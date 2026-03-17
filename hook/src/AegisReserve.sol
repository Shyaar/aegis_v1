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
    mapping(address => uint256) public totalReserve;
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
        if (msg.sender != hook) revert NotHook();
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
        if (swapper == address(0)) revert InvalidSwapper();
        if (amount == 0) revert ZeroAmount();
        if (totalReserve[token] < amount) revert InsufficientReserve();
        totalReserve[token] -= amount;

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
     * @param token The address of the token being seeded.
     * @param amount The amount of capital to record in the reserve.
     */
    function seedReserve(
        address token,
        uint256 amount
    ) external payable onlyOwner {
        if (token != address(0)) {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        }
        totalReserve[token] += amount;
    }

    /**
     * @inheritdoc IAegisReserve
     */
    function depositPremium(address token, uint256 amount) external onlyHook {
        totalReserve[token] += amount;
        emit PremiumDeposited(amount);
    }

    /**
     * @inheritdoc IAegisReserve
     */
    function settleClaim(uint256 claimId) external {
        Claim storage claim = claims[claimId];
        if (claim.settled) revert AlreadySettled();

        claim.settled = true;

        if (claim.token == address(0)) {
            (bool success, ) = claim.swapper.call{value: claim.amount}("");
            require(success, "ETH transfer failed");
        } else {
            IERC20(claim.token).safeTransfer(claim.swapper, claim.amount);
        }

        emit ClaimSettled(claimId, claim.swapper, claim.amount);
    }

    /**
     * @inheritdoc IAegisReserve
     */
    function getReserveBalance(address token) external view returns (uint256) {
        return totalReserve[token];
    }

    // Required to receive ETH from PoolManager.take()
    receive() external payable {}
}
