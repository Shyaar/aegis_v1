// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {AegisHook} from "../src/AegisHook.sol";

contract AegisHookTest is Test {
    IPoolManager manager;
    AegisHook hook;

    function setUp() public {
        manager = IPoolManager(address(1)); // Mock
        hook = new AegisHook(manager);
    }

    function test_Permission() public {
        Hooks.Permissions memory permissions = hook.getHookPermissions();
        assertTrue(permissions.beforeSwap);
        assertTrue(permissions.afterSwap);
    }
}
