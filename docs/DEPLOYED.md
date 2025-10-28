# 🎉 KipuBankV3 - Deployado com Sucesso!

**Data:** 28 de Outubro, 2025  
**Network:** Sepolia Testnet

---

## 📍 Endereço do Contrato

```
0x92EC2442Aae8d7Da9106Ec6ca2b2c1D046F7f879
```

**🔗 Links:**
- **Etherscan:** https://sepolia.etherscan.io/address/0x92EC2442Aae8d7Da9106Ec6ca2b2c1D046F7f879
- **Transaction:** https://sepolia.etherscan.io/tx/0x4b570c36c4dd5a837c620ed6eab7888548c12c0a6f82d2268eda797f6258fe9e

---

## ✅ Configuração Verificada

| Parâmetro | Valor | Status |
|-----------|-------|--------|
| **Bank Cap** | $10,000,000 USD | ✅ |
| **Withdrawal Limit** | $100,000 USD | ✅ |
| **USDC Suportado** | true (6 decimals) | ✅ |
| **PoolManager** | `0xE03A1074c86CFeDd5C142C4F04F1a1536e203543` | ✅ |
| **Permit2** | `0x000000000022D473030F116dDEE9F6B43aC78BA3` | ✅ |
| **ETH/USD Feed** | `0x694AA1769357215DE4FAC081bf1f309aDC325306` | ✅ |

---

## 📊 Detalhes do Deploy

- **Deployer:** `0x015Af42bc6a81C5214ae512D6131acb17BF06981`
- **Block:** 9,510,423
- **Gas Usado:** 2,891,498 (0.00289 ETH)
- **Gas Price:** 1.00002 gwei
- **Timestamp:** Block timestamp

---

## 🧪 Testes Básicos

### Ver Configuração

```bash
# Bank Cap
cast call 0x92EC2442Aae8d7Da9106Ec6ca2b2c1D046F7f879 \
  "bankCapUsd()(uint256)" \
  --rpc-url $SEPOLIA_RPC_URL

# Withdrawal Limit
cast call 0x92EC2442Aae8d7Da9106Ec6ca2b2c1D046F7f879 \
  "WITHDRAWAL_LIMIT_USD()(uint256)" \
  --rpc-url $SEPOLIA_RPC_URL

# Verificar se USDC está suportado
cast call 0x92EC2442Aae8d7Da9106Ec6ca2b2c1D046F7f879 \
  "tokens(address)(bool,uint256,uint8)" \
  0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238 \
  --rpc-url $SEPOLIA_RPC_URL
```

### Depositar ETH (Teste)

```bash
# Depositar 0.01 ETH
cast send 0x92EC2442Aae8d7Da9106Ec6ca2b2c1D046F7f879 \
  --value 0.01ether \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Ver seu saldo
cast call 0x92EC2442Aae8d7Da9106Ec6ca2b2c1D046F7f879 \
  "getUserBalance(address,address)(uint256,uint256)" \
  0x015Af42bc6a81C5214ae512D6131acb17BF06981 \
  0x0000000000000000000000000000000000000000 \
  --rpc-url $SEPOLIA_RPC_URL
```

---

## 🔧 Próximos Passos

### 1. Adicionar Mais Tokens

```bash
# Exemplo: Adicionar DAI
cast send 0x92EC2442Aae8d7Da9106Ec6ca2b2c1D046F7f879 \
  "addToken(address,address)" \
  0xDAI_ADDRESS_SEPOLIA \
  0x14866185B1962B63C3Ea9E03Bc1da838bab34C19 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

### 2. Configurar Pools V4

```bash
# Exemplo: Configurar pool DAI/USDC
cast send 0x92EC2442Aae8d7Da9106Ec6ca2b2c1D046F7f879 \
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

### 3. Testar depositArbitraryToken

Uma vez que pools estejam configurados, você pode depositar qualquer token que será automaticamente trocado por USDC via Uniswap V4.

---

## 📚 Documentação

- **README:** `README.md` - Documentação completa V3
- **Deploy Guide:** `DEPLOY-SEPOLIA.md` - Guia de deployment
- **V4 Addresses:** `V4-TESTNET-ADDRESSES.md` - Endereços oficiais
- **Chainlink Guide:** `CHAINLINK-FEEDS-GUIDE.md` - Guia de price feeds

---

## 🔒 Segurança

**Contrato Auditado:** Não (desenvolvimento/testnet)  
**Security Score:** 9.8/10 (conforme README)

**Recursos de Segurança:**
- ✅ ReentrancyGuard em todas funções públicas
- ✅ CEI pattern implementado
- ✅ Oracle validation (5 checks)
- ✅ Access control (ADMIN_ROLE, EMERGENCY_ROLE)
- ✅ Pause mechanism
- ✅ USDT compatibility (forceApprove)

---

## 📞 Suporte

**Issues:** Abra uma issue no repositório  
**Docs:** Ver arquivos markdown no projeto

---

## ✅ Checklist Pós-Deploy

- [x] Contrato deployado
- [x] Configuração verificada
- [x] USDC suportado
- [x] PoolManager conectado
- [x] Chainlink feeds ativos
- [ ] Tokens adicionais configurados
- [ ] Pools V4 configurados
- [ ] Primeiro deposit de teste
- [ ] Verificação no Etherscan (opcional)

---

**Status:** ✅ **PRONTO PARA USO!**

**Atenção:** Este é um ambiente de testnet. Não use em produção sem auditoria completa.
