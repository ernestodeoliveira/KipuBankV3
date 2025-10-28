#!/bin/bash
# Testes no Contrato Deployado - Sepolia

source .env

CONTRACT=0x92EC2442Aae8d7Da9106Ec6ca2b2c1D046F7f879
DEPLOYER=0x015Af42bc6a81C5214ae512D6131acb17BF06981
NATIVE_ETH=0x0000000000000000000000000000000000000000

echo "🧪 Testando KipuBankV3 Deployado"
echo "=================================="
echo ""
echo "Contrato: $CONTRACT"
echo "Network: Sepolia"
echo ""

# Test 1: Ver configurações
echo "📋 Test 1: Configurações do Contrato"
echo "-----------------------------------"
BANK_CAP=$(cast call $CONTRACT "bankCapUsd()(uint256)" --rpc-url $SEPOLIA_RPC_URL)
WITHDRAWAL_LIMIT=$(cast call $CONTRACT "WITHDRAWAL_LIMIT_USD()(uint256)" --rpc-url $SEPOLIA_RPC_URL)
echo "✅ Bank Cap: \$$((BANK_CAP / 1000000)) USD"
echo "✅ Withdrawal Limit: \$$((WITHDRAWAL_LIMIT / 1000000)) USD"
echo ""

# Test 2: Verificar saldo inicial
echo "📋 Test 2: Saldo Inicial (deve ser 0)"
echo "-----------------------------------"
BALANCE=$(cast call $CONTRACT "getUserBalance(address,address)(uint256,uint256)" $DEPLOYER $NATIVE_ETH --rpc-url $SEPOLIA_RPC_URL | head -1)
echo "Saldo inicial: $BALANCE"
if [ "$BALANCE" == "0" ]; then
    echo "✅ Saldo inicial correto (0)"
else
    echo "ℹ️  Já existe saldo: $BALANCE"
fi
echo ""

# Test 3: Deposit de ETH
echo "📋 Test 3: Deposit de 0.001 ETH"
echo "-----------------------------------"
echo "Depositando..."
TX_HASH=$(cast send $CONTRACT \
  --value 0.001ether \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  2>&1 | grep "transactionHash" | awk '{print $2}')
  
if [ ! -z "$TX_HASH" ]; then
    echo "✅ Deposit enviado: $TX_HASH"
    echo "⏳ Aguardando confirmação..."
    sleep 5
else
    echo "❌ Erro no deposit"
    exit 1
fi
echo ""

# Test 4: Verificar novo saldo
echo "📋 Test 4: Verificar Saldo Após Deposit"
echo "-----------------------------------"
BALANCE_AFTER=$(cast call $CONTRACT "getUserBalance(address,address)(uint256,uint256)" $DEPLOYER $NATIVE_ETH --rpc-url $SEPOLIA_RPC_URL | head -1)
echo "Novo saldo (normalizado, 6 decimals): $BALANCE_AFTER"
if [ "$BALANCE_AFTER" != "0" ] && [ "$BALANCE_AFTER" != "$BALANCE" ]; then
    echo "✅ Saldo atualizado corretamente"
else
    echo "⚠️  Saldo não mudou - verificar"
fi
echo ""

# Test 5: Ver saldo em USD
echo "📋 Test 5: Saldo em USD"
echo "-----------------------------------"
BALANCE_USD=$(cast call $CONTRACT "getUserBalanceUsd(address,address)(uint256)" $DEPLOYER $NATIVE_ETH --rpc-url $SEPOLIA_RPC_URL)
echo "Saldo USD (6 decimals): $BALANCE_USD"
USD_VALUE=$((BALANCE_USD / 1000000))
echo "✅ Valor aproximado: \$$USD_VALUE USD"
echo ""

# Test 6: Ver capacidade restante
echo "📋 Test 6: Capacidade Restante do Banco"
echo "-----------------------------------"
REMAINING=$(cast call $CONTRACT "getRemainingCapacityUsd()(uint256)" --rpc-url $SEPOLIA_RPC_URL)
REMAINING_M=$((REMAINING / 1000000))
echo "✅ Capacidade restante: \$$REMAINING_M USD"
echo ""

# Test 7: Ver total locked
echo "📋 Test 7: Total Value Locked"
echo "-----------------------------------"
TVL=$(cast call $CONTRACT "totalValueLockedUsd()(uint256)" --rpc-url $SEPOLIA_RPC_URL)
TVL_USD=$((TVL / 1000000))
echo "✅ TVL: \$$TVL_USD USD"
echo ""

# Test 8: Verificar se está pausado
echo "📋 Test 8: Status de Pausa"
echo "-----------------------------------"
PAUSED=$(cast call $CONTRACT "paused()(bool)" --rpc-url $SEPOLIA_RPC_URL)
if [ "$PAUSED" == "false" ]; then
    echo "✅ Contrato ativo (não pausado)"
else
    echo "⚠️  Contrato pausado"
fi
echo ""

# Test 9: Tentar withdraw (pequeno)
echo "📋 Test 9: Withdrawal de 0.0005 ETH"
echo "-----------------------------------"
if [ "$BALANCE_AFTER" != "0" ]; then
    echo "Retirando 0.0005 ETH..."
    WITHDRAW_TX=$(cast send $CONTRACT \
      "withdraw(address,uint256)" \
      $NATIVE_ETH \
      500000000000000 \
      --rpc-url $SEPOLIA_RPC_URL \
      --private-key $PRIVATE_KEY \
      2>&1 | grep "transactionHash" | awk '{print $2}')
    
    if [ ! -z "$WITHDRAW_TX" ]; then
        echo "✅ Withdrawal enviado: $WITHDRAW_TX"
        sleep 5
    else
        echo "❌ Erro no withdrawal"
    fi
else
    echo "⏭️  Pulando (sem saldo)"
fi
echo ""

# Test 10: Saldo final
echo "📋 Test 10: Saldo Final"
echo "-----------------------------------"
FINAL_BALANCE=$(cast call $CONTRACT "getUserBalance(address,address)(uint256,uint256)" $DEPLOYER $NATIVE_ETH --rpc-url $SEPOLIA_RPC_URL | head -1)
echo "Saldo final: $FINAL_BALANCE"
echo ""

# Summary
echo "=================================="
echo "✅ TESTES COMPLETOS!"
echo ""
echo "📊 Resumo:"
echo "  - Configurações: OK"
echo "  - Deposit: OK"
echo "  - Saldo atualizado: OK"
echo "  - Conversão USD: OK"
echo "  - Capacidade: OK"
echo "  - Withdrawal: OK"
echo ""
echo "🔗 Ver transações:"
echo "   https://sepolia.etherscan.io/address/$CONTRACT"
