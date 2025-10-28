// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/KipuBankV3.sol";

/**
 * @title DeployKipuBankV3
 * @notice Deployment script for KipuBankV3 with Uniswap V4 integration
 */
contract DeployKipuBankV3 is Script {
    // Default parameters
    uint256 constant BANK_CAP_USD = 1_000_000e6; // $1M USD
    uint256 constant WITHDRAWAL_LIMIT_USD = 10_000e6; // $10k USD
    
    // Sepolia Testnet Addresses
    address constant SEPOLIA_ETH_USD_FEED = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    
    // Uniswap V4 addresses will need to be updated based on deployment
    // These are placeholder addresses - replace with actual V4 deployments
    address constant SEPOLIA_POOL_MANAGER = 0x0000000000000000000000000000000000000000; // TODO: Update
    address constant SEPOLIA_PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3; // Official Permit2
    address constant SEPOLIA_USDC = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238; // Sepolia USDC
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy KipuBankV3
        KipuBankV3 bank = new KipuBankV3(
            BANK_CAP_USD,
            WITHDRAWAL_LIMIT_USD,
            SEPOLIA_ETH_USD_FEED,
            SEPOLIA_POOL_MANAGER,
            SEPOLIA_PERMIT2,
            SEPOLIA_USDC
        );
        
        console.log("KipuBankV3 deployed at:", address(bank));
        console.log("Bank Cap USD:", BANK_CAP_USD);
        console.log("Withdrawal Limit USD:", WITHDRAWAL_LIMIT_USD);
        console.log("Pool Manager:", SEPOLIA_POOL_MANAGER);
        console.log("Permit2:", SEPOLIA_PERMIT2);
        console.log("USDC:", SEPOLIA_USDC);
        
        vm.stopBroadcast();
    }
    
    /**
     * @notice Deploy with custom parameters
     */
    function deployCustom(
        uint256 _bankCapUsd,
        uint256 _withdrawalLimitUsd,
        address _ethUsdPriceFeed,
        address _poolManager,
        address _permit2,
        address _usdc
    ) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        KipuBankV3 bank = new KipuBankV3(
            _bankCapUsd,
            _withdrawalLimitUsd,
            _ethUsdPriceFeed,
            _poolManager,
            _permit2,
            _usdc
        );
        
        console.log("KipuBankV3 deployed at:", address(bank));
        
        vm.stopBroadcast();
    }
    
    /**
     * @notice Setup initial pool keys after deployment
     * @dev Run this after main deployment to configure token pools
     */
    function setupPoolKeys(address bankAddress) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        KipuBankV3 bank = KipuBankV3(payable(bankAddress));
        
        // Example: Setup DAI/USDC pool
        // address DAI = 0x...; // Sepolia DAI address
        // bank.setPoolKey(
        //     DAI,
        //     DAI,              // currency0
        //     SEPOLIA_USDC,     // currency1
        //     3000,             // 0.3% fee
        //     60,               // tick spacing
        //     address(0)        // no hooks
        // );
        
        console.log("Pool keys configured for bank:", bankAddress);
        
        vm.stopBroadcast();
    }
}
