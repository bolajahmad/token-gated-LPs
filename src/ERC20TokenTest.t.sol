// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 

contract TokenLiquidity1 is ERC20 {
    constructor(uint256 initialSupply) ERC20("TOKEN1", "TOK1") {
        _mint(msg.sender, initialSupply);
    }
}

// Deployment script that deploys the token and transfers the entire supply to the hook address.
contract DeployTokenScript {
    // For testing purposes, we set the hook to a fixed address (example address)
    address public constant TEST_HOOK = 0x0000000000000000000000000000000000000004;
    
    function run() public returns (ERC20, address) {
        // Set the initial supply: 2,000,000 tokens (with 18 decimals)
        uint256 initialSupply = 2_000_000 * 10 ** 18;
        // Deploy the token - in the token constructor, the entire supply is assigned to msg.sender (here: DeployTokenScript)
        ERC20 token = new TokenLiquidity1(initialSupply);
        // Transfer the entire token supply to the hook address
        token.transfer(TEST_HOOK, token.totalSupply());
        return (token, TEST_HOOK);
    }
}

// Test contract that verifies the deployment and token transfer.
contract ERC20Test is Test {
    ERC20 public token;
    address public hook;
    // We use address 0x01 as the recipient for the transfer
    address public recipient = address(0x0000000000000000000000000000000000000001);
    uint256 public initialSupply = 2_000_000 * 10 ** 18;

    // setUp() is executed before each test
    function setUp() public {
        // Execute the deployment script and obtain the token and hook addresses
        DeployTokenScript deployer = new DeployTokenScript();
        (token, hook) = deployer.run();
    }

    // Test that verifies the hook holds the full token supply
    function testHookBalance() public {
        uint256 hookBalance = token.balanceOf(hook);
        assertEq(hookBalance, initialSupply, "Hook address should have the full initial supply");
    }

    // Test that sends 1 token from the hook to address 0x01 and checks the recipient's balance
    function testTransferOneToken() public {
        // Use the cheatcode vm.prank to simulate that the transaction is sent by the hook address
        vm.prank(hook);
        token.transfer(recipient, 1);
        uint256 recipientBalance = token.balanceOf(recipient);
        assertEq(recipientBalance, 1, "Recipient should have 1 token after transfer");
    }
}