// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { TokenGatingNFT } from "../src/TGNft.sol";
import { CustomC20 } from "../src/CR20.sol";
import { GatedLPHook } from "../src/GatedLPHook.sol";
import { CreatePool } from "../src/CreateLP.sol";
import { PoolKey } from "v4-core/src/types/PoolKey.sol";
import { IPoolManager } from "v4-core/src/interfaces/IPoolManager.sol";

/**
 * @title Deploy
 * @dev Script to deploy and set up all contracts for a token-gated LP
 */
contract Deploy is Script {
    // Mainnet pool manager address, needs to be updated for the target network
    address constant POOL_MANAGER_ADDRESS = 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408; // Sepolia address
    
    // Initial prices and parameters
    uint256 constant INITIAL_MINT_PRICE_NATIVE = 0.01 ether;
    uint256 constant INITIAL_MINT_PRICE_TOKEN = 10 ether; // 10 tokens
    uint256 constant INITIAL_TOKEN_PRICE = 0.001 ether; // 1 token = 0.001 ETH
    uint256 constant INITIAL_MAX_FREE_MINTABLE = 100 ether; // 100 tokens for free mint
    
    TokenGatingNFT public nft;
    CustomC20 public token;
    GatedLPHook public hook;
    CreatePool public poolCreator;
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Deploy DAO token
        token = new CustomC20(
            "DAO Token",
            "DAO",
            INITIAL_TOKEN_PRICE,
            INITIAL_MAX_FREE_MINTABLE,
            deployer,
            address(0) // Will update after NFT deployment
        );
        console2.log("DAO Token deployed at:", address(token));
        
        // Step 2: Deploy membership NFT
        nft = new TokenGatingNFT(
            "DAO Membership",
            "DAOM",
            INITIAL_MINT_PRICE_NATIVE,
            INITIAL_MINT_PRICE_TOKEN,
            deployer,
            address(token)
        );
        console2.log("Membership NFT deployed at:", address(nft));
        
        // Step 3: Update token with NFT address
        token.updateMembershipNFT(address(nft));
        console2.log("DAO Token updated with NFT address");
        
        // Step 4: Deploy the hook contract
        hook = new GatedLPHook(
            IPoolManager(POOL_MANAGER_ADDRESS),
            address(nft),
            deployer
        );
        console2.log("LP Hook deployed at:", address(hook));
        
        // Step 5: Deploy the pool creator
        poolCreator = new CreatePool(
            address(token),
            address(hook),
            deployer
        );
        console2.log("Pool Creator deployed at:", address(poolCreator));
        
        // Step 6: Create the pool
        PoolKey memory poolKey = poolCreator.createPool();
        console2.log("Liquidity Pool created");
        
        // Step 7: Update the hook with the pool ID
        hook.setGatedPoolId(poolKey.toId());
        console2.log("Hook updated with pool ID");
        
        vm.stopBroadcast();
        
        console2.log("Deployment complete!");
        console2.log("Token:", address(token));
        console2.log("NFT:", address(nft));
        console2.log("Hook:", address(hook));
        console2.log("Pool Creator:", address(poolCreator));
    }
} 