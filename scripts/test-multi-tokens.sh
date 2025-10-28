#!/bin/bash
# Teste de Múltiplos Tokens - KipuBankV3 Sepolia

source .env

CONTRACT=0x92EC2442Aae8d7Da9106Ec6ca2b2c1D046F7f879
DEPLOYER=0x015Af42bc6a81C5214ae512D6131acb17BF06981

echo "🪙 Testando Múltiplos Tokens - KipuBankV3"
echo "=========================================="
echo ""
echo "Contrato: $CONTRACT"
echo "Deployer: $DEPLOYER"
echo ""

# Tokens e Price Feeds na Sepolia
# Fonte: https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum&page=1#sepolia-testnet

# Token 1: DAI
DAI_ADDRESS=0x7AF17A48a6336F7dc1beF9D485139f7B6f4FB5C8
DAI_USD_FEED=0x14866185B1962B63C3Ea9E03Bc1da838bab34C19

# Token 2: LINK
LINK_ADDRESS=0x779877A7B0D9E8603169DdbD7836e478b4624789
LINK_USD_FEED=0xc59E3633BAAC79493d908e63626716e204A45EdF

# Token 3: USDT (Tether)
USDT_ADDRESS=0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0
USDT_USD_FEED=0x4ec9ce55A72BF37b1597cebA2CB07E88D90f7F89

# Token 4: WBTC (Wrapped Bitcoin) - simulado com BTC feed
WBTC_ADDRESS=0x92f3B59a79bFf5dc60c0d59eA13a44D082B2bdFC
WBTC_USD_FEED=0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43

# Token 5: WETH (Wrapped ETH)
WETH_ADDRESS=0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9
WETH_USD_FEED=0x694AA1769357215DE4FAC081bf1f309aDC325306

echo "═══════════════════════════════════════════"
echo "📝 Fase 1: Adicionar Tokens ao Contrato"
echo "═══════════════════════════════════════════"
echo ""

# Função para adicionar token
add_token() {
    local NAME=$1
    local TOKEN=$2
    local FEED=$3
    
    echo "➕ Adicionando $NAME..."
    echo "   Token: $TOKEN"
    echo "   Feed:  $FEED"
    
    TX=$(cast send $CONTRACT \
        "addToken(address,address)" \
        $TOKEN \
        $FEED \
        --rpc-url $SEPOLIA_RPC_URL \
        --private-key $PRIVATE_KEY \
        2>&1 | grep "transactionHash" | awk '{print $2}' | tr -d '[]')
    
    if [ ! -z "$TX" ]; then
        echo "   ✅ TX: ${TX:0:20}...${TX: -10}"
        sleep 3
    else
        echo "   ⚠️  Pode já estar adicionado ou erro"
    fi
    echo ""
}

# Adicionar tokens
add_token "DAI" $DAI_ADDRESS $DAI_USD_FEED
add_token "LINK" $LINK_ADDRESS $LINK_USD_FEED
add_token "USDT" $USDT_ADDRESS $USDT_USD_FEED
add_token "WBTC" $WBTC_ADDRESS $WBTC_USD_FEED
add_token "WETH" $WETH_ADDRESS $WETH_USD_FEED

echo "═══════════════════════════════════════════"
echo "🔍 Fase 2: Verificar Tokens Adicionados"
echo "═══════════════════════════════════════════"
echo ""

# Função para verificar token
check_token() {
    local NAME=$1
    local TOKEN=$2
    
    echo "🔎 Verificando $NAME ($TOKEN)..."
    INFO=$(cast call $CONTRACT \
        "tokens(address)(bool,uint256,uint8)" \
        $TOKEN \
        --rpc-url $SEPOLIA_RPC_URL)
    
    IS_SUPPORTED=$(echo $INFO | awk '{print $1}')
    DECIMALS=$(echo $INFO | awk '{print $3}')
    
    if [ "$IS_SUPPORTED" == "true" ]; then
        echo "   ✅ Suportado (decimals: $DECIMALS)"
    else
        echo "   ❌ NÃO suportado"
    fi
    echo ""
}

check_token "DAI" $DAI_ADDRESS
check_token "LINK" $LINK_ADDRESS
check_token "USDT" $USDT_ADDRESS
check_token "WBTC" $WBTC_ADDRESS
check_token "WETH" $WETH_ADDRESS

echo "═══════════════════════════════════════════"
echo "💰 Fase 3: Verificar Balanços do Deployer"
echo "═══════════════════════════════════════════"
echo ""

echo "⚠️  NOTA: Você precisa ter estes tokens em sua wallet"
echo "   Para obter tokens de teste na Sepolia:"
echo "   - LINK: https://faucets.chain.link/sepolia"
echo "   - DAI/USDT/WBTC: Swap via Uniswap ou outros faucets"
echo "   - WETH: Wrap seu ETH"
echo ""

# Verificar balanços
check_balance() {
    local NAME=$1
    local TOKEN=$2
    
    BALANCE=$(cast call $TOKEN \
        "balanceOf(address)(uint256)" \
        $DEPLOYER \
        --rpc-url $SEPOLIA_RPC_URL 2>/dev/null || echo "0")
    
    echo "💵 $NAME balance: $BALANCE"
}

check_balance "DAI" $DAI_ADDRESS
check_balance "LINK" $LINK_ADDRESS
check_balance "USDT" $USDT_ADDRESS
check_balance "WBTC" $WBTC_ADDRESS
check_balance "WETH" $WETH_ADDRESS

echo ""
echo "═══════════════════════════════════════════"
echo "📊 Fase 4: Tentar Deposits (se houver saldo)"
echo "═══════════════════════════════════════════"
echo ""

# Função para tentar deposit
try_deposit() {
    local NAME=$1
    local TOKEN=$2
    local AMOUNT=$3
    
    echo "💸 Tentando depositar $NAME..."
    
    # Verificar balance
    BALANCE=$(cast call $TOKEN \
        "balanceOf(address)(uint256)" \
        $DEPLOYER \
        --rpc-url $SEPOLIA_RPC_URL 2>/dev/null || echo "0")
    
    if [ "$BALANCE" == "0" ] || [ -z "$BALANCE" ]; then
        echo "   ⏭️  Pulando (sem saldo)"
        echo ""
        return
    fi
    
    echo "   Saldo disponível: $BALANCE"
    
    # Approve
    echo "   Aprovando..."
    cast send $TOKEN \
        "approve(address,uint256)" \
        $CONTRACT \
        $AMOUNT \
        --rpc-url $SEPOLIA_RPC_URL \
        --private-key $PRIVATE_KEY \
        > /dev/null 2>&1
    
    sleep 3
    
    # Deposit
    echo "   Depositando $AMOUNT..."
    TX=$(cast send $CONTRACT \
        "depositToken(address,uint256)" \
        $TOKEN \
        $AMOUNT \
        --rpc-url $SEPOLIA_RPC_URL \
        --private-key $PRIVATE_KEY \
        2>&1 | grep "transactionHash" | awk '{print $2}' | tr -d '[]')
    
    if [ ! -z "$TX" ]; then
        echo "   ✅ Deposit TX: ${TX:0:20}...${TX: -10}"
        sleep 5
        
        # Verificar saldo no contrato
        BANK_BALANCE=$(cast call $CONTRACT \
            "getUserBalance(address,address)(uint256,uint256)" \
            $DEPLOYER \
            $TOKEN \
            --rpc-url $SEPOLIA_RPC_URL | head -1)
        
        echo "   💰 Saldo no banco: $BANK_BALANCE"
    else
        echo "   ❌ Deposit falhou"
    fi
    echo ""
}

# Tentar deposits (valores pequenos para teste)
try_deposit "DAI" $DAI_ADDRESS 1000000000000000000  # 1 DAI (18 decimals)
try_deposit "LINK" $LINK_ADDRESS 100000000000000000  # 0.1 LINK (18 decimals)
try_deposit "USDT" $USDT_ADDRESS 1000000  # 1 USDT (6 decimals)
try_deposit "WBTC" $WBTC_ADDRESS 10000  # 0.0001 WBTC (8 decimals)
try_deposit "WETH" $WETH_ADDRESS 1000000000000000  # 0.001 WETH (18 decimals)

echo "═══════════════════════════════════════════"
echo "📤 Fase 5: Tentar Withdrawals"
echo "═══════════════════════════════════════════"
echo ""

# Função para tentar withdrawal
try_withdrawal() {
    local NAME=$1
    local TOKEN=$2
    local AMOUNT=$3
    
    echo "💸 Tentando retirar $NAME..."
    
    # Verificar saldo no banco
    BANK_BALANCE=$(cast call $CONTRACT \
        "getUserBalance(address,address)(uint256,uint256)" \
        $DEPLOYER \
        $TOKEN \
        --rpc-url $SEPOLIA_RPC_URL 2>/dev/null | head -1 || echo "0")
    
    if [ "$BANK_BALANCE" == "0" ] || [ -z "$BANK_BALANCE" ]; then
        echo "   ⏭️  Pulando (sem saldo no banco)"
        echo ""
        return
    fi
    
    echo "   Saldo no banco: $BANK_BALANCE"
    
    # Withdrawal
    echo "   Retirando $AMOUNT..."
    TX=$(cast send $CONTRACT \
        "withdraw(address,uint256)" \
        $TOKEN \
        $AMOUNT \
        --rpc-url $SEPOLIA_RPC_URL \
        --private-key $PRIVATE_KEY \
        2>&1 | grep "transactionHash" | awk '{print $2}' | tr -d '[]')
    
    if [ ! -z "$TX" ]; then
        echo "   ✅ Withdrawal TX: ${TX:0:20}...${TX: -10}"
        sleep 5
        
        # Verificar novo saldo
        NEW_BALANCE=$(cast call $CONTRACT \
            "getUserBalance(address,address)(uint256,uint256)" \
            $DEPLOYER \
            $TOKEN \
            --rpc-url $SEPOLIA_RPC_URL | head -1)
        
        echo "   💰 Novo saldo no banco: $NEW_BALANCE"
    else
        echo "   ❌ Withdrawal falhou"
    fi
    echo ""
}

# Tentar withdrawals (metade dos valores depositados)
try_withdrawal "DAI" $DAI_ADDRESS 500000000000000000  # 0.5 DAI
try_withdrawal "LINK" $LINK_ADDRESS 50000000000000000  # 0.05 LINK
try_withdrawal "USDT" $USDT_ADDRESS 500000  # 0.5 USDT
try_withdrawal "WBTC" $WBTC_ADDRESS 5000  # 0.00005 WBTC
try_withdrawal "WETH" $WETH_ADDRESS 500000000000000  # 0.0005 WETH

echo "═══════════════════════════════════════════"
echo "✅ TESTES COMPLETOS!"
echo "═══════════════════════════════════════════"
echo ""
echo "📊 Resumo:"
echo "  - 5 tokens configurados no contrato"
echo "  - Deposits testados (onde havia saldo)"
echo "  - Withdrawals testados (onde havia depósito)"
echo ""
echo "🔗 Ver contrato:"
echo "   https://sepolia.etherscan.io/address/$CONTRACT"
echo ""
echo "💡 Para obter tokens de teste:"
echo "   LINK:  https://faucets.chain.link/sepolia"
echo "   DAI:   Uniswap V3 Sepolia swap"
echo "   WETH:  Wrap ETH em https://sepolia.etherscan.io/address/$WETH_ADDRESS"
echo ""
