// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/KipuBankV3.sol";

/**
 * @title Deploy KipuBankV3 na Sepolia
 * @notice Script de deployment para testnet Sepolia
 */
contract DeployKipuBankV3Sepolia is Script {
    // ✅ Endereços oficiais REAIS na Sepolia
    address constant CHAINLINK_ETH_USD = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    address constant USDC_SEPOLIA = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    
    // ✅ Uniswap V4 PoolManager OFICIAL (Sepolia)
    // Fonte: https://docs.uniswap.org/contracts/v4/deployments
    address constant POOL_MANAGER = 0xE03A1074c86CFeDd5C142C4F04F1a1536e203543;
    address constant UNIVERSAL_ROUTER = 0x3A9D48AB9751398BbFa63ad67599Bb04e4BdF98b;
    
    // Configurações do banco
    uint256 constant BANK_CAP_USD = 10_000_000e6; // 10M USD
    uint256 constant WITHDRAWAL_LIMIT_USD = 100_000e6; // 100K USD
    
    function run() external {
        // Validações
        require(POOL_MANAGER != address(0), "POOL_MANAGER nao configurado!");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== Deploy KipuBankV3 na Sepolia ===");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("");
        console.log("Enderecos:");
        console.log("  ETH/USD Feed:", CHAINLINK_ETH_USD);
        console.log("  Permit2:", PERMIT2);
        console.log("  USDC:", USDC_SEPOLIA);
        console.log("  PoolManager:", POOL_MANAGER);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy KipuBankV3
        KipuBankV3 bank = new KipuBankV3(
            BANK_CAP_USD,
            WITHDRAWAL_LIMIT_USD,
            CHAINLINK_ETH_USD,
            POOL_MANAGER,
            PERMIT2,
            USDC_SEPOLIA
        );
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== Deploy Completo ===");
        console.log("KipuBankV3:", address(bank));
        console.log("");
        console.log("Proximo passo:");
        console.log("forge verify-contract", address(bank), "src/KipuBankV3.sol:KipuBankV3");
        console.log("  --chain sepolia");
        console.log("  --constructor-args $(cast abi-encode \"constructor(uint256,uint256,address,address,address,address)\"");
        console.log("    ", BANK_CAP_USD);
        console.log("    ", WITHDRAWAL_LIMIT_USD);
        console.log("    ", CHAINLINK_ETH_USD);
        console.log("    ", POOL_MANAGER);
        console.log("    ", PERMIT2);
        console.log("    ", USDC_SEPOLIA, ")");
    }
}
