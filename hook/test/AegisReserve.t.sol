// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {Deployers} from "test/utils/Deployers.sol";
import {AegisReserve} from "../src/AegisReserve.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";

contract AegisReserveTest is Test, Deployers {
    AegisReserve public reserve;
    address public hook = address(0x123);
    address public user = address(0x456);
    MockERC20 public token;

    function setUp() public {
        reserve = new AegisReserve(address(this));
        reserve.setHook(hook);
        token = new MockERC20("Test Token", "TEST", 18);
        token.mint(address(this), 1000 ether);
        token.approve(address(reserve), type(uint256).max);
    }

    /* =========================================================================
       seedReserve()
       ========================================================================= */

    function test_Success_seedReserve_ERC20() public {
        uint256 amount = 100 ether;
        reserve.seedReserve(address(token), amount);

        assertEq(reserve.getReserveBalance(address(token)), amount);
        assertEq(token.balanceOf(address(reserve)), amount);
    }

    function test_Success_seedReserve_ETH() public {
        uint256 amount = 1 ether;
        reserve.seedReserve{value: amount}(address(0), amount);

        assertEq(reserve.getReserveBalance(address(0)), amount);
        assertEq(address(reserve).balance, amount);
    }

    function test_Revert_seedReserve_NotOwner() public {
        vm.prank(user);
        vm.expectRevert(); // Ownable: caller is not the owner
        reserve.seedReserve(address(token), 10 ether);
    }

    function testFuzz_seedReserve(uint256 amount) public {
        amount = bound(amount, 1, 1000 ether);
        token.mint(address(this), amount);
        token.approve(address(reserve), amount);

        reserve.seedReserve(address(token), amount);
        assertEq(reserve.getReserveBalance(address(token)), amount);
    }

    /* =========================================================================
       depositPremium()
       ========================================================================= */

    function test_Success_depositPremium() public {
        vm.prank(hook);
        reserve.depositPremium(address(token), 50 ether);

        assertEq(reserve.getReserveBalance(address(token)), 50 ether);
    }

    function test_Revert_depositPremium_NotHook() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("NotHook()"));
        reserve.depositPremium(address(token), 10 ether);
    }

    /* =========================================================================
       recordClaim()
       ========================================================================= */

    function test_Success_recordClaim() public {
        reserve.seedReserve(address(token), 100 ether);

        uint256 expectedId = reserve.nextClaimId();
        vm.prank(hook);
        reserve.recordClaim(user, address(token), 10 ether);

        (address recipient, address claimToken, uint256 amount, bool settled, uint256 timestamp) = reserve.claims(expectedId);
        assertEq(recipient, user);
        assertEq(amount, 10 ether);
        assertEq(claimToken, address(token));
        assertFalse(settled);
        assertEq(timestamp, block.timestamp);

        // Reserve should be deducted locally
        assertEq(reserve.getReserveBalance(address(token)), 90 ether);
    }

    function test_Revert_recordClaim_InsufficientReserve() public {
        reserve.seedReserve(address(token), 5 ether);
        
        vm.prank(hook);
        vm.expectRevert(abi.encodeWithSignature("InsufficientReserve()"));
        reserve.recordClaim(user, address(token), 10 ether);
    }

    /* =========================================================================
       settleClaim()
       ========================================================================= */

    function test_Success_settleClaim_ERC20() public {
        reserve.seedReserve(address(token), 100 ether);
        
        uint256 id = reserve.nextClaimId();
        vm.prank(hook);
        reserve.recordClaim(user, address(token), 10 ether);

        reserve.settleClaim(id);

        (, , , bool settled, ) = reserve.claims(id);
        assertTrue(settled);
        assertEq(token.balanceOf(user), 10 ether);
    }

    function test_Success_settleClaim_ETH() public {
        reserve.seedReserve{value: 10 ether}(address(0), 10 ether);
        
        uint256 id = reserve.nextClaimId();
        vm.prank(hook);
        reserve.recordClaim(user, address(0), 1 ether);

        uint256 initialBalance = user.balance;
        reserve.settleClaim(id);

        assertEq(user.balance, initialBalance + 1 ether);
    }

    function test_Revert_settleClaim_AlreadySettled() public {
        reserve.seedReserve(address(token), 100 ether);
        uint256 id = reserve.nextClaimId();
        vm.prank(hook);
        reserve.recordClaim(user, address(token), 10 ether);

        reserve.settleClaim(id);
        
        vm.expectRevert(abi.encodeWithSignature("AlreadySettled()"));
        reserve.settleClaim(id);
    }
}
