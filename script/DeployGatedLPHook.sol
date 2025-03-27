// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";

import {Counter} from "../src/GatedLPHook.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";

/// @notice Mines the address and deploys the Counter.sol Hook contract
contract CounterScript is Script {
    IPoolManager constant POOLMANAGER = IPoolManager(address(
        0x5FbDB2315678afecb367f032d93F642f64180aa3
    ));
    address constant CREATE2_DEPLOYER = address(0x4e59b44847b379578588920cA78FbF26c0B4956C);

    function setUp() public {}

    function run() public {
        // hook contracts must have specific flags encoded in the address
        uint160 flags = uint160(
            Hooks.BEFORE_ADD_LIQUIDITY_FLAG
                | Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG
        );

        // Mine a salt that will produce a hook address with the correct flags
        bytes memory constructorArgs = abi.encode(
            POOLMANAGER, 
            0x215BA01637F2Bbf91Fcf5Fb4Df6D41bC64820D65,
            0x215BA01637F2Bbf91Fcf5Fb4Df6D41bC64820D65
        );
        (address hookAddress, bytes32 salt) =
            HookMiner.find(CREATE2_DEPLOYER, flags, type(Counter).creationCode, constructorArgs);

        // Deploy the hook using CREATE2
        vm.broadcast();
        GatedLPHook counter = new GateLPHook{salt: salt}(
            IPoolManager(POOLMANAGER),
            address(0x215BA01637F2Bbf91Fcf5Fb4Df6D41bC64820D65),
            address(0x215BA01637F2Bbf91Fcf5Fb4Df6D41bC64820D65)
        );
        require(address(counter) == hookAddress, "CounterScript: hook address mismatch");
    }
}