// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenLiquidity1 is ERC20 {
    constructor(uint256 initialSupply) ERC20("TOKEN1", "TOK1") {
        _mint(msg.sender, initialSupply);
    }
}

contract tokenLiqiodityDeploy is Script {
    function run() external {

        // priv key deployer z env (np. PRIVATE_KEY)
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // from .env or toml
        address hookDeployerOrBigFish = vm.envAddress("HOOK_DEPLOYER_OR_BIGFISH");
        vm.deal(hookDeployerOrBigFish, 100);
        // Ustalanie początkowej podaży tokenów: 2 000 000 * 10^18 (dla 18 miejsc dziesiętnych)
        uint256 initialSupply = 2_000_000 * 10 ** 18;

        vm.startBroadcast(deployerPrivateKey);
        // Deploy tokena
        TokenLiquidity1 token = new TokenLiquidity1(initialSupply);
        // Transfer wszystkich tokenów do wskazanego adresu
        token.transfer(hookDeployerOrBigFish, token.balanceOf(msg.sender));
        vm.stopBroadcast();
    }
}