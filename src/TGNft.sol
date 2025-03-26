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
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenGatingNFT is ERC721, Ownable {
    // NFT minting price in native token (ETH/MATIC/etc.)
    uint256 public mintPriceNative;
    
    // NFT minting price in DAO token
    uint256 public mintPriceToken;
    
    // DAO token address
    IERC20 public daoToken;
    
    // Token counter for minting
    uint256 private _tokenIdCounter;
    
    // Mapping to track if an address has already minted an NFT
    mapping(address => bool) public hasMinted;
    
    // Event declarations
    event MintPriceUpdated(uint256 newPriceNative, uint256 newPriceToken);
    event DAOTokenUpdated(address newTokenAddress);
    event NFTMinted(address indexed to, uint256 tokenId, bool paidWithNative);
    
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
    
    /**
     * @dev Mint a new NFT using native token (ETH/MATIC/etc.)
     */
    function mintWithNative() external payable {
        require(!hasMinted[msg.sender], "Already minted: one NFT per address");
        require(msg.value >= mintPriceNative, "Insufficient payment");
        
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        
        hasMinted[msg.sender] = true;
        _mint(msg.sender, tokenId);
        
        emit NFTMinted(msg.sender, tokenId, true);
    }
    
    /**
     * @dev Mint a new NFT using DAO token
     */
    function mintWithToken() external {
        require(!hasMinted[msg.sender], "Already minted: one NFT per address");
        
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        
        hasMinted[msg.sender] = true;
        
        // Transfer tokens from user to this contract
        require(daoToken.transferFrom(msg.sender, address(this), mintPriceToken), "Token transfer failed");
        
        _mint(msg.sender, tokenId);
        
        emit NFTMinted(msg.sender, tokenId, false);
    }
    
    /**
     * @dev Checks if an address owns any DAO membership NFT
     * @param owner The address to check
     * @return true if the address owns any DAO NFT
     */
    function isMember(address owner) external view returns (bool) {
        return balanceOf(owner) > 0;
    }
    
    /**
     * @dev Update mint prices - only callable by DAO governance
     * @param _newPriceNative New price in native token
     * @param _newPriceToken New price in DAO token
     */
    function updateMintPrices(uint256 _newPriceNative, uint256 _newPriceToken) external onlyOwner {
        mintPriceNative = _newPriceNative;
        mintPriceToken = _newPriceToken;
        
        emit MintPriceUpdated(_newPriceNative, _newPriceToken);
    }
    
    /**
     * @dev Update DAO token address - only callable by DAO governance
     * @param _newTokenAddress New DAO token address
     */
    function updateDAOToken(address _newTokenAddress) external onlyOwner {
        daoToken = IERC20(_newTokenAddress);
        
        emit DAOTokenUpdated(_newTokenAddress);
    }
    
    /**
     * @dev Withdraw collected funds - only callable by DAO governance
     * @param recipient Address to receive the funds
     */
    function withdrawFunds(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @dev Withdraw collected tokens - only callable by DAO governance
     * @param recipient Address to receive the tokens
     */
    function withdrawTokens(address recipient) external onlyOwner {
        uint256 balance = daoToken.balanceOf(address(this));
        require(daoToken.transfer(recipient, balance), "Token transfer failed");
    }
    
    /**
     * @dev Prevent transfers - NFTs are non-transferable
     */
    function transfer(address from, address to, uint256 tokenId) internal {
        revert("NFT is non-transferable");
    }
    
    /**
     * @dev Override approval functions to make tokens non-transferable
     */
    function approve(address to, uint256 tokenId) public override {
        revert("NFT is non-transferable");
    }
    
    function setApprovalForAll(address operator, bool approved) public override {
        revert("NFT is non-transferable");
    }
}
