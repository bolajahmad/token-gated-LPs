// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TokenGatingNFT.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("MockDAO", "MDAO") {
        _mint(msg.sender, 1000 ether);
    }
}

contract TokenGatingNFTTest is Test {
    TokenGatingNFT public nft;
    MockERC20 public daoToken;
    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    uint256 public mintPriceNative = 1 ether;
    uint256 public mintPriceToken = 100 ether;

    function setUp() public {
        vm.startPrank(owner);
        daoToken = new MockERC20();
        nft = new TokenGatingNFT("TokenGatingNFT", "TGNFT", mintPriceNative, mintPriceToken, owner, address(daoToken));
        vm.stopPrank();
    }

    function testDeployment() public {
        assertEq(nft.name(), "TokenGatingNFT");
        assertEq(nft.symbol(), "TGNFT");
        assertEq(nft.mintPriceNative(), mintPriceNative);
        assertEq(nft.mintPriceToken(), mintPriceToken);
    }

    function testMintWithNative() public {
        vm.deal(user1, 2 ether);
        vm.prank(user1);
        nft.mintWithNative{value: mintPriceNative}();

        assertEq(nft.balanceOf(user1), 1);
        assertTrue(nft.hasMinted(user1));
    }

    function testMintWithToken() public {
        vm.prank(owner);
        daoToken.transfer(user2, mintPriceToken);

        vm.startPrank(user2);
        daoToken.approve(address(nft), mintPriceToken);
        nft.mintWithToken();
        vm.stopPrank();

        assertEq(nft.balanceOf(user2), 1);
        assertTrue(nft.hasMinted(user2));
    }

    function testIsMember() public {
        vm.deal(user1, 2 ether);
        vm.prank(user1);
        nft.mintWithNative{value: mintPriceNative}();
        assertTrue(nft.isMember(user1));
    }

    function testCannotTransferNFT() public {
        vm.deal(user1, 2 ether);
        vm.prank(user1);
        nft.mintWithNative{value: mintPriceNative}();

        vm.expectRevert("NFT is non-transferable");
        vm.prank(user1);
        nft.approve(user2, 0);
    }

    function testUpdateMintPrices() public {
        uint256 newNativePrice = 2 ether;
        uint256 newTokenPrice = 200 ether;
        vm.prank(owner);
        nft.updateMintPrices(newNativePrice, newTokenPrice);

        assertEq(nft.mintPriceNative(), newNativePrice);
        assertEq(nft.mintPriceToken(), newTokenPrice);
    }

    function testWithdrawFunds() public {
        vm.deal(user1, 2 ether);
        vm.prank(user1);
        nft.mintWithNative{value: mintPriceNative}();

        uint256 initialBalance = owner.balance;
        vm.prank(owner);
        nft.withdrawFunds(payable(owner));

        assertGt(owner.balance, initialBalance);
    }
}
