# 📊 Guia Completo: Chainlink Price Feeds

## 🎯 Conceito Fundamental

**NÃO existe feed ETH/USDC direto!**

Chainlink fornece feeds **TOKEN/USD**, não pares entre tokens.

---

## ✅ Como Funciona (Arquitetura Correta)

### Sistema de Conversão

```
┌──────────────────────────────────────┐
│   Qualquer Token → USD (Chainlink)   │
└──────────────────────────────────────┘
              ↓
┌──────────────────────────────────────┐
│    Todas conversões via USD base     │
└──────────────────────────────────────┘
```

### Exemplo Prático

**Pergunta:** "Quanto vale 1 ETH em USDC?"

**Processo:**
1. ✅ ETH/USD feed → $2000
2. ✅ USDC/USD feed → $1
3. ✅ Cálculo: 2000 / 1 = 2000 USDC

**Código:**
```solidity
// No contrato:
uint256 ethValueUsd = _getTokenValueInUsd(NATIVE_ETH, 1 ether);  // $2000
uint256 usdcValueUsd = _getTokenValueInUsd(USDC, 1e6);           // $1
// ETH em USDC = ethValueUsd / usdcValueUsd = 2000 USDC
```

---

## 📍 Endereços Oficiais

### Sepolia Testnet

```solidity
// Todos são TOKEN/USD feeds (8 decimals)
address constant ETH_USD  = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
address constant BTC_USD  = 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43;
address constant USDC_USD = 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E;
address constant DAI_USD  = 0x14866185B1962B63C3Ea9E03Bc1da838bab34C19;
address constant LINK_USD = 0xc59E3633BAAC79493d908e63626716e204A45EdF;
address constant USDT_USD = 0x4ec9ce55A72BF37b1597cebA2CB07E88D90f7F89;
```

**Fonte Oficial:**  
https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum&page=1#sepolia-testnet

### Mainnet Ethereum

```solidity
address constant ETH_USD  = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
address constant BTC_USD  = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c;
address constant USDC_USD = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
address constant DAI_USD  = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;
```

---

## 🔧 Configuração no Contrato

### 1. Constructor (ETH Feed)

```solidity
constructor(
    uint256 _bankCapUsd,
    uint256 _withdrawalLimitUsd,
    address _ethUsdPriceFeed,  // ✅ ETH/USD (NÃO ETH/USDC!)
    address _poolManager,
    address _permit2,
    address _usdc
) {
    // Armazena feed ETH/USD
    ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
    
    // ETH usa este feed
    priceFeeds[NATIVE_ETH] = ethUsdPriceFeed;
    
    // USDC não precisa feed (assume $1 ou usa feed USDC/USD)
    tokens[_usdc] = TokenInfo(true, 0, 6);
}
```

### 2. Adicionar Outros Tokens

```solidity
// Adicionar DAI com feed DAI/USD
bank.addToken(
    0xDAI_ADDRESS,
    0x14866185B1962B63C3Ea9E03Bc1da838bab34C19  // DAI/USD feed
);

// Adicionar WBTC com feed BTC/USD
bank.addToken(
    0xWBTC_ADDRESS,
    0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43  // BTC/USD feed
);
```

---

## 🧪 Testes

### Opção 1: Mocks (Testes Unitários)

**Arquivo:** `test/KipuBankV3.t.sol` (já criado)

```solidity
// Mock feeds (valores fixos para testes)
ethUsdPriceFeed = new MockV3Aggregator(8, int256(2000e8));   // $2000
usdcUsdPriceFeed = new MockV3Aggregator(8, int256(1e8));     // $1
daiUsdPriceFeed = new MockV3Aggregator(8, int256(1e8));      // $1
```

**Vantagens:**
- ✅ Rápido
- ✅ Previsível
- ✅ Sem dependência de rede

### Opção 2: Feeds Reais (Integration Tests)

**Arquivo:** `test/KipuBankV3.integration.t.sol` (recém criado)

**Rodar com fork da Sepolia:**
```bash
# Terminal 1: Fork
anvil --fork-url $SEPOLIA_RPC_URL

# Terminal 2: Testes
forge test --match-contract KipuBankV3IntegrationTest --rpc-url http://127.0.0.1:8545 -vv
```

**Vantagens:**
- ✅ Usa preços reais
- ✅ Valida integração completa
- ✅ Detecta problemas com feeds

---

## 🔍 Como Verificar se Está Funcionando

### 1. Ver Preço do ETH

```bash
# Via cast (Sepolia)
cast call 0x694AA1769357215DE4FAC081bf1f309aDC325306 \
  "latestRoundData()(uint80,int256,uint256,uint256,uint80)" \
  --rpc-url $SEPOLIA_RPC_URL

# Output esperado:
# roundId, price (e.g., 200000000000 = $2000), startedAt, updatedAt, answeredInRound
```

### 2. No Contrato Deployado

```bash
# Get ETH price
cast call YOUR_BANK_ADDRESS \
  "getEthPrice()(uint256)" \
  --rpc-url $SEPOLIA_RPC_URL

# Convert 1 ETH to USD
cast call YOUR_BANK_ADDRESS \
  "convertToUsd(address,uint256)(uint256)" \
  0x0000000000000000000000000000000000000000 \
  1000000000000000000 \
  --rpc-url $SEPOLIA_RPC_URL
```

### 3. Em Testes

```solidity
function testEthPrice() public view {
    uint256 price = bank.getEthPrice();
    console.log("ETH/USD:", price); // 8 decimals
    
    // Validar range razoável
    assertGt(price, 500e8, "ETH too cheap");
    assertLt(price, 10_000e8, "ETH too expensive");
}
```

---

## ⚠️ Problemas Comuns

### ❌ Erro: "Tentando usar ETH/USDC feed"

**Problema:**
```solidity
// ❌ ERRADO
address ethUsdcFeed = 0x...;  // Não existe!
```

**Solução:**
```solidity
// ✅ CORRETO
address ethUsdFeed = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
address usdcUsdFeed = 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E;
// Cálculo: ETH/USDC = (ETH/USD) / (USDC/USD)
```

### ❌ Erro: "Stale Price"

**Problema:**
```solidity
Error: StalePriceFeed()
```

**Causa:** Preço mais antigo que 1 hora (PRICE_FEED_STALENESS_THRESHOLD)

**Solução:**
```solidity
// Em testes com mock:
vm.warp(block.timestamp); // Reset timestamp

// Em produção: Usar feed ativo
// Chainlink atualiza regularmente (geralmente < 1 hour)
```

### ❌ Erro: "Invalid Price Feed"

**Problema:**
```solidity
Error: InvalidPriceFeed()
```

**Causas Possíveis:**
1. Endereço do feed errado
2. Price <= 0
3. updatedAt == 0
4. answeredInRound < roundId

**Solução:**
```bash
# Verificar feed está ativo
cast call FEED_ADDRESS \
  "latestRoundData()(uint80,int256,uint256,uint256,uint80)" \
  --rpc-url $SEPOLIA_RPC_URL
```

---

## 📊 Exemplo Completo: Deploy com Feeds

```bash
# 1. Set environment
export ETH_USD_FEED=0x694AA1769357215DE4FAC081bf1f309aDC325306
export POOL_MANAGER=0xE03A1074c86CFeDd5C142C4F04F1a1536e203543
export PERMIT2=0x000000000022D473030F116dDEE9F6B43aC78BA3
export USDC=0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238

# 2. Deploy
forge script script/DeployKipuBankV3Sepolia.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify

# 3. Verificar preço
cast call DEPLOYED_ADDRESS "getEthPrice()(uint256)" --rpc-url $SEPOLIA_RPC_URL
```

---

## 📚 Recursos

**Chainlink Docs:**
- Price Feeds: https://docs.chain.link/data-feeds/price-feeds
- Sepolia Addresses: https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum&page=1#sepolia-testnet
- Using Data Feeds: https://docs.chain.link/data-feeds/using-data-feeds

**Seu Projeto:**
- Contrato: `src/KipuBankV3.sol` linhas 592-618 (`_getTokenValueInUsd`)
- Testes Mock: `test/KipuBankV3.t.sol`
- Testes Integration: `test/KipuBankV3.integration.t.sol`
- Endereços V4: `V4-TESTNET-ADDRESSES.md`

---

## ✅ Checklist

- [x] Entendo que não existe feed ETH/USDC direto
- [x] Uso feeds TOKEN/USD para todas conversões
- [x] Tenho endereços oficiais Sepolia
- [x] Testes com mocks funcionam
- [x] Sei como testar com feeds reais (fork)
- [x] Sei verificar se feed está ativo

---

**Última Atualização:** 28 de Outubro, 2025
