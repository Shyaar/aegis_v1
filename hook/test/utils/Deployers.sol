// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {
    IPositionManager
} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";

// Simplified Deployers for Hook Testing
abstract contract Deployers {
    IPoolManager poolManager;
    IPositionManager positionManager;

    function deployToken() internal returns (MockERC20 token) {
        token = new MockERC20("Test Token", "TEST", 18);
        token.mint(address(this), 10_000_000 ether);
    }

    function deployCurrencyPair()
        internal
        virtual
        returns (Currency currency0, Currency currency1)
    {
        MockERC20 token0 = deployToken();
        MockERC20 token1 = deployToken();

        if (token0 > token1) {
            (token0, token1) = (token1, token0);
        }

        currency0 = Currency.wrap(address(token0));
        currency1 = Currency.wrap(address(token1));
    }

    function deployArtifactsAndLabel() internal {
        //order matters
        deployPoolManager();
        deployPositionManager();
    }

    function deployPoolManager() internal virtual {
        // Mock or implement as needed
    }

    function deployPositionManager() internal virtual {
        // Mock or implement as needed
    }

    function deployCodeTo(
        string memory,
        bytes memory,
        address
    ) internal virtual {
        // order matters
    }
}
