// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {AegisReactive} from "../src/AegisReactive.sol";
import {console} from "forge-std/console.sol";

/**
 * @notice Deploys AegisReactive to Reactive Network (RNK / Lasna Testnet).
 *
 * Prerequisites (run 01_DeploySepolia.s.sol first):
 *   POLICY_ADDRESS   — AegisPolicy deployed on Sepolia
 *   HOOK_ADDRESS     — AegisHook deployed on Sepolia
 *
 * Required env vars:
 *   REACTIVE_PRIVATE_KEY  — deployer key on RNK
 *   POLICY_ADDRESS        — AegisPolicy address on Sepolia
 *   HOOK_ADDRESS          — AegisHook address on Sepolia
 *
 * Run:
 *   forge script script/02_DeployReactive.s.sol \
 *     --rpc-url $REACTIVE_RPC_URL \
 *     --broadcast \
 *     --chain-id 5318007
 *
 * After deployment, call on Sepolia:
 *   AegisPolicy.setCallbackProxy(<CALLBACK_PROXY_ADDR>)
 *   AegisPolicy.setReactiveContract(<deployed AegisReactive addr>)
 */
contract DeployReactive is Script {
    // Unichain Sepolia chain ID — the origin/destination chain we're monitoring
    uint256 constant SEPOLIA_CHAIN_ID = 1301;

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address policyAddress = vm.envAddress("POLICY_ADDRESS");
        address hookAddress = vm.envAddress("HOOK_ADDRESS");

        console.log("Deploying AegisReactive to Reactive Network...");
        console.log("  Policy (Sepolia):", policyAddress);
        console.log("  Hook   (Sepolia):", hookAddress);

        vm.startBroadcast(deployerKey);

        // Fund with 0.01 ETH for callback gas costs
        AegisReactive reactive = new AegisReactive{value: 0.01 ether}(
            policyAddress,
            SEPOLIA_CHAIN_ID,
            hookAddress
        );

        vm.stopBroadcast();

        // NOTE: Call reactive.subscribe() manually on-chain after deployment
        // (system contract calls revert in simulation)

        console.log("AegisReactive deployed at:", address(reactive));
        console.log("");
        console.log("Next steps on Sepolia:");
        console.log("  AegisPolicy.setCallbackProxy(<CALLBACK_PROXY_ADDR>)");
        console.log("  AegisPolicy.setReactiveContract(", address(reactive), ")");
    }
}
