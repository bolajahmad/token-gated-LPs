// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/GatedLPHook.sol";
import { IPoolManager } from "v4-core/src/interfaces/IPoolManager.sol";
import {console} from "forge-std/console.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";

contract DeployGatedLPHook is Script {
    function run() external {
        // Need to import Hooks from v4-core for flags
        uint160 flags = uint160(Hooks.BEFORE_ADD_LIQUIDITY_FLAG | Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG);
        
        // Need private key from .env for deployment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Get the pool manager address for the network you're deploying to
        address poolManagerAddress = address(0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408);
        // Get the membership NFT address
        address membershipNFTAddress = address(0x215BA01637F2Bbf91Fcf5Fb4Df6D41bC64820D65);
        // Owner address
        address ownerAddress = address(0x10a945D3F281deE63546bD2f3fF808072FFDA047);

        // Need CREATE2 deployer address for deterministic deployment
        address CREATE2_DEPLOYER = address(0x4e59b44847b379578588920cA78FbF26c0B4956C);

        // Need constructor args for the hook
        bytes memory constructorArgs = abi.encode(poolManagerAddress, membershipNFTAddress, ownerAddress);

        // Need to find the correct salt for deployment
        (address hookAddress, bytes32 salt) =
            HookMiner.find(CREATE2_DEPLOYER, flags, type(GatedLPHook).creationCode, constructorArgs);

        // Need to deploy the hook with found parameters
        GatedLPHook hook = new GatedLPHook{salt: salt}(
            IPoolManager(poolManagerAddress),
            membershipNFTAddress,
            ownerAddress
        );

        console.log("GatedLPHook deployed at:", address(hook));

        vm.stopBroadcast();

        // Need to verify hook was deployed to correct address
        require(address(hook) == hookAddress, "GatedLPHookScript: hook address mismatch");
    }
}
