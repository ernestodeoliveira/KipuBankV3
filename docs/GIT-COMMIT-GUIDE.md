# 📤 Guia de Commit para Git

**Projeto:** KipuBankV3 - Decentralized Bank with Uniswap V4  
**Status:** ✅ Pronto para commit

---

## ✅ Pré-Commit Checklist

- [x] ✅ Código limpo e organizado
- [x] ✅ .gitignore atualizado
- [x] ✅ .env protegido (não será commitado)
- [x] ✅ Arquivos backup removidos
- [x] ✅ Documentação organizada
- [x] ✅ Scripts em /scripts/
- [x] ✅ Contrato verificado no Etherscan

---

## 🚀 Comandos para Commit

### 1️⃣ Verificar Status

```bash
git status
```

**Esperado:** Não deve aparecer `.env` (está no .gitignore)

---

### 2️⃣ Add Arquivos

```bash
# Adicionar tudo
git add .

# OU adicionar seletivamente
git add src/
git add test/
git add script/
git add scripts/
git add docs/
git add README.md
git add DEPLOYED.md
git add FINAL-SUMMARY.md
git add foundry.toml
git add .env.example
git add .gitignore
```

---

### 3️⃣ Verificar o que será commitado

```bash
git status
```

**⚠️ CRÍTICO:** Certifique-se que `.env` NÃO aparece!

---

### 4️⃣ Commit

```bash
git commit -m "feat: KipuBankV3 with Uniswap V4 integration

- Implement multi-token banking system
- Integrate Uniswap V4 lock-callback pattern
- Add Permit2 for secure approvals
- Security hardening (9.8/10 score)
- Full Chainlink oracle integration
- Deployed and verified on Sepolia

Contract: 0x92EC2442Aae8d7Da9106Ec6ca2b2c1D046F7f879
Network: Sepolia Testnet
Status: ✅ Verified on Etherscan"
```

---

### 5️⃣ Push para Remote

```bash
# Se já tem remote configurado
git push origin main

# Se é primeiro push
git push -u origin main

# Se remote não existe, criar primeiro:
git remote add origin https://github.com/seu-usuario/seu-repo.git
git push -u origin main
```

---

## 📋 Estrutura do Repositório

```
KipuBankV3/
├── README.md                    ✅ Docs principal
├── DEPLOYED.md                  ✅ Info deployment
├── FINAL-SUMMARY.md             ✅ Resumo completo
├── .env.example                 ✅ Template config
├── .gitignore                   ✅ Git ignore rules
├── foundry.toml                 ✅ Foundry config
│
├── src/                         ✅ Contratos
│   ├── KipuBankV3.sol          ← Contrato principal
│   ├── KipuBankV3.old.sol      ← Versão anterior
│   └── ...
│
├── test/                        ✅ Testes
│   ├── KipuBankV3.t.sol        ← Testes V3
│   ├── KipuBank.t.sol          ← Testes V2
│   └── Counter.t.sol
│
├── script/                      ✅ Scripts Foundry
│   ├── DeployKipuBankV3Sepolia.s.sol
│   └── ...
│
├── scripts/                     ✅ Utilitários
│   ├── deploy.sh
│   ├── verify.sh
│   ├── test-deployed.sh
│   └── ...
│
├── docs/                        ✅ Documentação
│   ├── deployment/
│   ├── testing/
│   ├── archive/
│   └── *.md
│
└── lib/                         ✅ Dependencies
    ├── forge-std/
    ├── openzeppelin-contracts/
    ├── v4-core/
    └── ...
```

---

## 🔒 Arquivos que NÃO serão commitados

Protegidos pelo `.gitignore`:

```
.env                    ← CRÍTICO! Contém private keys
.env.bak
.env.*                  (exceto .env.example)
*.bak
*.backup
.DS_Store
cache/
out/
broadcast/*/31337/     (local deployments)
node_modules/
coverage/
```

---

## ⚠️ VERIFICAÇÃO DE SEGURANÇA

Antes de fazer push, execute:

```bash
# Verificar que .env não está sendo commitado
git status | grep .env

# Deve mostrar apenas:
# .env.example

# Se mostrar .env (sem .example), PARE!
git reset HEAD .env
```

---

## 📊 Informações do Contrato (para README)

```markdown
## 🚀 Deployed Contract

**Network:** Sepolia Testnet  
**Contract:** 0x92EC2442Aae8d7Da9106Ec6ca2b2c1D046F7f879  
**Verified:** ✅ https://sepolia.etherscan.io/address/0x92EC2442Aae8d7Da9106Ec6ca2b2c1D046F7f879#code

### Features
- ✅ Multi-token support (ETH, USDC, LINK, DAI, WBTC, WETH)
- ✅ Uniswap V4 integration (lock-callback pattern)
- ✅ Permit2 secure approvals
- ✅ Chainlink price feeds
- ✅ Security score: 9.8/10

### Deployment Details
- Block: 9,510,423
- Gas Used: 2,891,498
- Deployer: 0x015Af42bc6a81C5214ae512D6131acb17BF06981
- Date: October 28, 2025
```

---

## 🎯 Próximos Passos Após Commit

### 1. Criar Release Tag
```bash
git tag -a v3.0.0 -m "KipuBankV3 - Production Ready
- Uniswap V4 integration
- Deployed on Sepolia
- Verified on Etherscan"

git push origin v3.0.0
```

### 2. Adicionar Badge ao README

```markdown
![Solidity](https://img.shields.io/badge/Solidity-0.8.26-363636?logo=solidity)
![Network](https://img.shields.io/badge/Network-Sepolia-blue)
![Status](https://img.shields.io/badge/Status-Deployed-success)
![Verified](https://img.shields.io/badge/Verified-Etherscan-green)
```

### 3. Criar GitHub Release

No GitHub:
1. Vá para "Releases"
2. "Create a new release"
3. Tag: v3.0.0
4. Title: "KipuBankV3 - Production Ready"
5. Description: Cole informações do DEPLOYED.md

---

## 📝 Commit Message Template

Para commits futuros:

```bash
# Feature
git commit -m "feat: descrição"

# Bug fix
git commit -m "fix: descrição"

# Documentation
git commit -m "docs: descrição"

# Refactor
git commit -m "refactor: descrição"

# Test
git commit -m "test: descrição"
```

---

## ✅ Checklist Final

Antes de fazer push público:

- [ ] `.env` não está sendo commitado
- [ ] Não há API keys no código
- [ ] Não há private keys no código
- [ ] README.md está atualizado
- [ ] Documentação está completa
- [ ] Testes estão incluídos
- [ ] Scripts estão documentados
- [ ] License file existe (MIT)
- [ ] .gitignore está completo

---

## 🔗 Links Úteis

- **Contrato Deployado:** https://sepolia.etherscan.io/address/0x92EC2442Aae8d7Da9106Ec6ca2b2c1D046F7f879
- **Uniswap V4 Docs:** https://docs.uniswap.org/contracts/v4/overview
- **Foundry Book:** https://book.getfoundry.sh/

---

**Pronto para commit! 🚀**

Execute os comandos na seção "Comandos para Commit" acima.
