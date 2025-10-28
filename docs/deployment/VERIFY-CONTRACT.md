# 🔍 Verificar Contrato no Etherscan - Guia Completo

**Contrato:** `0x92EC2442Aae8d7Da9106Ec6ca2b2c1D046F7f879`  
**Network:** Sepolia Testnet

---

## 📋 Passo 1: Obter API Key do Etherscan

### 1.1 Criar Conta (se não tiver)
1. Acesse: https://etherscan.io/register
2. Complete o cadastro
3. Confirme o email

### 1.2 Gerar API Key
1. Login em: https://etherscan.io/login
2. Vá para: https://etherscan.io/myapikey
3. Clique em "Add" para criar nova API key
4. Dê um nome (ex: "KipuBank Verification")
5. **Copie a API key gerada**

**Exemplo de API key:**
```
ABC123XYZ789DEF456GHI012JKL345MNO678
```

---

## 📝 Passo 2: Configurar API Key no .env

Edite o arquivo `.env`:

```bash
# Abrir .env
nano .env
```

Adicione/atualize a linha:
```bash
ETHERSCAN_API_KEY=SUA_API_KEY_AQUI
```

**Exemplo:**
```bash
ETHERSCAN_API_KEY=ABC123XYZ789DEF456GHI012JKL345MNO678
```

Salve o arquivo (Ctrl+O, Enter, Ctrl+X).

---

## 🚀 Passo 3: Verificar o Contrato

### Método 1: Foundry (Automático) - RECOMENDADO ✅

```bash
source .env

forge verify-contract \
  0x92EC2442Aae8d7Da9106Ec6ca2b2c1D046F7f879 \
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
```

**Explicação dos Parâmetros:**
- `0x92EC...` - Endereço do contrato deployado
- `src/KipuBankV3.sol:KipuBankV3` - Caminho e nome do contrato
- `--chain sepolia` - Network (Sepolia)
- `--constructor-args` - Argumentos do constructor (IMPORTANTE!)
- `--watch` - Aguarda confirmação

---

## 🎯 Constructor Args Explicados

```solidity
constructor(
    uint256 _bankCapUsd,           // 10000000000000 = $10M (6 decimals)
    uint256 _withdrawalLimitUsd,   // 100000000000 = $100K (6 decimals)
    address _ethUsdPriceFeed,      // 0x694AA...5306 (Chainlink ETH/USD)
    address _poolManager,          // 0xE03A1...3543 (Uniswap V4)
    address _permit2,              // 0x0000...8BA3 (Permit2)
    address _usdc                  // 0x1c7D4...7238 (USDC Sepolia)
)
```

---

## ⚠️ Troubleshooting

### Erro: "Invalid API Key"

**Problema:** API key inválida ou não configurada.

**Solução:**
```bash
# Verificar se está configurada
echo $ETHERSCAN_API_KEY

# Se vazia, recarregar .env
source .env
echo $ETHERSCAN_API_KEY
```

### Erro: "Already Verified"

**Problema:** Contrato já verificado!

**Solução:** ✅ Nada a fazer, já está verificado!

Verifique em:
https://sepolia.etherscan.io/address/0x92EC2442Aae8d7Da9106Ec6ca2b2c1D046F7f879#code

### Erro: "Constructor arguments mismatch"

**Problema:** Arguments incorretos.

**Solução:** Copie exatamente os valores usados no deploy:
```bash
# Usar os valores EXATOS do DeployKipuBankV3Sepolia.s.sol:
BANK_CAP_USD = 10_000_000e6 = 10000000000000
WITHDRAWAL_LIMIT_USD = 100_000e6 = 100000000000
```

### Erro: "Compilation failed"

**Problema:** Versão do compiler diferente.

**Solução:**
```bash
# Verificar versão no foundry.toml
cat foundry.toml | grep solc

# Adicionar flag --compiler-version se necessário
forge verify-contract ... --compiler-version 0.8.26
```

---

## 🔄 Método 2: Via Interface Web (Manual)

Se o comando Foundry falhar, você pode verificar manualmente:

### 2.1 Acessar Etherscan
https://sepolia.etherscan.io/verifyContract

### 2.2 Preencher Formulário

**Compiler Type:** Solidity (Single file)  
**Compiler Version:** v0.8.26+commit.8a97fa7a  
**License:** MIT

### 2.3 Flatten o Código

```bash
# Gerar arquivo único com todas dependências
forge flatten src/KipuBankV3.sol > KipuBankV3_flattened.sol
```

### 2.4 Colar no Etherscan

1. Abra `KipuBankV3_flattened.sol`
2. Copie TODO o conteúdo
3. Cole no campo "Enter the Solidity Contract Code"

### 2.5 Constructor Arguments (ABI-encoded)

Gere os arguments:
```bash
cast abi-encode \
  "constructor(uint256,uint256,address,address,address,address)" \
  10000000000000 \
  100000000000 \
  0x694AA1769357215DE4FAC081bf1f309aDC325306 \
  0xE03A1074c86CFeDd5C142C4F04F1a1536e203543 \
  0x000000000022D473030F116dDEE9F6B43aC78BA3 \
  0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238
```

Cole o resultado no campo "Constructor Arguments".

### 2.6 Verificar

Clique em "Verify and Publish".

---

## ✅ Como Saber se Funcionou

### Checklist de Verificação

1. **Via Foundry:**
```bash
forge verify-check \
  --chain-id 11155111 \
  <GUID_DO_VERIFY>
```

2. **Via Browser:**
Acesse: https://sepolia.etherscan.io/address/0x92EC2442Aae8d7Da9106Ec6ca2b2c1D046F7f879#code

Você deve ver:
- ✅ Aba "Contract" com código-fonte
- ✅ Aba "Read Contract" funcional
- ✅ Aba "Write Contract" funcional
- ✅ Marca verde ✅ ao lado do endereço

---

## 🎁 Benefícios da Verificação

### Antes (Não Verificado) ❌
```
Contract: 0x92EC...
Bytecode: 0x6080604052...
```
- Apenas bytecode visível
- Sem interface de leitura
- Sem interface de escrita
- Difícil de auditar

### Depois (Verificado) ✅
```
Contract: KipuBankV3 ✅
Source Code: Available
Compiler: 0.8.26
License: MIT
```
- ✅ Código-fonte legível
- ✅ Interface "Read Contract"
- ✅ Interface "Write Contract"
- ✅ Fácil auditoria pública
- ✅ Mais confiança dos usuários

---

## 📖 Read Contract (Exemplo)

Após verificação, você poderá:

```
Read Contract
├── bankCapUsd() → 10000000000000
├── totalValueLockedUsd() → 4127540
├── getUserBalance(address,address) → (uint256, uint256)
├── tokens(address) → (bool, uint256, uint8)
└── ... (todas funções view)
```

---

## ✍️ Write Contract (Exemplo)

E também interagir via UI:

```
Write Contract (Connect Wallet)
├── deposit() → Send ETH
├── depositToken(address,uint256)
├── withdraw(address,uint256)
├── addToken(address,address) [Admin]
└── ... (todas funções públicas)
```

---

## 🚀 Script Helper

Criei um script para facilitar:

```bash
#!/bin/bash
# verify.sh

source .env

if [ -z "$ETHERSCAN_API_KEY" ] || [ "$ETHERSCAN_API_KEY" == "your_etherscan_key_here" ]; then
    echo "❌ Configure ETHERSCAN_API_KEY no .env primeiro!"
    echo "   Obter em: https://etherscan.io/myapikey"
    exit 1
fi

echo "🔍 Verificando contrato no Etherscan..."
echo ""

forge verify-contract \
  0x92EC2442Aae8d7Da9106Ec6ca2b2c1D046F7f879 \
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

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ VERIFICAÇÃO COMPLETA!"
    echo ""
    echo "🔗 Ver código verificado:"
    echo "   https://sepolia.etherscan.io/address/0x92EC2442Aae8d7Da9106Ec6ca2b2c1D046F7f879#code"
else
    echo ""
    echo "❌ Verificação falhou"
    echo "   Verifique os erros acima"
fi
```

Uso:
```bash
chmod +x verify.sh
./verify.sh
```

---

## 📝 Checklist Final

Antes de verificar:
- [ ] Tenho API key do Etherscan
- [ ] API key está no .env
- [ ] Contrato está deployado
- [ ] Sei os constructor args exatos
- [ ] Compilador é 0.8.26

Para verificar:
- [ ] Executar `./verify.sh` ou comando manual
- [ ] Aguardar confirmação (1-2 minutos)
- [ ] Verificar no Etherscan

Após verificação:
- [ ] Ver código-fonte no Etherscan
- [ ] Testar aba "Read Contract"
- [ ] Testar aba "Write Contract"
- [ ] Compartilhar link verificado

---

## 🎯 Links Úteis

- **Seu Contrato:** https://sepolia.etherscan.io/address/0x92EC2442Aae8d7Da9106Ec6ca2b2c1D046F7f879
- **Obter API Key:** https://etherscan.io/myapikey
- **Verificar Manualmente:** https://sepolia.etherscan.io/verifyContract
- **Foundry Docs:** https://book.getfoundry.sh/reference/forge/forge-verify-contract

---

**Boa sorte com a verificação! 🚀**
