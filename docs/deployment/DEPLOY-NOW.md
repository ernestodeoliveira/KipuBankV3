# 🚀 Deploy Imediato na Sepolia - Guia Rápido

## ✅ Pré-requisitos

### 1. Private Key
Você precisa de uma wallet com:
- ✅ Private key (MetaMask, etc.)
- ✅ ~0.1 ETH Sepolia (para gas)

**Obter ETH Sepolia:**
- https://sepoliafaucet.com/
- https://www.alchemy.com/faucets/ethereum-sepolia

### 2. RPC URL (grátis)
Opções gratuitas:
- Alchemy: https://dashboard.alchemy.com/
- Infura: https://infura.io/

### 3. Etherscan API Key (opcional, para verificação)
- https://etherscan.io/myapikey

---

## 📝 Passo 1: Configurar .env

```bash
cd /Users/ernesto/Documents/Solidity/eth-kipu-uniswap/SwapModule

# Criar arquivo .env
cat > .env << 'EOF'
# Sepolia RPC URL
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY_HERE

# Private Key (SEM 0x no início!)
PRIVATE_KEY=sua_private_key_aqui_sem_0x

# Etherscan API Key (opcional)
ETHERSCAN_API_KEY=sua_etherscan_key_aqui
EOF

echo "✅ Arquivo .env criado!"
echo "⚠️  EDITE O ARQUIVO .env e adicione suas credenciais!"
```

**⚠️ IMPORTANTE:**
- NÃO commitar .env no git
- NÃO compartilhar sua private key
- Private key SEM "0x" no início

---

## 🔧 Passo 2: Compilar

```bash
# Compilar contrato
forge build

# Verificar se compilou
echo "✅ Compilado com sucesso!"
```

---

## 🚀 Passo 3: Deploy (Dry Run)

Primeiro, fazer um dry-run sem broadcast:

```bash
forge script script/DeployKipuBankV3Sepolia.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  -vvv
```

Isso mostra:
- ✅ Endereço do deployer
- ✅ Todos os endereços de contratos
- ✅ Gas estimado
- ❌ NÃO faz deploy real

---

## 🎯 Passo 4: Deploy Real

**ATENÇÃO:** Isso vai GASTAR ETH real!

```bash
# Deploy NA SEPOLIA
forge script script/DeployKipuBankV3Sepolia.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  -vvv

# Salvar output
```

**Output esperado:**
```
=== Deploy KipuBankV3 na Sepolia ===
Deployer: 0xYOUR_ADDRESS
...
=== Deploy Completo ===
KipuBankV3: 0xDEPLOYED_ADDRESS
```

**⚠️ COPIE O ENDEREÇO DEPLOYADO!**

---

## ✅ Passo 5: Verificar no Etherscan

```bash
# Verificar contrato (se tiver ETHERSCAN_API_KEY)
forge verify-contract \
  0xDEPLOYED_ADDRESS \
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
  --etherscan-api-key $ETHERSCAN_API_KEY

# OU manualmente em:
# https://sepolia.etherscan.io/address/0xDEPLOYED_ADDRESS#code
```

---

## 🧪 Passo 6: Testar Deployment

```bash
# Ver se está deployado
cast code 0xDEPLOYED_ADDRESS --rpc-url $SEPOLIA_RPC_URL

# Ver bank cap
cast call 0xDEPLOYED_ADDRESS \
  "bankCapUsd()(uint256)" \
  --rpc-url $SEPOLIA_RPC_URL

# Ver se USDC está suportado
cast call 0xDEPLOYED_ADDRESS \
  "tokens(address)(bool,uint256,uint8)" \
  0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238 \
  --rpc-url $SEPOLIA_RPC_URL

# Depositar 0.01 ETH (teste)
cast send 0xDEPLOYED_ADDRESS \
  --value 0.01ether \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

---

## 📊 Configurações do Deploy

**Endereços Oficiais Usados:**
- ✅ ETH/USD Feed: `0x694AA1769357215DE4FAC081bf1f309aDC325306`
- ✅ V4 PoolManager: `0xE03A1074c86CFeDd5C142C4F04F1a1536e203543`
- ✅ Permit2: `0x000000000022D473030F116dDEE9F6B43aC78BA3`
- ✅ USDC: `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238`

**Parâmetros:**
- Bank Cap: $10,000,000 USD
- Withdrawal Limit: $100,000 USD

---

## ⚠️ Troubleshooting

### Erro: "PRIVATE_KEY not found"
```bash
# Verificar se .env está carregado
source .env
echo $PRIVATE_KEY
```

### Erro: "insufficient funds"
```bash
# Verificar balance
cast balance YOUR_ADDRESS --rpc-url $SEPOLIA_RPC_URL

# Obter mais ETH Sepolia
# https://sepoliafaucet.com/
```

### Erro: "nonce too high"
```bash
# Ver nonce atual
cast nonce YOUR_ADDRESS --rpc-url $SEPOLIA_RPC_URL

# Aguardar ou resetar MetaMask
```

### Deploy demorado
```bash
# Normal! Sepolia pode levar 30-60 segundos
# Aguardar...
```

---

## 🎉 Deploy Completo!

Após deploy bem-sucedido, você terá:

✅ Contrato deployado na Sepolia  
✅ Verificado no Etherscan  
✅ Pronto para interação  
✅ Integração completa com Uniswap V4  

**Ver contrato:**
https://sepolia.etherscan.io/address/0xYOUR_DEPLOYED_ADDRESS

---

## 📚 Próximos Passos

### Configurar Pools V4

```bash
# Exemplo: Adicionar pool DAI/USDC
cast send 0xDEPLOYED_ADDRESS \
  "setPoolKey(address,address,address,uint24,int24,address)" \
  0xDAI_ADDRESS \
  0xDAI_ADDRESS \
  0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238 \
  3000 \
  60 \
  0x0000000000000000000000000000000000000000 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

### Adicionar Tokens Suportados

```bash
# Exemplo: Adicionar DAI
cast send 0xDEPLOYED_ADDRESS \
  "addToken(address,address)" \
  0xDAI_ADDRESS \
  0x14866185B1962B63C3Ea9E03Bc1da838bab34C19 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

---

**Bom deploy! 🚀**
