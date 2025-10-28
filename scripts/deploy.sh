#!/bin/bash

# 🚀 Deploy Helper para KipuBankV3 na Sepolia
# Execute: chmod +x deploy.sh && ./deploy.sh

set -e

echo "🚀 KipuBankV3 - Deploy na Sepolia"
echo "=================================="
echo ""

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para printar com cor
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Passo 1: Verificar .env
echo "Passo 1: Verificando configuração..."
if [ ! -f .env ]; then
    print_error ".env não encontrado!"
    echo ""
    echo "Criando .env template..."
    cat > .env << 'EOF'
# Sepolia RPC URL (obter em https://dashboard.alchemy.com/)
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY_HERE

# Private Key (SEM 0x no início!)
PRIVATE_KEY=your_private_key_here

# Etherscan API Key (opcional, para verificação)
ETHERSCAN_API_KEY=your_etherscan_key_here
EOF
    print_warning ".env criado!"
    print_warning "EDITE o arquivo .env com suas credenciais e execute novamente"
    echo ""
    echo "Obter RPC grátis: https://dashboard.alchemy.com/"
    echo "Obter ETH Sepolia: https://sepoliafaucet.com/"
    exit 1
fi

# Carregar .env
source .env

# Verificar variáveis
if [ -z "$SEPOLIA_RPC_URL" ] || [ "$SEPOLIA_RPC_URL" == "https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY_HERE" ]; then
    print_error "SEPOLIA_RPC_URL não configurado no .env"
    exit 1
fi

if [ -z "$PRIVATE_KEY" ] || [ "$PRIVATE_KEY" == "your_private_key_here" ]; then
    print_error "PRIVATE_KEY não configurado no .env"
    exit 1
fi

print_success ".env configurado"

# Passo 2: Compilar
echo ""
echo "Passo 2: Compilando contrato..."
if forge build > /dev/null 2>&1; then
    print_success "Contrato compilado"
else
    print_error "Erro ao compilar"
    forge build
    exit 1
fi

# Passo 3: Dry run
echo ""
echo "Passo 3: Simulando deploy (dry run)..."
print_warning "Isso NÃO faz deploy real, apenas simula"
echo ""

if ! forge script script/DeployKipuBankV3Sepolia.s.sol --rpc-url $SEPOLIA_RPC_URL 2>&1 | grep -q "Script ran successfully"; then
    print_error "Simulação falhou!"
    echo "Execute manualmente para ver o erro:"
    echo "forge script script/DeployKipuBankV3Sepolia.s.sol --rpc-url \$SEPOLIA_RPC_URL -vvv"
    exit 1
fi

print_success "Simulação bem-sucedida"

# Passo 4: Confirmar deploy
echo ""
echo "=================================="
print_warning "ATENÇÃO: Próximo passo é o DEPLOY REAL!"
echo ""
echo "Isso vai:"
echo "  - Gastar ETH Sepolia (~0.05 ETH)"
echo "  - Deployar KipuBankV3 na Sepolia"
echo "  - Criar contrato permanente"
echo ""
read -p "Deseja continuar? (sim/não): " confirm

if [ "$confirm" != "sim" ]; then
    echo "Deploy cancelado"
    exit 0
fi

# Passo 5: Deploy real
echo ""
echo "Passo 4: Fazendo deploy na Sepolia..."
print_warning "Aguarde... Isso pode levar 30-60 segundos"
echo ""

# Executar deploy e capturar output
DEPLOY_OUTPUT=$(forge script script/DeployKipuBankV3Sepolia.s.sol \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast \
    -vv 2>&1)

echo "$DEPLOY_OUTPUT"

# Extrair endereço deployado
DEPLOYED_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep "KipuBankV3:" | awk '{print $2}')

if [ -z "$DEPLOYED_ADDRESS" ]; then
    print_error "Não foi possível extrair endereço deployado"
    echo "Verifique o output acima"
    exit 1
fi

echo ""
print_success "Deploy bem-sucedido!"
echo ""
echo "=================================="
echo "📍 Contrato Deployado:"
echo "   $DEPLOYED_ADDRESS"
echo ""
echo "🔗 Ver no Etherscan:"
echo "   https://sepolia.etherscan.io/address/$DEPLOYED_ADDRESS"
echo ""

# Salvar endereço
echo "DEPLOYED_ADDRESS=$DEPLOYED_ADDRESS" >> .env
echo "DEPLOYED_ADDRESS salvo no .env"
echo ""

# Passo 6: Verificar (opcional)
if [ ! -z "$ETHERSCAN_API_KEY" ] && [ "$ETHERSCAN_API_KEY" != "your_etherscan_key_here" ]; then
    echo "Passo 5: Verificando no Etherscan..."
    print_warning "Aguarde 30 segundos para propagação..."
    sleep 30
    
    if forge verify-contract \
        $DEPLOYED_ADDRESS \
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
        --etherscan-api-key $ETHERSCAN_API_KEY > /dev/null 2>&1; then
        print_success "Contrato verificado no Etherscan!"
    else
        print_warning "Verificação falhou (normal se já verificado)"
    fi
else
    print_warning "ETHERSCAN_API_KEY não configurado, pulando verificação"
    echo "   Verifique manualmente em: https://sepolia.etherscan.io/verifyContract"
fi

# Passo 7: Teste rápido
echo ""
echo "Passo 6: Testando deployment..."

# Verificar se tem código
CODE=$(cast code $DEPLOYED_ADDRESS --rpc-url $SEPOLIA_RPC_URL)
if [ -z "$CODE" ] || [ "$CODE" == "0x" ]; then
    print_error "Contrato não tem código!"
    exit 1
fi
print_success "Código verificado"

# Verificar bank cap
BANK_CAP=$(cast call $DEPLOYED_ADDRESS "bankCapUsd()(uint256)" --rpc-url $SEPOLIA_RPC_URL)
if [ "$BANK_CAP" == "10000000000000" ]; then
    print_success "Bank cap configurado corretamente: \$10M"
else
    print_warning "Bank cap inesperado: $BANK_CAP"
fi

echo ""
echo "=================================="
print_success "DEPLOY COMPLETO!"
echo ""
echo "📝 Próximos passos:"
echo "   1. Ver contrato: https://sepolia.etherscan.io/address/$DEPLOYED_ADDRESS"
echo "   2. Adicionar tokens com addToken()"
echo "   3. Configurar pools V4 com setPoolKey()"
echo "   4. Fazer primeiro deposit de teste"
echo ""
echo "📚 Ver guia completo: cat DEPLOY-SEPOLIA.md"
echo ""
