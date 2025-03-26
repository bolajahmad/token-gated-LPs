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
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Ownable2Step, Ownable } from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract GatedLPHook is BaseHook, Ownable2Step {
    using PoolIdLibrary for PoolKey;

    // Only one LP is expected to connect to this hook anyway
    uint256 private beforeAddLiquidityCount;
    uint256 private beforeRemoveLiquidityCount;
    
    // NFT contract that gates access to the LP
    IERC721 public membershipNFT;
    
    // Pool ID for the gated LP
    PoolId public gatedPoolId;
    
    // Events
    event MembershipNFTUpdated(address newNFTAddress);
    event GatedPoolIdUpdated(PoolId newPoolId);
    event LiquidityAdded(address indexed user, uint256 timestamp);
    event LiquidityRemoved(address indexed user, uint256 timestamp);
    
    constructor(
        IPoolManager _poolManager,
        address _membershipNFT,
        address _initialOwner
    ) BaseHook(_poolManager) Ownable(_initialOwner) {
        membershipNFT = IERC721(_membershipNFT);
    }

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
        bytes calldata /* hookData */
    ) internal override returns (bytes4) {
        // Check if this is our gated pool
        if (PoolId.unwrap(gatedPoolId) != bytes32(0) && PoolId.unwrap(key.toId()) != PoolId.unwrap(gatedPoolId)) {
            // Not our pool, let it pass
            return BaseHook.beforeAddLiquidity.selector;
        }
        
        // Check if user has the required NFT
        require(membershipNFT.balanceOf(sender) > 0, "Not a DAO member");
        
        // Increment counter and emit event
        beforeAddLiquidityCount++;
        emit LiquidityAdded(sender, block.timestamp);
        
        return BaseHook.beforeAddLiquidity.selector;
    }
    
    function _beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        bytes calldata /* hookData */
    ) internal override returns (bytes4) {
        // For liquidity removal, we don't need to check for membership
        // But we track it for analytics
        
        // Check if this is our gated pool
        if (PoolId.unwrap(gatedPoolId) != bytes32(0) && PoolId.unwrap(key.toId()) != PoolId.unwrap(gatedPoolId)) {
            // Not our pool, let it pass
            return BaseHook.beforeRemoveLiquidity.selector;
        }
        
        // Increment counter and emit event
        beforeRemoveLiquidityCount++;
        emit LiquidityRemoved(sender, block.timestamp);
        
        return BaseHook.beforeRemoveLiquidity.selector;
    }

    /**
     * @dev Update the NFT contract address that gates access to the LP
     * @param _membershipNFT New membership NFT contract address
     */
    function updateMembershipNFT(address _membershipNFT) external onlyOwner {
        membershipNFT = IERC721(_membershipNFT);
        emit MembershipNFTUpdated(_membershipNFT);
    }
    
    /**
     * @dev Set the pool ID for the gated LP
     * @param _gatedPoolId Pool ID for the gated LP
     */
    function setGatedPoolId(PoolId _gatedPoolId) external onlyOwner {
        gatedPoolId = _gatedPoolId;
        emit GatedPoolIdUpdated(_gatedPoolId);
    }
    
    /**
     * @dev Get analytics information
     * @return addCount Number of liquidity additions
     * @return removeCount Number of liquidity removals
     */
    function getAnalytics() external view returns (uint256 addCount, uint256 removeCount) {
        return (beforeAddLiquidityCount, beforeRemoveLiquidityCount);
    }
}