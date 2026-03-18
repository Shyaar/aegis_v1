// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {AegisPolicy} from "../src/AegisPolicy.sol";
import {AegisReactive} from "../src/AegisReactive.sol";
import {IAegisPolicy} from "../src/interfaces/IAegisPolicy.sol";
import {IReactive, LogRecord} from "../src/interfaces/IReactive.sol";

contract MockSystemContract {
    function subscribe(uint256, address, uint256, uint256, uint256, uint256) external {}
    function unsubscribe(uint256, address, uint256, uint256, uint256, uint256) external {}
}

contract ReactiveFlowTest is Test {
    AegisPolicy public policy;
    AegisReactive public reactive;
    MockSystemContract public mockSystem;

    address public owner = address(0x1);
    address public hook = address(0x3);
    uint256 public chainId = 1;
    address public constant SYSTEM_CONTRACT_ADDR = 0x00000000000000000000000000000000000000ff;

    event Callback(
        uint256 chain_id,
        address _contract,
        uint64 gas_limit,
        bytes payload
    );

    function setUp() public {
        vm.prank(owner);
        policy = new AegisPolicy(owner);

        // Mock the system contract at 0xFF so AegisReactive detects 'vm = true'
        mockSystem = new MockSystemContract();
        vm.etch(SYSTEM_CONTRACT_ADDR, address(mockSystem).code);

        reactive = new AegisReactive(address(policy), chainId, hook);

        vm.prank(owner);
        policy.setReactiveContract(address(reactive));
        
        vm.label(SYSTEM_CONTRACT_ADDR, "SystemContract");
        vm.label(address(policy), "AegisPolicy");
        vm.label(address(reactive), "AegisReactive");
    }

    function test_ReactiveEndToEndFlow() public {
        // 1. Initial State
        IAegisPolicy.PolicyParams memory params = IAegisPolicy.PolicyParams({
            swapSize: 1000 ether,
            poolLiquidity: 1000000 ether,
            baseFee: 3000,
            volatilitySignal: 0,
            tier: IAegisPolicy.CoverageTier.Basic
        });

        assertEq(policy.extraBps(), 0);
        uint256 initialPremium = policy.calculatePremium(params);
        assertEq(initialPremium, 0.5 ether);

        // 2. Trigger Claims (Total 6 ether > 5 ether threshold)
        // First claim: 3 ether
        _simulateClaim(3 ether, 100);
        assertEq(reactive.totalClaimsInWindow(), 3 ether);
        assertEq(reactive.isPremiumRaised(), false);

        // Second claim: 3 ether -> Should trigger _raisePremium
        vm.expectEmit(true, true, true, true, address(reactive));
        emit Callback(
            chainId,
            address(policy),
            1000000,
            abi.encodeWithSignature("updateBasePremium(address,uint16)", address(0), uint16(50))
        );
        _simulateClaim(3 ether, 101);

        assertTrue(reactive.isPremiumRaised());
        assertEq(reactive.totalClaimsInWindow(), 6 ether);

        // 3. Manually execute the callback (Simulating Reactive Relayer)
        vm.prank(address(reactive));
        policy.updateBasePremium(address(reactive), 50);

        // Verify premium is raised
        assertEq(policy.extraBps(), 50);
        uint256 raisedPremium = policy.calculatePremium(params);
        assertEq(raisedPremium, 5.5 ether);

        // 4. Test "Quiet Period" Reset
        // Advance 40 blocks (still within 50 block window)
        _simulateQuietReact(140);
        assertTrue(reactive.isPremiumRaised());

        // Advance past the window (101 + 50 = 151)
        vm.expectEmit(true, true, true, true, address(reactive));
        emit Callback(
            chainId,
            address(policy),
            1000000,
            abi.encodeWithSignature("clearBasePremium(address)", address(0))
        );
        _simulateQuietReact(152);

        assertFalse(reactive.isPremiumRaised());
        assertEq(reactive.totalClaimsInWindow(), 0);

        // 5. Manually execute the reset callback
        vm.prank(address(reactive));
        policy.clearBasePremium(address(reactive));

        assertEq(policy.extraBps(), 0);
        assertEq(policy.calculatePremium(params), initialPremium);
    }

    function _simulateClaim(uint256 amount, uint256 blockNumber) internal {
        LogRecord memory record = LogRecord({
            chain_id: chainId,
            _contract: hook,
            topic_0: reactive.CLAIM_PAID_TOPIC_0(),
            topic_1: 0,
            topic_2: 0,
            topic_3: 0,
            data: abi.encode(amount),
            block_number: blockNumber,
            block_hash: 0,
            tx_hash: 0,
            log_index: 0
        });
        reactive.react(record);
    }

    function _simulateQuietReact(uint256 blockNumber) internal {
        // Send a dummy record that doesn't match ClaimPaid to trigger the quiet period check
        LogRecord memory record = LogRecord({
            chain_id: chainId,
            _contract: address(0), 
            topic_0: 0,
            topic_1: 0,
            topic_2: 0,
            topic_3: 0,
            data: "",
            block_number: blockNumber,
            block_hash: 0,
            tx_hash: 0,
            log_index: 0
        });
        reactive.react(record);
    }
}
