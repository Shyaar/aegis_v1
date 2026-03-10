// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Deployers} from "./Deployers.sol";

abstract contract BaseTest is Test, Deployers {
    function deployArtifactsAndLabel() internal {
        // order matters
    }
}
