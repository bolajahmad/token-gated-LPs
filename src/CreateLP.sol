// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { PoolKey } from "v4-core/src/types/PoolKey.sol";
import { Currency, CurrencyLibrary } from "v4-core/src/types/Currency.sol";
import { IHooks } from "v4-core/src/interfaces/IHooks.sol";
import { IPoolManager } from "v4-core/src/interfaces/IPoolManager.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CreatePool
 * @dev Contract to create and initialize a Uniswap V4 liquidity pool with token gating
 */
contract CreatePool is Ownable {
    // Token to be paired with ETH in the pool
    Currency public immutable token;
    
    // Hook contract that implements token gating
    IHooks public hookContract;
    
    // Pool Manager address (can be updated for different networks)
    IPoolManager public poolManager;
    
    // LP fee (in hundredths of a bip, so 5000 = 0.5%)
    uint24 public lpFee;
    
    // Tick spacing for the pool
    int24 public tickSpacing;
    
    // Starting price for the pool (sqrt price * 2^96)
    uint160 public startingPrice;
    
    // Status of the pool creation
    bool public poolCreated;
    
    // Pool key for the created pool
    PoolKey public poolKey;
    
    // Events
    event PoolParametersUpdated(uint24 lpFee, int24 tickSpacing, uint160 startingPrice);
    event HookContractUpdated(address newHook);
    event PoolManagerUpdated(address newPoolManager);
    event PoolCreated(PoolKey poolKey, uint160 startingPrice);
    
    // Custom errors
    error PoolAlreadyCreated();
    error PoolCreationFailed();
    error InvalidParameter();
    error InsufficientPermissions();

    constructor(
        address _token, 
        address _hook, 
        address _poolManager,
        address _initialOwner
    ) Ownable(_initialOwner) {
        if (_token == address(0)) revert InvalidParameter();
        if (_hook == address(0)) revert InvalidParameter();
        if (_poolManager == address(0)) revert InvalidParameter();
        
        token = Currency.wrap(_token);
        hookContract = IHooks(_hook);
        poolManager = IPoolManager(_poolManager);
        
        // Default values (can be updated before pool creation)
        lpFee = 5000;      // 0.5%
        tickSpacing = 100;
        startingPrice = 56022770974786139918731938227; // floor(sqrt(0.5) * 2^96)
    }

    /**
     * @dev Create and initialize the liquidity pool
     * @return The created pool key
     */
    function createPool() external onlyOwner returns (PoolKey memory) {
        if (poolCreated) revert PoolAlreadyCreated();
        
        // Setup poolKey configuration
        poolKey = PoolKey({
            currency0: CurrencyLibrary.currency0, // Use native currency (ETH) as currency0
            currency1: token,
            fee: lpFee,
            tickSpacing: tickSpacing,
            hooks: hookContract
        });

        try IPoolManager(poolManager).initialize(poolKey, startingPrice) {
            poolCreated = true;
            emit PoolCreated(poolKey, startingPrice);
            return poolKey;
        } catch {
            revert PoolCreationFailed();
        }
    }
    
    /**
     * @dev Update pool parameters before pool creation
     * @param _lpFee New LP fee
     * @param _tickSpacing New tick spacing
     * @param _startingPrice New starting price
     */
    function updatePoolParameters(
        uint24 _lpFee,
        int24 _tickSpacing,
        uint160 _startingPrice
    ) external onlyOwner {
        if (poolCreated) revert PoolAlreadyCreated();
        if (_startingPrice == 0) revert InvalidParameter();
        
        lpFee = _lpFee;
        tickSpacing = _tickSpacing;
        startingPrice = _startingPrice;
        
        emit PoolParametersUpdated(_lpFee, _tickSpacing, _startingPrice);
    }
    
    /**
     * @dev Update the hook contract before pool creation
     * @param _newHook New hook contract address
     */
    function updateHookContract(address _newHook) external onlyOwner {
        if (poolCreated) revert PoolAlreadyCreated();
        if (_newHook == address(0)) revert InvalidParameter();
        
        hookContract = IHooks(_newHook);
        
        emit HookContractUpdated(_newHook);
    }
    
    /**
     * @dev Update the pool manager contract before pool creation
     * @param _newPoolManager New pool manager contract address
     */
    function updatePoolManager(address _newPoolManager) external onlyOwner {
        if (poolCreated) revert PoolAlreadyCreated();
        if (_newPoolManager == address(0)) revert InvalidParameter();
        
        poolManager = IPoolManager(_newPoolManager);
        
        emit PoolManagerUpdated(_newPoolManager);
    }
}