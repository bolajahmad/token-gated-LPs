// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {CreatePool} from "../src/CreateLP.sol";
import {GatedLPHook} from "../src/GatedLPHook.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";

contract DeployCreatLPScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address tokenAddress = address(0xB9C358FF5988687F344e022C5E795113CE9bbEe4);
        address membershipNFT = address(0x215BA01637F2Bbf91Fcf5Fb4Df6D41bC64820D65);
        address adminAddress = address(0x10a945D3F281deE63546bD2f3fF808072FFDA047);
        address hook = address(0xf3aA127b76929a7226fC125Bef255d669A7D8a00);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Then deploy the CreatePool contract with the hook
        CreatePool createPool = new CreatePool(
            tokenAddress,
            address(hook),
            adminAddress
        );
        
        vm.stopBroadcast();
        
        
        console.log("CreatePool deployed at:", address(createPool));
    }
}

