# 🔑 Obter API Key do Etherscan - Guia Rápido

**Tempo:** 2 minutos ⏱️

---

## 📋 Passo a Passo Visual

### 1️⃣ Página Aberta: https://etherscan.io/myapikey

Você deve ver uma página assim:

```
╔════════════════════════════════════════╗
║  Etherscan - My API Keys               ║
╠════════════════════════════════════════╣
║                                        ║
║  [+] Add                               ║
║                                        ║
║  My API Keys:                          ║
║  (lista vazia se é primeira vez)       ║
║                                        ║
╚════════════════════════════════════════╝
```

---

### 2️⃣ Se NÃO Estiver Logado

Você verá:
```
Please Sign In or Register
```

**Ação:** 
- Clique em "Register" (primeira vez)
- OU "Sign In" (se já tem conta)

---

### 3️⃣ Após Login

Clique no botão **"Add"** (canto superior)

---

### 4️⃣ Formulário de Criação

Você verá:
```
╔════════════════════════════════════════╗
║  Create New API Key                    ║
╠════════════════════════════════════════╣
║  AppName: [___________________]        ║
║           (ex: KipuBank Verify)        ║
║                                        ║
║  [Continue]                            ║
╚════════════════════════════════════════╝
```

**Ação:**
1. Digite um nome: **"KipuBank Verification"**
2. Clique em **"Continue"**

---

### 5️⃣ API Key Gerada! 🎉

Você verá algo assim:
```
╔════════════════════════════════════════╗
║  Your API Key:                         ║
║                                        ║
║  ABC123XYZ789DEF456GHI012JKL345MNO678  ║
║                                        ║
║  [Copy]                                ║
╚════════════════════════════════════════╝
```

**Ação:**
1. Clique em **"Copy"** (ou copie manualmente)
2. **GUARDE essa key!**

---

## 💾 Adicionar ao .env

### Opção 1: Script Automático (RECOMENDADO) ✅

```bash
./setup-verify.sh
```

Quando perguntado, cole a API key que você copiou.

---

### Opção 2: Manual

```bash
# Abrir .env
nano .env

# Adicionar ou substituir a linha:
ETHERSCAN_API_KEY=ABC123XYZ789DEF456GHI012JKL345MNO678

# Salvar: Ctrl+O, Enter, Ctrl+X
```

---

## ✅ Verificar se Funcionou

```bash
# Testar
source .env
echo $ETHERSCAN_API_KEY

# Deve mostrar sua key
```

---

## 🚀 Verificar o Contrato

Após configurar:

```bash
./verify.sh
```

Ou use o setup completo:

```bash
./setup-verify.sh
```

---

## 💡 Dicas

### ✅ É Gratuito!
- API key do Etherscan é 100% grátis
- Não precisa cartão de crédito
- Ilimitado para uso normal

### 🔒 Segurança
- **NUNCA** compartilhe sua API key
- **NÃO** commite o `.env` no git
- Pode revogar e criar nova a qualquer momento

### ⚡ Limites
- Rate limit: 5 requests/segundo (mais que suficiente)
- Para projetos pessoais, API key gratuita é perfeita

---

## ❓ Troubleshooting

### "Por que preciso de uma conta?"
Para evitar abuso, Etherscan requer identificação.

### "Esqueci minha API key"
1. Acesse: https://etherscan.io/myapikey
2. Veja suas keys existentes
3. Ou crie uma nova

### "Posso ter múltiplas keys?"
Sim! Útil para diferentes projetos.

---

## 🔗 Links Úteis

- **Obter API Key:** https://etherscan.io/myapikey
- **Documentação:** https://docs.etherscan.io/
- **Criar Conta:** https://etherscan.io/register

---

**Próximo Passo:** Executar `./setup-verify.sh` 🚀
