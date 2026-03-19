// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

contract DeployTokens is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        MockERC20 mWETH = new MockERC20("Mock WETH", "mWETH", 18);
        MockERC20 mUSDC = new MockERC20("Mock USDC", "mUSDC", 6);

        console.log("mWETH:", address(mWETH));
        console.log("mUSDC:", address(mUSDC));

        vm.stopBroadcast();
    }
}
