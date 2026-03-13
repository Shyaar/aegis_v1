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
import {AegisOracle} from "../src/AegisOracle.sol";
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";

contract AegisHookTest is Test {
    IPoolManager manager;
    AegisHook hook;
    AegisPolicy policy;
    AegisReserve reserve;
    AegisOracle oracle;

    function setUp() public {
        manager = IPoolManager(address(1)); // Mock
        policy = new AegisPolicy();
        reserve = new AegisReserve(address(this));
        oracle = new AegisOracle();
        
        uint160 flags = uint160(Hooks.BEFORE_INITIALIZE_FLAG | Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG);
        bytes memory constructorArgs = abi.encode(address(manager), address(policy), address(reserve), address(oracle));
        // Deploy CREATE2_FACTORY if not present, but forge test usually has it.
        address CREATE2_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
        (, bytes32 salt) = HookMiner.find(
            CREATE2_FACTORY,
            flags,
            type(AegisHook).creationCode,
            constructorArgs
        );
        hook = new AegisHook{salt: salt}(manager, address(policy), address(reserve), address(oracle));
        
        reserve.setHook(address(hook));
    }

    function test_Permission() public {
        Hooks.Permissions memory permissions = hook.getHookPermissions();
        assertTrue(permissions.beforeInitialize);
        assertTrue(permissions.beforeSwap);
        assertTrue(permissions.afterSwap);
    }
}
