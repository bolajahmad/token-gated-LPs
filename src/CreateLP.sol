// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { PoolKey } from "v4-core/src/types/PoolKey.sol";
import { Currency, CurrencyLibrary } from "v4-core/src/types/Currency.sol";
import { IHooks } from "v4-core/src/interfaces/IHooks.sol";
import { IPoolManager } from "v4-core/src/interfaces/IPoolManager.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { PoolId } from "@uniswap/v4-core/src/types/PoolId.sol";

import { Ownable2Step, Ownable } from "@openzeppelin/contracts/access/Ownable2Step.sol";

import { GatedLPHook } from "./GatedLPHook.sol";

contract CreatePool is Ownable2Step {
    Currency immutable token;
    GatedLPHook private hookContract;

    // Pool Manager information: https://docs.uniswap.org/contracts/v4/deployments#sepolia-11155111 
    // Sepolia information
    IPoolManager private constant POOL_MANAGER = IPoolManager(
        address(0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408)
    );

    uint24 private lpFee = 5000;      // 0.5%
    int24 private tickSpacing = 100;

    bool public poolCreated;

    // ETH:CR20 => 1:2
    uint160 private startingPrice = 56022770974786139918731938227; // floor(sqrt(0.5) * 2^96)

    // Events emittable
    event PoolParameterUpdated(uint24 lpFee, int24 tickSpacing, uint160 startingPrice);
    event PoolCreated(PoolId poolId, uint160 startingPrice);
    event HookContractUpdated(address newHook);

    // Custom errors
    error PoolAlreadyCreated();
    error PoolCreationFailed();
    error InvalidParameter();
    error InsufficientPermissions();

    constructor(address _token, address _hook, address _admin) 
        Ownable(_admin)
    {
        require(_token != address(0) && _hook != address(0), InvalidParameter());
        token = Currency.wrap(address(_token));
        hookContract = GatedLPHook(address(_hook));
    }

    // This creates a new LP
    // Only the contract owner can call this function
    // Updates the hook contract with the created PoolKey
    function createPool() external onlyOwner returns (PoolKey memory pool) {
        require(!poolCreated, PoolAlreadyCreated());

        // Setup poolKey configuration
        pool = PoolKey({
            currency0: CurrencyLibrary.ADDRESS_ZERO,
            currency1: token,
            fee: lpFee,
            tickSpacing: tickSpacing,
            hooks: hookContract
        });

        // Save PoolKey to hooks contract
        hookContract.setGatedPoolId(pool.toId());

        // Call initialize function, with a starting price
        try IPoolManager(POOL_MANAGER).initialize(pool, startingPrice) {
            poolCreated = true;
            emit PoolCreated(pool.toId(), startingPrice);
            return pool;
        } catch {
            revert("Pool Creation Failed");
        }
    }

    /**
    * @param _lpFee the fee to be paid by LPs
    * @param _startingPrice the starting price of the pool
    * tickSpacing = (_lpFee * 100) / 5000
     */
     function updatePoolParameters(uint24 _lpFee, uint160 _startingPrice) external onlyOwner {
        require(!poolCreated, PoolAlreadyCreated());
        require(_lpFee > 0 && _lpFee <= 10000, InvalidParameter());

        lpFee = _lpFee;
        tickSpacing = int24((_lpFee * 100) / 5000);
        startingPrice = _startingPrice;

        emit PoolParameterUpdated(lpFee, tickSpacing, startingPrice);
    }

    /**
    * Updates the hookContract address before creating Pool 
    * @param _newHook address of the the new hook contract
    */
    function updateHookContract(address _newHook) external onlyOwner {
        require(_newHook != address(0), InvalidParameter());
        hookContract = GatedLPHook(address(_newHook));
        emit HookContractUpdated(_newHook);
    }
}