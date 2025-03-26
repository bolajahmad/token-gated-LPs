// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract NonTransferableNFT is ERC721, Ownable {
    using SafeERC20 for IERC20;
    
    uint256 private _nextTokenId;
    uint256 public nativePrice;
    uint256 public erc20Price;
    address public paymentToken;
    
    mapping(uint256 => address) public tokenOwner;

    event PriceUpdated(uint256 newNativePrice, uint256 newERC20Price);
    event PaymentTokenUpdated(address newPaymentToken);

    constructor(
        address initialOwner,
        uint256 _nativePrice,
        uint256 _erc20Price,
        address _paymentToken
    ) ERC721("NonTransferableNFT", "NTNFT") Ownable(initialOwner) {
        nativePrice = _nativePrice;
        erc20Price = _erc20Price;
        paymentToken = _paymentToken;
    }

    // Override update function to prevent transfers
    function _update(address to, uint256 tokenId, address auth) internal virtual override returns (address) {
        // Only allow minting (when auth is address(0))
        require(auth == address(0), "Transfers disabled");
        return super._update(to, tokenId, auth);
    }

    // Mint with native currency
    function mintWithNative() external payable {
        require(msg.value >= nativePrice, "Insufficient funds");
        _mintToken(msg.sender);
    }

    // Mint with ERC20 tokens
    function mintWithERC20() external {
        IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), erc20Price);
        _mintToken(msg.sender);
    }

    function _mintToken(address to) private {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }

    // Admin functions
    function setPrices(uint256 newNativePrice, uint256 newERC20Price) external onlyOwner {
        nativePrice = newNativePrice;
        erc20Price = newERC20Price;
        emit PriceUpdated(newNativePrice, newERC20Price);
    }

    function setPaymentToken(address newPaymentToken) external onlyOwner {
        paymentToken = newPaymentToken;
        emit PaymentTokenUpdated(newPaymentToken);
    }

    function withdrawNative() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawERC20() external onlyOwner {
        IERC20(paymentToken).safeTransfer(owner(), IERC20(paymentToken).balanceOf(address(this)));
    }
}
