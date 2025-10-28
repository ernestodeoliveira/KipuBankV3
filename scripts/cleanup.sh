#!/bin/bash
# Limpeza de arquivos desnecessários

echo "🧹 Limpando projeto para Git..."
echo ""

# Remover backups
echo "📦 Removendo arquivos backup..."
rm -f .env.bak .env.backup *.bak *.backup 2>/dev/null
rm -f debug-*.txt 2>/dev/null

# Remover arquivos OS
echo "🖥️  Removendo arquivos do sistema..."
find . -name ".DS_Store" -delete 2>/dev/null
find . -name "._*" -delete 2>/dev/null

# Organizar documentação duplicada
echo "📚 Organizando documentação..."
mkdir -p docs/archive 2>/dev/null

# Mover documentação antiga/duplicada para archive
mv -f README-V2-backup.md docs/archive/ 2>/dev/null
mv -f README-V3-HONEST.md docs/archive/ 2>/dev/null  
mv -f README-V3-OFFICIAL-PATTERN.md docs/archive/ 2>/dev/null
mv -f FINAL-IMPLEMENTATION-SUMMARY.md docs/archive/ 2>/dev/null
mv -f FINAL-IMPLEMENTATION.md docs/archive/ 2>/dev/null
mv -f IMPLEMENTATION_SUMMARY.md docs/archive/ 2>/dev/null
mv -f IMPLEMENTATION-VS-DOCS.md docs/archive/ 2>/dev/null
mv -f FIXES-NEEDED.md docs/archive/ 2>/dev/null
mv -f TEST-STATUS.md docs/archive/ 2>/dev/null

# Manter apenas docs essenciais na raiz
echo "✅ Mantendo documentação essencial na raiz:"
echo "   - README.md (principal)"
echo "   - DEPLOYED.md (info do deploy)"
echo "   - FINAL-SUMMARY.md (resumo final)"
echo "   - VERIFY-CONTRACT.md (guia de verificação)"
echo "   - V4-TESTNET-ADDRESSES.md (endereços)"

# Mover scripts de teste para pasta scripts
mkdir -p scripts 2>/dev/null
mv -f test-deployed.sh scripts/ 2>/dev/null
mv -f test-advanced.sh scripts/ 2>/dev/null
mv -f test-multi-tokens.sh scripts/ 2>/dev/null
mv -f get-weth.sh scripts/ 2>/dev/null
mv -f deploy.sh scripts/ 2>/dev/null
mv -f verify.sh scripts/ 2>/dev/null
mv -f setup-verify.sh scripts/ 2>/dev/null

echo ""
echo "✅ Limpeza completa!"
echo ""
echo "📁 Estrutura final:"
echo "   /src         - Código fonte"
echo "   /test        - Testes"
echo "   /script      - Scripts Foundry"
echo "   /scripts     - Scripts utilitários"
echo "   /docs        - Documentação"
echo "   /*.md        - Docs essenciais"
echo ""
