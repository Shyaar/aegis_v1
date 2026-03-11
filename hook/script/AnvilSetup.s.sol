// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {AegisHook} from "../src/AegisHook.sol";
import {AegisPolicy} from "../src/AegisPolicy.sol";
import {AegisReserve} from "../src/AegisReserve.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";

import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";

import {console} from "forge-std/console.sol";

contract AnvilSetup is Script {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddr = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Tokens
        MockERC20 aegis = new MockERC20("Aegis Token", "AEGIS", 18);
        MockERC20 usdc = new MockERC20("USD Coin", "USDC", 18);

        // 2. Sort Currencies
        (Currency currency0, Currency currency1) = address(aegis) < address(usdc) 
            ? (Currency.wrap(address(aegis)), Currency.wrap(address(usdc)))
            : (Currency.wrap(address(usdc)), Currency.wrap(address(aegis)));

        // 3. Deploy PoolManager
        PoolManager manager = new PoolManager(deployerAddr);

        // 4. Deploy Aegis Suite
        AegisPolicy policy = new AegisPolicy();
        AegisReserve reserve = new AegisReserve(deployerAddr);
        
        // 5. Mine Hook Address
        uint160 flags = uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG);
        
        bytes memory constructorArgs = abi.encode(address(manager), address(policy), address(reserve));
        
        // Use the standard CREATE2 factory address used by forge script
        address CREATE2_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
        
        (address hookAddr, bytes32 salt) = HookMiner.find(
            CREATE2_FACTORY,
            flags,
            type(AegisHook).creationCode,
            constructorArgs
        );

        AegisHook hook = new AegisHook{salt: salt}(IPoolManager(address(manager)), address(policy), address(reserve));
        require(address(hook) == hookAddr, "Hook address mismatch");
        
        reserve.setHook(address(hook));

        // 6. Initialize Pool
        uint160 startingPrice = uint160(TickMath.getSqrtPriceAtTick(0)); // 1:1 price
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(hook))
        });

        IPoolManager(address(manager)).initialize(key, startingPrice);

        // 7. Fund Reserve
        usdc.mint(address(reserve), 100000 ether);
        aegis.mint(address(reserve), 100000 ether);

        vm.stopBroadcast();
        
        // Log addresses for frontend/env
        console.log("AEGIS:", address(aegis));
        console.log("USDC:", address(usdc));
        console.log("PoolManager:", address(manager));
        console.log("Hook:", address(hook));
        console.log("Reserve:", address(reserve));
    }
}
