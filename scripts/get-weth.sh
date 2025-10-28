#!/bin/bash
# Get WETH - Wrap ETH em WETH na Sepolia

source .env

WETH=0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9
AMOUNT=0.01  # 0.01 ETH

echo "💧 Wrapping ETH em WETH"
echo "======================="
echo ""
echo "WETH Contract: $WETH"
echo "Amount: $AMOUNT ETH"
echo ""

# Wrap ETH
echo "Wrapping..."
TX=$(cast send $WETH \
  "deposit()" \
  --value ${AMOUNT}ether \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  2>&1 | grep "transactionHash" | awk '{print $2}' | tr -d '[]')

if [ ! -z "$TX" ]; then
    echo "✅ Wrap TX: $TX"
    echo ""
    sleep 5
    
    # Verificar balance
    BALANCE=$(cast call $WETH \
        "balanceOf(address)(uint256)" \
        $(cast wallet address --private-key $PRIVATE_KEY) \
        --rpc-url $SEPOLIA_RPC_URL)
    
    echo "💰 Seu saldo WETH: $BALANCE"
    echo ""
    echo "Agora você pode testar deposit de WETH!"
    echo ""
    echo "Execute: ./test-multi-tokens.sh"
else
    echo "❌ Erro ao wrap"
fi
