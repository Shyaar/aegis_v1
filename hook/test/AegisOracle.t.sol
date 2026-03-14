// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {Deployers} from "test/utils/Deployers.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";

import {AegisOracle} from "../src/AegisOracle.sol";

contract AegisOracleTest is Test, Deployers {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    AegisOracle public oracle;
    IPoolManager public manager;
    Currency public currency0;
    Currency public currency1;
    PoolKey public key;

    function setUp() public {
        manager = IPoolManager(address(new PoolManager(address(0))));
        
        // Mock currencies
        (currency0, currency1) = deployCurrencyPair();

        oracle = new AegisOracle();

        // Create a dummy poolkey, Oracle only cares about the PoolId
        key = PoolKey(currency0, currency1, 3000, 60, IHooks(address(0)));
    }

    /* =========================================================================
       updateObservation()
       ========================================================================= */

    function test_Success_updateObservation_InitializesWindow() public {
        PoolId pid = key.toId();
        
        vm.warp(1000);
        
        oracle.updateObservation(pid, 100);

        // Fetch back using observation view
        (uint16 index, uint16 count) = oracle.poolObservations(pid);
        
        assertEq(count, 1, "Window count should be 1");
        assertEq(index, 1, "Index should have advanced to 1");
    }

    function test_Success_updateObservation_SameBlockIgnored() public {
        PoolId pid = key.toId();
        
        vm.warp(1000);
        oracle.updateObservation(pid, 100);
        oracle.updateObservation(pid, 200); // Should be ignored due to debounce

        (uint16 index, uint16 count) = oracle.poolObservations(pid);
        
        assertEq(count, 1, "Window count should still be 1");
        assertEq(index, 1, "Index should still be 1");
    }

    function testFuzz_updateObservation(int24 tick) public {
        PoolId pid = key.toId();
        oracle.updateObservation(pid, tick);

        (uint16 index, uint16 count) = oracle.poolObservations(pid);
        assertEq(count, 1);
        assertEq(index, 1);
    }

    /* =========================================================================
       getVolatilitySignal()
       ========================================================================= */

    function test_Revert_getVolatilitySignal_NotEnoughData() public {
        PoolId pid = key.toId();
        
        // 0 observations
        uint256 vol = oracle.getVolatilitySignal(pid);
        assertEq(vol, 0, "Volatility should be 0 with no data");

        // 1 observation
        vm.warp(1000);
        oracle.updateObservation(pid, 100);
        
        vol = oracle.getVolatilitySignal(pid);
        assertEq(vol, 0, "Volatility should be 0 with 1 data point");
    }

    function test_Success_getVolatilitySignal() public {
        PoolId pid = key.toId();
        
        vm.warp(1000);
        oracle.updateObservation(pid, 100); // min
        
        vm.warp(1010);
        oracle.updateObservation(pid, 500); // max

        vm.warp(1020);
        oracle.updateObservation(pid, 200);

        // Volatility = maxTick(500) - minTick(100) = 400
        uint256 vol = oracle.getVolatilitySignal(pid);
        assertEq(vol, 400, "Volatility should be 400");
    }

    function testFuzz_getVolatilitySignal(int24 tick1, int24 tick2) public {
        // Bound ticks to reasonable Uniswap V4 ranges to prevent overflow/underflow reverts in test setup
        tick1 = int24(bound(tick1, -887272, 887272));
        tick2 = int24(bound(tick2, -887272, 887272));

        PoolId pid = key.toId();
        
        vm.warp(1000);
        oracle.updateObservation(pid, tick1);
        
        vm.warp(1010);
        oracle.updateObservation(pid, tick2);

        uint256 expectedVol = tick1 > tick2 ? uint256(int256(tick1 - tick2)) : uint256(int256(tick2 - tick1));

        uint256 vol = oracle.getVolatilitySignal(pid);
        assertEq(vol, expectedVol, "Fuzzed Volatility deviation mismatches");
    }
}
