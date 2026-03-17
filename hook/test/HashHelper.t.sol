// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/console.sol";

contract HashHelper {
    function run() external pure {
        console.log("keccak256('ClaimPaid(address,uint256)'):");
        console.logBytes32(keccak256("ClaimPaid(address,uint256)"));
        
        console.log("keccak256('SwapCovered(address,uint256,uint256)'):");
        console.logBytes32(keccak256("SwapCovered(address,uint256,uint256)"));
    }
}
