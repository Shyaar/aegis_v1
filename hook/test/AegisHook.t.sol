// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {AegisHook} from "../src/AegisHook.sol";

import {AegisHook} from "../src/AegisHook.sol";
import {AegisPolicy} from "../src/AegisPolicy.sol";
import {AegisReserve} from "../src/AegisReserve.sol";

contract AegisHookTest is Test {
    IPoolManager manager;
    AegisHook hook;
    AegisPolicy policy;
    AegisReserve reserve;

    function setUp() public {
        manager = IPoolManager(address(1)); // Mock
        policy = new AegisPolicy();
        reserve = new AegisReserve(address(this));
        hook = new AegisHook(manager, address(policy), address(reserve));
        
        reserve.setHook(address(hook));
    }

    function test_Permission() public {
        Hooks.Permissions memory permissions = hook.getHookPermissions();
        assertTrue(permissions.beforeSwap);
        assertTrue(permissions.afterSwap);
    }
}
