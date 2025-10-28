# 🚀 Deploy KipuBankV3 na Sepolia - Guia Completo

## ✅ ÓTIMA NOTÍCIA!

**Uniswap V4 ESTÁ deployado oficialmente na Sepolia!**

Endereços oficiais disponíveis e prontos para uso.

---

## 📋 Checklist de Requisitos

### ✅ Endereços Disponíveis (Sepolia)

| Componente | Endereço | Status |
|------------|----------|--------|
| **Chainlink ETH/USD** | `0x694AA1769357215DE4FAC081bf1f309aDC325306` | ✅ Disponível |
| **Permit2** | `0x000000000022D473030F116dDEE9F6B43aC78BA3` | ✅ Disponível |
| **USDC** | `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238` | ✅ Disponível |
| **V4 PoolManager** | `0xE03A1074c86CFeDd5C142C4F04F1a1536e203543` | ✅ Disponível |
| **V4 UniversalRouter** | `0x3A9D48AB9751398BbFa63ad67599Bb04e4BdF98b` | ✅ Disponível |

---

## 🔧 Setup Inicial

### 1. Criar arquivo `.env`

```bash
# Na raiz do projeto
cat > .env << 'EOF'
# Sepolia RPC
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_ALCHEMY_KEY

# Private key da wallet (SEM 0x no início)
PRIVATE_KEY=sua_private_key_aqui

# Etherscan API key (para verificação)
ETHERSCAN_API_KEY=sua_etherscan_key_aqui
EOF
```

### 2. Obter ETH Sepolia

**Faucets gratuitos:**
- https://sepoliafaucet.com/
- https://www.alchemy.com/faucets/ethereum-sepolia
- https://sepolia-faucet.pk910.de/

**Quantidade necessária:** ~0.1 ETH Sepolia

---

## 🚀 Deploy na Sepolia

### Deploy Direto (Production-Like)

```bash
# Deploy KipuBankV3 com endereços oficiais V4
forge script script/DeployKipuBankV3Sepolia.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  -vvvv
```

**O script já está configurado com todos os endereços oficiais!**

### Alternativa: Teste Local Primeiro (Anvil Fork)

```bash
# Terminal 1: Fork da Sepolia
anvil --fork-url $SEPOLIA_RPC_URL --chain-id 11155111

# Terminal 2: Deploy no fork
forge script script/DeployKipuBankV3Sepolia.s.sol \
  --rpc-url http://127.0.0.1:8545 \
  --broadcast
```

---

## 📝 Após Deploy

### 1. Verificar no Etherscan

```bash
forge verify-contract \
  SEU_ENDERECO_KIPUBANK \
  src/KipuBankV3.sol:KipuBankV3 \
  --chain sepolia \
  --constructor-args $(cast abi-encode \
    "constructor(uint256,uint256,address,address,address,address)" \
    10000000000000 \
    100000000000 \
    0x694AA1769357215DE4FAC081bf1f309aDC325306 \
    0xSEU_POOL_MANAGER \
    0x000000000022D473030F116dDEE9F6B43aC78BA3 \
    0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238)
```

### 2. Adicionar tokens suportados

```bash
# Conecte sua wallet e execute:
cast send SEU_ENDERECO_KIPUBANK \
  "addToken(address,address)" \
  TOKEN_ADDRESS \
  PRICE_FEED_ADDRESS \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

### 3. Configurar PoolKeys (se usando mock)

```bash
cast send SEU_ENDERECO_KIPUBANK \
  "setPoolKey(address,address,address,uint24,int24,address)" \
  TOKEN_ADDRESS \
  CURRENCY0 \
  CURRENCY1 \
  3000 \
  60 \
  0x0000000000000000000000000000000000000000 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

---

## 🔍 Verificação Pós-Deploy

### Checklist:

```bash
# 1. Verificar se deployou
cast code SEU_ENDERECO_KIPUBANK --rpc-url $SEPOLIA_RPC_URL

# 2. Verificar configurações
cast call SEU_ENDERECO_KIPUBANK "bankCapUsd()(uint256)" --rpc-url $SEPOLIA_RPC_URL

# 3. Verificar roles
cast call SEU_ENDERECO_KIPUBANK \
  "hasRole(bytes32,address)(bool)" \
  0x0000000000000000000000000000000000000000000000000000000000000000 \
  SEU_ENDERECO \
  --rpc-url $SEPOLIA_RPC_URL

# 4. Verificar se paused
cast call SEU_ENDERECO_KIPUBANK "paused()(bool)" --rpc-url $SEPOLIA_RPC_URL
```

---

## ✅ Funcionalidades Disponíveis

**Com V4 Oficial na Sepolia, TUDO funciona:**
- ✅ Swaps reais via `depositArbitraryToken()`
- ✅ Callbacks de unlock
- ✅ Integração completa com pools V4
- ✅ Deposits ETH e tokens suportados
- ✅ Withdrawals
- ✅ Admin functions
- ✅ Permit2 approvals

---

## 🎯 Para Produção Real

**Você precisará:**

1. **Mainnet Ethereum** (V4 está sendo rolled out)
2. **PoolManager oficial V4** deployado
3. **Auditoria de segurança** completa
4. **Testes extensivos** (unit + integration)
5. **Multisig** para admin roles
6. **Timelock** para mudanças críticas

---

## 📚 Recursos Úteis

**Sepolia:**
- Explorer: https://sepolia.etherscan.io/
- Faucet: https://sepoliafaucet.com/
- RPC: https://chainlist.org/chain/11155111

**Chainlink (Sepolia):**
- Docs: https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum&page=1#sepolia-testnet
- ETH/USD: 0x694AA1769357215DE4FAC081bf1f309aDC325306

**Uniswap:**
- V4 Docs: https://docs.uniswap.org/contracts/v4/overview
- GitHub: https://github.com/Uniswap/v4-core

---

## 🚨 Troubleshooting

### Erro: "POOL_MANAGER nao configurado!"
**Solução:** Edite `DeployKipuBankV3Sepolia.s.sol` linha 14 com endereço válido

### Erro: "insufficient funds"
**Solução:** Obtenha mais ETH Sepolia dos faucets

### Erro: "nonce too low"
**Solução:** 
```bash
cast nonce SEU_ENDERECO --rpc-url $SEPOLIA_RPC_URL
```

### Erro na verificação
**Solução:** 
```bash
# Use --force para re-verificar
forge verify-contract ... --force
```

---

**Status:** ✅ **PRONTO para deploy REAL na Sepolia**

**Recomendação:** Deploy direto na Sepolia para testes com V4 real e funcional!
