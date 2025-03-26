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
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract CustomC20 is ERC20, Ownable {
    // Token price in wei (ETH/MATIC/etc.)
    uint256 public tokenPrice;
    
    // Maximum amount of free tokens a DAO member can mint
    uint256 public maxFreeMintable;
    
    // Token gating NFT contract
    IERC721 public membershipNFT;
    
    // Track if an address has already claimed free tokens
    mapping(address => bool) public hasClaimedFree;
    
    // Track total amount minted
    uint256 public totalMinted;
    
    // Track total amount burned
    uint256 public totalBurned;
    
    // Events
    event TokensMinted(address indexed to, uint256 amount, bool paidWithNative);
    event TokensBurned(address indexed from, uint256 amount);
    event TokenPriceUpdated(uint256 newPrice);
    event MaxFreeMintableUpdated(uint256 newMax);
    event MembershipNFTUpdated(address newNFTAddress);
    
    constructor(
        string memory _name, 
        string memory _symbol,
        uint256 _initialTokenPrice,
        uint256 _initialMaxFreeMintable,
        address _initialOwner,
        address _membershipNFT
    ) ERC20(_name, _symbol) Ownable(_initialOwner) {
        tokenPrice = _initialTokenPrice;
        maxFreeMintable = _initialMaxFreeMintable;
        membershipNFT = IERC721(_membershipNFT);
    }
    
    /**
     * @dev Mint tokens by paying with native currency
     * @param amount The amount of tokens to mint
     */
    function mint(uint256 amount) external payable {
        uint256 paymentRequired = amount * tokenPrice;
        require(msg.value >= paymentRequired, "Insufficient payment");
        
        totalMinted += amount;
        _mint(msg.sender, amount);
        
        emit TokensMinted(msg.sender, amount, true);
        
        // Return excess payment if any
        if (msg.value > paymentRequired) {
            (bool success, ) = msg.sender.call{value: msg.value - paymentRequired}("");
            require(success, "Refund failed");
        }
    }
    
    /**
     * @dev Free token mint for DAO members (one-time only)
     */
    function claimFreeMint() external {
        require(membershipNFT.balanceOf(msg.sender) > 0, "Not a DAO member");
        require(!hasClaimedFree[msg.sender], "Already claimed free tokens");
        
        hasClaimedFree[msg.sender] = true;
        totalMinted += maxFreeMintable;
        _mint(msg.sender, maxFreeMintable);
        
        emit TokensMinted(msg.sender, maxFreeMintable, false);
    }
    
    /**
     * @dev Burn tokens and receive native currency back
     * @param amount The amount of tokens to burn
     */
    function burn(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        
        uint256 paymentToReturn = amount * tokenPrice;
        require(address(this).balance >= paymentToReturn, "Insufficient contract balance");
        
        _burn(msg.sender, amount);
        totalBurned += amount;
        
        (bool success, ) = msg.sender.call{value: paymentToReturn}("");
        require(success, "Payment failed");
        
        emit TokensBurned(msg.sender, amount);
    }
    
    /**
     * @dev Update token price - only callable by DAO governance
     * @param _newPrice New token price in wei
     */
    function updateTokenPrice(uint256 _newPrice) external onlyOwner {
        tokenPrice = _newPrice;
        emit TokenPriceUpdated(_newPrice);
    }
    
    /**
     * @dev Update max free mintable amount - only callable by DAO governance
     * @param _newMax New maximum free mintable amount
     */
    function updateMaxFreeMintable(uint256 _newMax) external onlyOwner {
        maxFreeMintable = _newMax;
        emit MaxFreeMintableUpdated(_newMax);
    }
    
    /**
     * @dev Update membership NFT contract address - only callable by DAO governance
     * @param _newNFTAddress New membership NFT contract address
     */
    function updateMembershipNFT(address _newNFTAddress) external onlyOwner {
        membershipNFT = IERC721(_newNFTAddress);
        emit MembershipNFTUpdated(_newNFTAddress);
    }
    
    /**
     * @dev Withdraw excess native tokens - only callable by DAO governance
     * @param recipient Address to receive the funds
     * @param amount Amount to withdraw
     */
    function withdrawFunds(address payable recipient, uint256 amount) external onlyOwner {
        // Calculate the amount that needs to be kept for potential token burns
        uint256 requiredReserve = (totalMinted - totalBurned) * tokenPrice;
        uint256 withdrawableAmount = address(this).balance > requiredReserve ? 
                                    address(this).balance - requiredReserve : 0;
        
        require(amount <= withdrawableAmount, "Amount exceeds withdrawable balance");
        
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @dev Function to receive Ether
     */
    receive() external payable {}
}
