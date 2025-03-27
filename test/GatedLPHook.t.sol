// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { Hooks } from "v4-core/src/libraries/Hooks.sol";
import { GatedLPHook } from "GatedLPHook.sol";

import { MockERC20 } from "./mocks/MockERC20.sol";
import { MockGatedNFT } from "./mocks/MockGatedNFT.sol";

contract GatedLPHookTest is Test {
    GatedLPHook hook;

    address nft;
    address owner = address(0x1234);

    function setUp() public {
        // Use the correct flags as defined in the hook permissions
        address flags = address(
            uint160(
                Hooks.BEFORE_ADD_LIQUIDITY_FLAG
                    | Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG
            ) ^ (0x4444 << 144)
        );

        address erc20 = new MockERC20("Mock CNKT", "CNKT", 18);
        nft = new MockGatedNFT(
            "GatedNFT",
            "GNT",
            100,
            90,
            owner,
            erc20
        );

        bytes memory constructorArgs = abi.encode(
            manager,
            nft,
            owner
        );
        deployCodeTo("GatedLPHook.sol:GatedLPHook", constructorArgs, flags);
        hook = GatedLPHook(flags);

        // Create the 
    }
}