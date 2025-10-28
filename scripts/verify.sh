#!/bin/bash
# verify.sh - Script para verificar KipuBankV3 no Etherscan

source .env

CONTRACT=0x92EC2442Aae8d7Da9106Ec6ca2b2c1D046F7f879

echo "🔍 Verificação do Contrato no Etherscan"
echo "========================================"
echo ""
echo "Contrato: $CONTRACT"
echo "Network: Sepolia"
echo ""

# Check API key
if [ -z "$ETHERSCAN_API_KEY" ] || [ "$ETHERSCAN_API_KEY" == "your_etherscan_key_here" ]; then
    echo "❌ ETHERSCAN_API_KEY não configurada!"
    echo ""
    echo "📝 Para configurar:"
    echo "   1. Obtenha API key em: https://etherscan.io/myapikey"
    echo "   2. Edite .env e adicione:"
    echo "      ETHERSCAN_API_KEY=sua_key_aqui"
    echo "   3. Execute: source .env"
    echo "   4. Rode este script novamente"
    echo ""
    exit 1
fi

echo "✅ API Key configurada: ${ETHERSCAN_API_KEY:0:10}..."
echo ""
echo "🔧 Iniciando verificação..."
echo ""

# Verificar contrato
forge verify-contract \
  $CONTRACT \
  src/KipuBankV3.sol:KipuBankV3 \
  --chain sepolia \
  --constructor-args $(cast abi-encode \
    "constructor(uint256,uint256,address,address,address,address)" \
    10000000000000 \
    100000000000 \
    0x694AA1769357215DE4FAC081bf1f309aDC325306 \
    0xE03A1074c86CFeDd5C142C4F04F1a1536e203543 \
    0x000000000022D473030F116dDEE9F6B43aC78BA3 \
    0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238) \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --watch

EXIT_CODE=$?

echo ""
echo "========================================"

if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ VERIFICAÇÃO COMPLETA!"
    echo ""
    echo "🔗 Ver código verificado em:"
    echo "   https://sepolia.etherscan.io/address/$CONTRACT#code"
    echo ""
    echo "📖 Funcionalidades disponíveis:"
    echo "   - Código-fonte legível"
    echo "   - Aba 'Read Contract'"
    echo "   - Aba 'Write Contract'"
    echo "   - Marca verde ✅ de verificado"
    echo ""
else
    echo "❌ Verificação falhou (código: $EXIT_CODE)"
    echo ""
    echo "💡 Possíveis causas:"
    echo "   - Contrato já verificado (verifique no link acima)"
    echo "   - API key inválida"
    echo "   - Constructor args incorretos"
    echo "   - Problema de rede"
    echo ""
    echo "📚 Ver guia completo: cat VERIFY-CONTRACT.md"
    echo ""
fi
