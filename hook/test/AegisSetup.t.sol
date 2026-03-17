// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {Deployers} from "test/utils/Deployers.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";

import {AegisHook} from "../src/AegisHook.sol";
import {AegisPolicy} from "../src/AegisPolicy.sol";
import {AegisReserve} from "../src/AegisReserve.sol";
import {AegisOracle} from "../src/AegisOracle.sol";
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";
import {LPFeeLibrary} from "@uniswap/v4-core/src/libraries/LPFeeLibrary.sol";

contract AegisSetupTest is Test, Deployers {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using StateLibrary for IPoolManager;

    AegisHook public hook;
    AegisPolicy public policy;
    AegisReserve public reserve;
    AegisOracle public oracle;

    IPoolManager public manager;
    Currency public currency0;
    Currency public currency1;
    PoolKey public key;

    uint160 public constant SQRT_PRICE_1_1 = 79228162514264337593543950336;

    function setUp() public {
        manager = IPoolManager(address(new PoolManager(address(0))));
        
        // Use Deployers helper to get tokens
        (currency0, currency1) = deployCurrencyPair();

        // 1. Deploy Aegis Component Contracts
        policy = new AegisPolicy(address(this));
        reserve = new AegisReserve(address(this));
        oracle = new AegisOracle();
        
        // 2. Setup Hook Miner
        uint160 flags = uint160(
            Hooks.BEFORE_INITIALIZE_FLAG | 
            Hooks.BEFORE_SWAP_FLAG | 
            Hooks.AFTER_SWAP_FLAG |
            Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG
        );

        bytes memory constructorArgs = abi.encode(address(manager), address(policy), address(reserve), address(oracle));
        
        (, bytes32 salt) = HookMiner.find(
            address(this),
            flags,
            type(AegisHook).creationCode,
            constructorArgs
        );
        
        hook = new AegisHook{salt: salt}(manager, address(policy), address(reserve), address(oracle));
        reserve.setHook(address(hook));

        // 3. Initialize dynamic fee pool
        key = PoolKey(currency0, currency1, LPFeeLibrary.DYNAMIC_FEE_FLAG, 60, IHooks(address(hook)));
        // Note: Real IPoolManager requires `initialize`. MockPoolManager might not if it's too simple.
        // manager.initialize(key, SQRT_PRICE_1_1);
    }

    function test_Success_Permission() public view {
        Hooks.Permissions memory permissions = hook.getHookPermissions();
        assertTrue(permissions.beforeInitialize, "Should have beforeInitialize flag");
        assertTrue(permissions.beforeSwap, "Should have beforeSwap flag");
        assertTrue(permissions.afterSwap, "Should have afterSwap flag");
        assertTrue(permissions.beforeSwapReturnDelta, "Should have beforeSwapReturnDelta flag");

        
        // Ensure properties we DONT want are false
        assertFalse(permissions.beforeAddLiquidity, "Should NOT have beforeAddLiquidity");
        assertFalse(permissions.beforeRemoveLiquidity, "Should NOT have beforeRemoveLiquidity");
        assertFalse(permissions.afterAddLiquidity, "Should NOT have afterAddLiquidity");
    }
}
