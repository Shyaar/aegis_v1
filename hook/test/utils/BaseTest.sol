// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test, StdCheats} from "forge-std/Test.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Deployers} from "./Deployers.sol";

abstract contract BaseTest is Test, Deployers {
    function deployArtifactsAndLabel() internal override {
        // order matters
    }

    function deployCodeTo(
        string memory what,
        bytes memory args,
        address where
    ) internal override(StdCheats, Deployers) {
        // Resolve conflict between StdCheats and Deployers
    }
}
