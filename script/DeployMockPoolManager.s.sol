// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";

/**
 * @title MockPoolManager
 * @notice Mock simples para testar deployment (NÃO usar em produção!)
 */
contract MockPoolManager {
    function unlock(bytes calldata) external returns (bytes memory) {
        revert("Mock - nao implementado");
    }
    
    function swap(
        address,
        address,
        bytes calldata
    ) external pure returns (int256, int256) {
        revert("Mock - nao implementado");
    }
}

/**
 * @title Deploy Mock PoolManager
 * @notice Para testes de deployment apenas
 */
contract DeployMockPoolManager is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== Deploy Mock PoolManager (TESTE APENAS) ===");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        
        vm.startBroadcast(deployerPrivateKey);
        
        MockPoolManager mock = new MockPoolManager();
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("Mock PoolManager deployado em:", address(mock));
        console.log("");
        console.log("ATENCAO: Este e um MOCK para TESTE!");
        console.log("NAO usar em producao ou com fundos reais!");
        console.log("");
        console.log("Use este endereco no DeployKipuBankV3Sepolia.s.sol");
    }
}
