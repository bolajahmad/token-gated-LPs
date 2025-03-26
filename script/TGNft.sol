// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import { TokenGatingNFT } from "../src/TGNft.sol";

contract TGNftScript is Script {
    TokenGatingNFT public nft;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        nft = new TokenGatingNFT("Name", "Symb", 100, 200, address(0x01), address(0x02));

        vm.stopBroadcast();
    }
}
