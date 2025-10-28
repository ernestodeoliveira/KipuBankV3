#!/bin/bash
# Setup e Verificação Automática - Etherscan

echo "🔐 Setup de Verificação do Etherscan"
echo "====================================="
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ Arquivo .env não encontrado!"
    echo "   Criando a partir do .env.example..."
    cp .env.example .env
    echo "✅ .env criado"
    echo ""
fi

# Check current API key
source .env 2>/dev/null

if [ -z "$ETHERSCAN_API_KEY" ] || [ "$ETHERSCAN_API_KEY" == "your_etherscan_api_key_here" ]; then
    echo "⚠️  ETHERSCAN_API_KEY não configurada"
    echo ""
    echo "📝 Para obter API key (GRÁTIS):"
    echo "   1. Acesse: https://etherscan.io/myapikey"
    echo "   2. Faça login (ou crie conta)"
    echo "   3. Clique 'Add' para criar nova key"
    echo "   4. Copie a key gerada"
    echo ""
    read -p "Cole sua API key do Etherscan aqui: " API_KEY
    
    if [ -z "$API_KEY" ]; then
        echo "❌ API key vazia. Saindo..."
        exit 1
    fi
    
    # Update .env
    if grep -q "ETHERSCAN_API_KEY=" .env; then
        # Replace existing line
        sed -i.bak "s/ETHERSCAN_API_KEY=.*/ETHERSCAN_API_KEY=$API_KEY/" .env
    else
        # Add new line
        echo "" >> .env
        echo "# Etherscan Verification" >> .env
        echo "ETHERSCAN_API_KEY=$API_KEY" >> .env
    fi
    
    echo "✅ API key salva no .env"
    echo ""
    
    # Reload .env
    source .env
else
    echo "✅ API key já configurada: ${ETHERSCAN_API_KEY:0:10}..."
    echo ""
fi

# Ask to verify
echo "🔍 Verificar contrato agora?"
read -p "Continuar? (s/n): " CONFIRM

if [ "$CONFIRM" != "s" ] && [ "$CONFIRM" != "S" ]; then
    echo "Verificação cancelada"
    exit 0
fi

echo ""
echo "🚀 Iniciando verificação..."
echo ""

# Run verification
./verify.sh
