// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { PoolKey } from "v4-core/src/types/PoolKey.sol";
import { Currency, CurrencyLibrary } from "v4-core/src/types/Currency.sol";
import { IHooks } from "v4-core/src/interfaces/IHooks.sol";
import { IPOolManager } from "v4-core/src/interfaces/IPoolManager.sol";

contract CreatePool {
    Currency immutable token;
    IHooks private hook;

    // Pool Manager information: https://docs.uniswap.org/contracts/v4/deployments#sepolia-11155111 
    // Sepolia information
    IPoolManager private constant POOL_MANAGER = IPoolManager(address(0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408));

    uint24 private constant LP_FEE = 5000;      // 0.5%
    int24 private constant TICK_SPACING = 100;

    constructor(address _token, hook) {
        token = Currency.wrap(address(_token));
    }

    function run() external {
        // Setup poolKey configuration
        PoolKey memory pool = PoolKey({
            currency0: CurrencyLibrary.ADDRESS_ZERO,
            currency1: token,
            fee: LP_FEE,
            tickSpacing: TICK_SPACING,
            hook
        });

        // Call initialize function, with a starting price
        IPoolManager(POOL_MANAGER).initialize(pool, getStartingPrice());
    }

    /* The startingPrice is expressed as sqrtPriceX96 */
    function getStartingPrice() internal returns (uint256) {
        // Get the price of the token
        uint256 tokenAmount = 5e17;
        uint256 ethAmount = 1e18;
        // Return the price of the token
        uint256 startPrice = floor(sqrt(ethAmount / tokenAmount) * 2**96);
        return startPrice;
    }
}