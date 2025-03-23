// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
* Token gating NFT contract. This is an ERC721 contract
* Owning this NFT is the proof of membership of a DAO
* This NFT also allows members to join the LP.
*
* This NFT is non-transferrable and non-burnable.
* Minting can be done using the native token, or our custom ERC20.
* Price of the minting can be adjusted by the DAO.
*/

// import the openzeppelin ERC721 contract
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TokenGatingNFT is ERC721 {
    constructor() ERC721("TokenName", "TokenSymbol") {}
}
