// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/*
** Uniswap hook implementation for our GatedLP contract
** Should contain the beforeLiquidity hooks (add & remove)
*/

import { BaseHook } from "v4-periphery/src/utils/BaseHook.sol";

import { PoolId, PoolIdLibrary } from "@uniswap/v4-core/src/types/PoolId.sol";
import { PoolKey } from "v4-core/src/types/PoolKey.sol";
import { Hooks } from "v4-core/src/libraries/Hooks.sol";
import { IPoolManager } from "v4-core/src/interfaces/IPoolManager.sol";

contract GatedLPHook is BaseHook {
    using PoolIdLibrary for PoolKey;

    // Only one LP is expected to connect to this hook anyway
    uint256 private beforeAddLiquidityCount;

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeAddLiquidity: true,
            beforeRemoveLiquidity: true,
            beforeInitialize: false,
            afterInitialize: false,
            afterAddLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: false,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function _beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        bytes calldata hookdata
    ) internal override returns (bytes4) {
        // TODO: Check that the key.id() is for our LP
        beforeAddLiquidityCount++;
        // Check if user has NFT
        return BaseHook.beforeAddLiquidity.selector;
    }

    // TODO: Update `address token` to use type of NFT contract
    function updateNFTContract(address token) external {
        // update contract address
    }
}