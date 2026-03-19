// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {
    Currency,
    CurrencyLibrary
} from "@uniswap/v4-core/src/types/Currency.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {LPFeeLibrary} from "@uniswap/v4-core/src/libraries/LPFeeLibrary.sol";

import {MockERC20} from "../src/mocks/MockERC20.sol";
import {AegisPolicy} from "../src/AegisPolicy.sol";
import {AegisReserve} from "../src/AegisReserve.sol";
import {AegisOracle} from "../src/AegisOracle.sol";
import {AegisHook} from "../src/AegisHook.sol";
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";

import {console} from "forge-std/console.sol";

contract DeploySepolia is Script {
    using CurrencyLibrary for Currency;

    // Unichain Sepolia PoolManager
    address constant POOL_MANAGER = 0x00B036B58a818B1BC34d502D3fE730Db729e62AC;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddr = vm.addr(deployerPrivateKey);

        console.log("Deploying from:", deployerAddr);

        vm.startBroadcast(deployerPrivateKey);

        // -------------------------------------------------------
        // STEP 1 — Deploy mock tokens
        // -------------------------------------------------------
        MockERC20 mockUSDC = new MockERC20("Mock USDC", "mUSDC", 6);
        MockERC20 mockWETH = new MockERC20("Mock WETH", "mWETH", 18);

        console.log("mUSDC deployed at:", address(mockUSDC));
        console.log("mWETH deployed at:", address(mockWETH));

        // -------------------------------------------------------
        // STEP 2 — Sort tokens (v4 requires currency0 < currency1)
        // -------------------------------------------------------
        (Currency currency0, Currency currency1) = address(mockUSDC) <
            address(mockWETH)
            ? (
                Currency.wrap(address(mockUSDC)),
                Currency.wrap(address(mockWETH))
            )
            : (
                Currency.wrap(address(mockWETH)),
                Currency.wrap(address(mockUSDC))
            );

        // -------------------------------------------------------
        // STEP 3 — Deploy core Aegis contracts
        // -------------------------------------------------------
        AegisPolicy policy = new AegisPolicy(deployerAddr, 0x9299472A6399Fd1027ebF067571Eb3e3D7837FC4); // Unichain Sepolia Callback Proxy
        AegisOracle oracle = new AegisOracle();
        AegisReserve reserve = new AegisReserve(deployerAddr);

        console.log("AegisPolicy deployed at:", address(policy));
        console.log("AegisReserve deployed at:", address(reserve));

        // -------------------------------------------------------
        // STEP 4 — Mine hook address and deploy AegisHook
        // -------------------------------------------------------
        uint160 flags = uint160(
            Hooks.BEFORE_INITIALIZE_FLAG |
                Hooks.BEFORE_SWAP_FLAG |
                Hooks.AFTER_SWAP_FLAG |
                Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG
        );

        (address hookAddress, bytes32 salt) = HookMiner.find(
            CREATE2_FACTORY,
            flags,
            type(AegisHook).creationCode,
            abi.encode(address(POOL_MANAGER), address(policy), address(reserve), address(oracle))
        );

        AegisHook hook = new AegisHook{salt: salt}(
            IPoolManager(POOL_MANAGER),
            address(policy),
            address(reserve),
            address(oracle)
        );

        require(address(hook) == hookAddress, "Hook address mismatch");
        console.log("AegisHook deployed at:", address(hook));

        // -------------------------------------------------------
        // STEP 5 — Construct PoolKey and initialize pool
        // -------------------------------------------------------
        PoolKey memory poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: LPFeeLibrary.DYNAMIC_FEE_FLAG,
            tickSpacing: 60,
            hooks: IHooks(address(hook))
        });

        // 1 mWETH = 2000 mUSDC starting price
        // pre-calculated sqrtPriceX96 for this ratio
        uint160 startingPrice = 1771595571142957166518320255467520;

        // this triggers beforeInitialize on AegisHook
        IPoolManager(POOL_MANAGER).initialize(poolKey, startingPrice);
        console.log("Pool initialized successfully");

        // -------------------------------------------------------
        // STEP 6 — Mint tokens and seed the reserve
        // -------------------------------------------------------
        // mint tokens for deployer to add liquidity
        mockUSDC.mint(deployerAddr, 100_000e6);
        mockWETH.mint(deployerAddr, 50e18);

        // approve before seeding
        mockUSDC.approve(address(reserve), 10_000e6);
        mockWETH.approve(address(reserve), 5e18);

        // seed both sides
        reserve.seedReserve(address(mockUSDC), 10_000e6);
        reserve.seedReserve(address(mockWETH), 5e18);

        console.log(
            "Reserve mUSDC balance:",
            reserve.getReserveBalance(address(mockUSDC))
        );
        console.log(
            "Reserve mWETH balance:",
            reserve.getReserveBalance(address(mockWETH))
        );
        vm.stopBroadcast();

        console.log("--- Deployment Summary ---");
        console.log(
            "mETH (Token 0):",
            address(
                currency0 == Currency.wrap(address(mockWETH))
                    ? mockWETH
                    : mockUSDC
            )
        );
        console.log(
            "mUSDC (Token 1):",
            address(
                currency1 == Currency.wrap(address(mockUSDC))
                    ? mockUSDC
                    : mockWETH
            )
        );
        console.log("AegisHook:", address(hook));
        console.log("AegisPolicy:", address(policy));
        console.log("AegisReserve:", address(reserve));
        console.log("AegisOracle:", address(oracle));
        console.log("--------------------------");
    }
}
