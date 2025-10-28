// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/KipuBank.sol";

/**
 * @title DeployKipuBank
 * @notice Deployment script for KipuBank contract
 * @dev Use with: forge script script/DeployKipuBank.s.sol:DeployKipuBank --rpc-url <RPC_URL> --broadcast
 */
contract DeployKipuBank is Script {
    // Chainlink ETH/USD Price Feed addresses for different networks
    
    // Sepolia Testnet
    address constant SEPOLIA_ETH_USD = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    
    // Ethereum Mainnet
    address constant MAINNET_ETH_USD = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    
    // Arbitrum Sepolia
    address constant ARB_SEPOLIA_ETH_USD = 0xd30e2101a97dcbAeBCBC04F14C3f624E67A35165;
    
    // Default deployment parameters
    uint256 constant BANK_CAP_USD = 1_000_000e6;        // $1M USD (6 decimals)
    uint256 constant WITHDRAWAL_LIMIT_USD = 10_000e6;   // $10k USD (6 decimals)

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy to Sepolia by default
        KipuBank kipuBank = new KipuBank(
            BANK_CAP_USD,
            WITHDRAWAL_LIMIT_USD,
            SEPOLIA_ETH_USD
        );
        
        console.log("KipuBank deployed to:", address(kipuBank));
        console.log("Bank Cap (USD):", BANK_CAP_USD / 1e6);
        console.log("Withdrawal Limit (USD):", WITHDRAWAL_LIMIT_USD / 1e6);
        console.log("ETH/USD Price Feed:", SEPOLIA_ETH_USD);
        
        vm.stopBroadcast();
    }
    
    /**
     * @notice Deploy to a specific network with custom parameters
     * @param bankCapUsd Bank capacity in USD (6 decimals)
     * @param withdrawalLimitUsd Withdrawal limit in USD (6 decimals)
     * @param ethUsdPriceFeed Chainlink ETH/USD price feed address
     */
    function deployCustom(
        uint256 bankCapUsd,
        uint256 withdrawalLimitUsd,
        address ethUsdPriceFeed
    ) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        KipuBank kipuBank = new KipuBank(
            bankCapUsd,
            withdrawalLimitUsd,
            ethUsdPriceFeed
        );
        
        console.log("KipuBank deployed to:", address(kipuBank));
        console.log("Bank Cap (USD):", bankCapUsd / 1e6);
        console.log("Withdrawal Limit (USD):", withdrawalLimitUsd / 1e6);
        console.log("ETH/USD Price Feed:", ethUsdPriceFeed);
        
        vm.stopBroadcast();
    }
}
