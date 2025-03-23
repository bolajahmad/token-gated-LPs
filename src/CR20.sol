// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
* This is a custom ERC20 token contract used as athe native currency of our DAO.
* This token can be used to mint NFTs and also make decisions within the DAO.
*
* Token is Mintable & Burnable (using the native token).
* Price should rely on Oracle but can be dummmied for now.
* Once-in-a-lifetime free minting for DAO members.
* Has a max free mintable limit that can be updated on-chain.
*/

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CustomC20 is ERC20 {
    constructor() ERC20("TokenName", "TokenSymbol") {}
}
