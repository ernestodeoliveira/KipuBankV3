# 🔧 Fixes Necessários para 100% Test Pass

**Status Atual:** 13/20 passing (65%)  
**Target:** 20/20 passing (100%)  
**Gap:** 7 testes a corrigir

---

## 📋 Análise dos 7 Testes Falhando

### 1. ❌ `testWithdrawETH()` - InsufficientBalance(500000, 0)

**Erro:**
```
Error: InsufficientBalance(500000, 0)
Expected: 500000 (0.5 ETH normalizado)
Actual: 0
```

**Root Cause:**
Deposit de 1 ETH não está sendo creditado corretamente. Balance permanece 0.

**Problema no Código:**
```solidity
// src/KipuBankV3.sol linha ~546
function _deposit(address token, uint256 amount) internal {
    // ...
    uint256 normalized = _normalizeDecimals(amount, tokens[token].decimals, TARGET_DECIMALS);
    // ...
    userDeposits[msg.sender][token].amount += normalized; // ← Isso não está funcionando
}
```

**Root Cause Possível:**
- `_normalizeDecimals()` pode estar retornando valor errado
- Ou `tokens[token].decimals` não está setado corretamente para NATIVE_ETH

**Fix Necessário:**
```solidity
// Investigar _normalizeDecimals para NATIVE_ETH:
// Input: 1 ether = 1e18, from 18 decimals, to 6 decimals
// Expected output: 1e6 (1 USDC equivalente)
// 
// Cálculo: 1e18 / 1e12 = 1e6 ✅

// Verificar se tokens[NATIVE_ETH].decimals = 18 está setado no constructor
```

**Teste para Validar Fix:**
```solidity
function testDecimalNormalizationETH() public view {
    uint256 normalized = bank._normalizeDecimals(1 ether, 18, 6);
    assertEq(normalized, 1e6, "Should normalize 1 ETH to 1e6");
}
```

---

### 2. ❌ `testDepositUSDC()` - EvmError: Revert

**Erro:**
```
EvmError: Revert (sem mensagem específica)
```

**Root Cause Provável:**
1. USDC não está marcado como suportado após constructor
2. Ou approve/transferFrom está falhando

**Investigação Necessária:**
```solidity
// Verificar se USDC está supported:
(bool isSupported,,) = bank.tokens(address(usdc));
// Deve ser true

// Verificar se addToken foi chamado para USDC
// Ou se constructor já adiciona
```

**Fix Provável:**
O constructor adiciona USDC mas NÃO marca como supported:
```solidity
// Constructor linha 172:
tokens[_usdc] = TokenInfo(true, 0, 6); // ✅ Isso deveria marcar como supported

// MAS: Pode ter issue se addToken() for chamado novamente
// addToken() tem check: if (tokens[token].isSupported) revert TokenAlreadySupported
```

**Teste Debug:**
```solidity
function testUSDCIsSupported() public view {
    (bool isSupported, uint256 totalDeposits, uint8 decimals) = bank.tokens(address(usdc));
    assertTrue(isSupported, "USDC should be supported");
    assertEq(decimals, 6, "USDC decimals should be 6");
}
```

---

### 3. ❌ `testDepositRevertsWhenPaused()` - Should revert when paused

**Erro:**
```
Assertion failed: Should revert when paused
Expected: Revert
Actual: Success
```

**Root Cause:**
`receive()` não tem modifier `whenNotPaused` aplicado corretamente.

**Código Atual:**
```solidity
// linha 179-181
receive() external payable whenNotPaused nonReentrant {
    _deposit(NATIVE_ETH, msg.value);
}
```

**Problema:**
O modifier `whenNotPaused` ESTÁ aplicado, mas o teste pode estar errado.

**Fix no Teste:**
```solidity
function testDepositRevertsWhenPaused() public {
    vm.prank(admin);
    bank.setPaused(true);
    
    vm.prank(user1);
    vm.expectRevert(KipuBankV3.ContractPaused.selector);
    // ❌ PROBLEMA: call{value} não propaga revert selector corretamente
    (bool success,) = address(bank).call{value: 1 ether}("");
    
    // Fix: Usar alta-level call
    // bank.receive(); // Não funciona, receive não pode ser chamado diretamente
}
```

**Solução Real:**
Testar expectRevert ANTES do call:
```solidity
function testDepositRevertsWhenPaused() public {
    vm.prank(admin);
    bank.setPaused(true);
    
    vm.prank(user1);
    vm.expectRevert(KipuBankV3.ContractPaused.selector);
    payable(address(bank)).transfer(1 ether); // ✅ Usa transfer ao invés de call
}
```

---

### 4. ❌ `testCEIPatternInDeposit()` - EvmError: Revert

**Erro:**
Mesmo que #2 - deposit de USDC falhando

**Fix:**
Corrigir #2 primeiro

---

### 5. ❌ `testWithdrawUSDC()` - EvmError: Revert

**Erro:**
Dependency de #2 - precisa depositar USDC primeiro

**Fix:**
Corrigir #2 primeiro

---

### 6. ❌ `testGetUserBalanceUsd()` - EvmError: Revert

**Erro:**
Dependency de #2 - precisa depositar USDC primeiro

**Fix:**
Corrigir #2 primeiro

---

### 7. ❌ `testOracleValidation()` - Should revert

**Erro:**
```
Expected: StalePriceFeed revert
Actual: Success
```

**Root Cause:**
Mock oracle não respeita `vm.warp()` para simular staleness.

**Código do Teste:**
```solidity
function testOracleValidation() public {
    vm.warp(block.timestamp + 2 hours); // ← Mock não usa isso
    
    vm.prank(user1);
    vm.expectRevert(KipuBankV3.StalePriceFeed.selector);
    (bool success,) = address(bank).call{value: 1 ether}("");
}
```

**Problema:**
MockV3Aggregator atualiza `latestTimestamp = block.timestamp` toda vez que updateAnswer() é chamado, mas não no latestRoundData().

**Fix no Mock:**
```solidity
// test/KipuBankV3.t.sol linha ~54
contract MockV3Aggregator {
    // ...
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (
            uint80(latestRound),
            latestAnswer,
            latestTimestamp,      // ✅ Usa timestamp armazenado
            latestTimestamp,      // ✅ Deve ser o mesmo
            uint80(latestRound)
        );
    }
}
```

**O Mock JÁ ESTÁ CORRETO!**

**Problema Real:**
Mock é criado no setUp() que roda ANTES de cada teste.
Quando `vm.warp()` é chamado, `block.timestamp` muda, mas `latestTimestamp` do mock ainda é o antigo.

**Fix no Teste:**
```solidity
function testOracleValidation() public {
    // Criar deposit velho primeiro
    vm.prank(user1);
    (bool success1,) = address(bank).call{value: 1 ether}("");
    require(success1);
    
    // Agora warp 2 horas
    vm.warp(block.timestamp + 2 hours);
    
    // Próximo deposit deve falhar (oracle stale)
    vm.prank(user1);
    vm.expectRevert(KipuBankV3.StalePriceFeed.selector);
    (bool success2,) = address(bank).call{value: 1 ether}("");
    assertFalse(success2);
}
```

**OU melhor:**
Atualizar o mock para simular staleness:
```solidity
function testOracleValidation() public {
    // Force mock to be stale
    vm.warp(block.timestamp + 2 hours);
    
    // Mock precisa ter timestamp antigo
    // Solução: Não atualizar mock, só warp
    
    vm.prank(user1);
    vm.expectRevert(KipuBankV3.StalePriceFeed.selector);
    (bool success,) = address(bank).call{value: 1 ether}("");
}
```

**Problema:** Mock é criado no setUp com `block.timestamp` atual.
Quando warp acontece, `latestTimestamp` do mock ainda é o antigo (correto!), mas o teste espera que funcione.

**O Mock FUNCIONA!** Teste precisa ajuste.

---

## 🎯 Prioridade de Fixes

### Priority 1: Core Issues (Fix estes primeiro)

**1.1 - Investigar Decimal Normalization**
```bash
forge test --match-test testDepositETH -vvvv
# Ver exatamente onde o balance fica 0
```

**1.2 - Verificar USDC Setup**
```solidity
// Adicionar teste de debug:
function testUSDCSetup() public view {
    (bool isSupported, uint256 totalDeposits, uint8 decimals) = bank.tokens(address(usdc));
    console.log("USDC supported:", isSupported);
    console.log("USDC decimals:", decimals);
    assertTrue(isSupported);
}
```

### Priority 2: Test Fixes

**2.1 - Fix testDepositRevertsWhenPaused**
Use `payable(address(bank)).transfer()` ao invés de `.call{value}()`

**2.2 - Fix testOracleValidation**
Abordagem: Criar teste diferente que não depende de warp:
```solidity
function testOracleValidation() public {
    // Deploy novo bank com mock que tem timestamp muito antigo
    MockV3Aggregator staleFeed = new MockV3Aggregator(8, int256(ETH_PRICE_USD));
    
    // Manually set stale timestamp
    vm.store(
        address(staleFeed),
        bytes32(uint256(2)), // latestTimestamp slot
        bytes32(block.timestamp - 2 hours)
    );
    
    KipuBankV3 testBank = new KipuBankV3(
        BANK_CAP_USD,
        WITHDRAWAL_LIMIT_USD,
        address(staleFeed), // Stale feed
        address(poolManager),
        address(permit2),
        address(usdc)
    );
    
    vm.prank(user1);
    vm.expectRevert(KipuBankV3.StalePriceFeed.selector);
    (bool success,) = address(testBank).call{value: 1 ether}("");
}
```

---

## 📝 Checklist para 100%

### Fase 1: Debug & Understand
- [ ] Rodar testDepositETH com -vvvv e ver onde balance fica 0
- [ ] Adicionar testUSDCSetup para verificar configuração
- [ ] Verificar _normalizeDecimals com console.log

### Fase 2: Fix Core Issues  
- [ ] Fix #1: testWithdrawETH (decimal normalization)
- [ ] Fix #2: testDepositUSDC (USDC setup)

### Fase 3: Fix Dependencies
- [ ] Fix #4: testCEIPatternInDeposit (depende de #2)
- [ ] Fix #5: testWithdrawUSDC (depende de #2)
- [ ] Fix #6: testGetUserBalanceUsd (depende de #2)

### Fase 4: Fix Test Logic
- [ ] Fix #3: testDepositRevertsWhenPaused (usar transfer)
- [ ] Fix #7: testOracleValidation (criar mock stale)

### Fase 5: Validate
- [ ] Rodar todos testes: `forge test --match-contract KipuBankV3Test`
- [ ] Verificar 20/20 passing
- [ ] Gas report: `forge test --gas-report`

---

## 🔍 Debug Commands

```bash
# Ver trace completo de um teste
forge test --match-test testDepositETH -vvvv

# Ver apenas o erro
forge test --match-test testDepositUSDC -vv

# Ver storage changes
forge test --match-test testWithdrawETH -vvvv | grep -A 5 "STORAGE"

# Debug específico
forge test --match-test testDepositETH --debug
```

---

## ✅ Expected Outcome

Após todos os fixes:

```
Ran 1 test suite: 20 tests passed, 0 failed, 0 skipped (20 total tests)

╔═══════════════════════════════════════════╗
║    KipuBankV3 Test Suite                 ║
╠═══════════════════════════════════════════╣
║  Total Tests:       20                    ║
║  ✅ Passing:        20 (100%)             ║
║  ❌ Failing:         0 (0%)               ║
║  ⏭️  Skipped:        0                     ║
╚═══════════════════════════════════════════╝
```

---

**Próximo Passo:** Começar com Fase 1 (Debug) para entender exatamente onde está o problema de decimal normalization.
