// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { PoolKey } from "v4-core/src/types/PoolKey.sol";
import { Currency, CurrencyLibrary } from "v4-core/src/types/Currency.sol";
import { IHooks } from "v4-core/src/interfaces/IHooks.sol";
import { IPoolManager } from "v4-core/src/interfaces/IPoolManager.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { Ownable2Step, Ownable } from "@openzeppelin/contracts/access/Ownable2Step.sol";

import { GatedLPHook } from "./GatedLPHook.sol";

contract CreatePool is Ownable2Step {
    Currency immutable token;
    GatedLPHook private immutable hookContract;

    // Pool Manager information: https://docs.uniswap.org/contracts/v4/deployments#sepolia-11155111 
    // Sepolia information
    IPoolManager private constant POOL_MANAGER = IPoolManager(
        address(0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408)
    );

    uint24 private constant LP_FEE = 5000;      // 0.5%
    int24 private constant TICK_SPACING = 100;

    // ETH:CR20 => 1:2
    uint160 startingPrice = 56022770974786139918731938227; // floor(sqrt(0.5) * 2^96)

    constructor(address _token, address _hook, address admin) 
        Ownable(admin)
    {
        token = Currency.wrap(address(_token));
        hookContract = GatedLPHook(address(_hook));
    }

    // This creates a new LP
    // Only the contract owner can call this function
    // Updates the hook contract with the created PoolKey
    function run() external onlyOwner {
        // Setup poolKey configuration
        poolKey = PoolKey({
            currency0: CurrencyLibrary.currency0, // Use native currency (ETH) as currency0
            currency1: token,
            fee: lpFee,
            tickSpacing: tickSpacing,
            hooks: hookContract
        });

        // Save PoolKey to hooks contract
        hookContract.updatePoolKey(pool);

        // Call initialize function, with a starting price
        IPoolManager(POOL_MANAGER).initialize(pool, startingPrice);
    }
}