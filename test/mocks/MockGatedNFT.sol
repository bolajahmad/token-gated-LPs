// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { TokenGatingNFT } from "../../src/TGNft.sol";

contract MockGatedNFT is TokenGatingNFT {
    uint256 public mintPriceNative;
    uint256 public mintPriceToken;
    IERC20 public daoToken;
    uint256 private _tokenIdCounter;
    mapping(address => bool) public hasMinted;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialMintPriceNative,
        uint256 _initialMintPriceToken,
        address _initialOwner,
        address _daoToken
    ) ERC721(_name, _symbol) Ownable(_initialOwner) {
        mintPriceNative = _initialMintPriceNative;
        mintPriceToken = _initialMintPriceToken;
        daoToken = IERC20(_daoToken);
    }
}