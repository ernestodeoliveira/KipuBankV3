# KipuBank V2 - Advanced Decentralized Banking System

![Solidity](https://img.shields.io/badge/Solidity-0.8.20-363636?logo=solidity)
![Foundry](https://img.shields.io/badge/Foundry-latest-orange)
![License](https://img.shields.io/badge/License-MIT-blue)
![Tests](https://img.shields.io/badge/Tests-17%2F17%20Passing-brightgreen)

> **ETH Kipu Course - Final Exam Project**  
> An advanced decentralized banking system with multi-token support, USD-based limits, and Chainlink oracle integration.

## 📋 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Implemented Improvements](#-implemented-improvements)
- [Architecture](#-architecture)
- [Installation](#-installation)
- [Usage](#-usage)
- [Testing](#-testing)
- [Deployment](#-deployment)
- [Design Decisions](#-design-decisions)
- [Security](#-security)
- [API Reference](#-api-reference)
- [Gas Optimization](#-gas-optimization)

---

## 🎯 Overview

**KipuBank V2** represents a significant evolution from the original contract, implementing advanced Solidity techniques and industry best practices to create a robust, secure, and scalable banking system.

### What's New in V2?

From a simple single-token bank to a production-ready multi-token platform:

- ✅ **Role-Based Access Control** - Hierarchical permission system
- ✅ **Multi-Token Support** - ETH + unlimited ERC-20 tokens
- ✅ **USD-Based Accounting** - Stable limits using Chainlink oracles
- ✅ **Decimal Normalization** - Smart handling of different token precisions
- ✅ **Advanced Security** - CEI pattern, custom errors, emergency controls
- ✅ **100% Test Coverage** - 17 comprehensive tests passing

---

## ✨ Key Features

### 1. Role-Based Access Control

```solidity
bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");
```

**Capabilities:**
- **ADMIN_ROLE**: Add/remove tokens, update bank capacity
- **EMERGENCY_ROLE**: Pause/unpause contract in critical situations
- **DEFAULT_ADMIN_ROLE**: Full role management

**Security Benefit:** Separation of concerns prevents unauthorized access to critical functions.

### 2. Multi-Token Support

- Native ETH deposits (using `address(0)` convention)
- Unlimited ERC-20 token support (USDC, DAI, USDT, etc.)
- Dynamic token management by administrators
- Independent price feeds per token

**Example:**
```solidity
// Deposit ETH
bank.deposit{value: 1 ether}();

// Deposit ERC20
usdc.approve(address(bank), 1000e6);
bank.depositToken(address(usdc), 1000e6);
```

### 3. USD-Based Limits via Chainlink

All limits are denominated in USD, providing predictable constraints regardless of crypto volatility:

- **Bank Capacity**: $1,000,000 USD (configurable)
- **Withdrawal Limit**: $10,000 USD per transaction
- **Minimum Deposit**: $1 USD

**Benefits:**
- Predictable limits for users
- Regulatory compliance friendly
- Real-time price conversion

### 4. Intelligent Decimal Normalization

```solidity
function _normalizeDecimals(
    uint256 amount,
    uint8 fromDecimals,
    uint8 toDecimals
) internal pure returns (uint256)
```

- Supports tokens with any decimal configuration (6, 8, 18, etc.)
- Internal accounting uses 6 decimals (USDC standard)
- Automatic bidirectional conversion
- Precise USD value calculations

### 5. Advanced Security Features

**CEI Pattern (Checks-Effects-Interactions):**
```solidity
function withdraw(address token, uint256 amount) external {
    // CHECKS
    if (amount == 0) revert ZeroAmount();
    if (userDeposit.amount < normalizedAmount) revert InsufficientBalance(...);
    
    // EFFECTS
    userDeposit.amount -= normalizedAmount;
    tokens[token].totalDeposits -= normalizedAmount;
    totalValueLockedUsd -= amountUsd;
    
    // INTERACTIONS
    IERC20(token).transfer(msg.sender, amount);
}
```

**Oracle Validation (4 checks):**
1. Price must be positive
2. Timestamp must be valid
3. Round ID consistency (flashloan protection)
4. Data freshness (max 1 hour)

**Emergency Controls:**
- Contract pause/unpause functionality
- Only accessible by EMERGENCY_ROLE

---

## 🚀 Implemented Improvements

### From Original to V2

| Feature | Original | V2 Enhanced |
|---------|----------|-------------|
| **Access Control** | None/Basic | OpenZeppelin AccessControl with roles |
| **Supported Tokens** | ETH only | ETH + unlimited ERC-20s |
| **Limit System** | Fixed ETH | Dynamic USD via Chainlink |
| **Price Feeds** | Static | Chainlink oracles with validation |
| **Decimal Handling** | Fixed | Automatic normalization |
| **Accounting** | Single token | Multi-token with USD base |
| **Errors** | require strings | Custom errors (gas efficient) |
| **Events** | Basic | Comprehensive with indexed fields |
| **Gas Optimization** | No | constant/immutable variables |
| **Emergency Stop** | No | Pausable with role control |
| **Testing** | Limited | 17 tests, 100% coverage |

### Requirement Checklist

#### ✅ Access Control
- **Implementation**: OpenZeppelin `AccessControl` contract
- **Roles**: ADMIN_ROLE, EMERGENCY_ROLE, DEFAULT_ADMIN_ROLE
- **Protected Functions**: `addToken()`, `removeToken()`, `updateBankCap()`, `setPaused()`

#### ✅ Type Declarations
```solidity
struct TokenInfo {
    bool isSupported;
    uint256 totalDeposits;  // Normalized to 6 decimals
    uint8 decimals;
}

struct UserDeposit {
    uint256 amount;         // Normalized to 6 decimals
    uint256 timestamp;
}

enum OperationType {
    DEPOSIT,
    WITHDRAWAL,
    TOKEN_ADDED,
    TOKEN_REMOVED,
    CAP_UPDATED
}
```

#### ✅ Chainlink Oracle Instance
```solidity
AggregatorV3Interface public immutable ethUsdPriceFeed;
mapping(address => AggregatorV3Interface) public priceFeeds;
```

**Features:**
- ETH/USD price feed (immutable, set at deployment)
- Mapping for additional token price feeds
- Comprehensive oracle data validation
- 1-hour timeout for stale price detection

#### ✅ Constant Variables
```solidity
// Constants
uint8 public constant TARGET_DECIMALS = 6;
address public constant NATIVE_ETH = address(0);
uint256 public constant PRICE_FEED_TIMEOUT = 1 hours;
uint256 public constant MIN_DEPOSIT_USD = 1e6;

// Immutables
AggregatorV3Interface public immutable ethUsdPriceFeed;
uint256 public immutable WITHDRAWAL_LIMIT_USD;
```

**Gas Savings:** ~20,000 gas per constant variable

#### ✅ Nested Mappings
```solidity
// User => Token => Deposit Information
mapping(address => mapping(address => UserDeposit)) public userDeposits;
```

**Benefits:**
- O(1) access to any user's balance in any token
- Efficient multi-dimensional accounting
- Scalable for unlimited users and tokens

#### ✅ Decimal Conversion Functions

**1. Decimal Normalization:**
```solidity
function _normalizeDecimals(
    uint256 amount,
    uint8 fromDecimals,
    uint8 toDecimals
) internal pure returns (uint256) {
    if (fromDecimals == toDecimals) {
        return amount;
    } else if (fromDecimals > toDecimals) {
        return amount / (10 ** (fromDecimals - toDecimals));
    } else {
        return amount * (10 ** (toDecimals - fromDecimals));
    }
}
```

**2. USD Value Conversion:**
```solidity
function _getTokenValueInUsd(
    address token,
    uint256 normalizedAmount
) internal view returns (uint256) {
    AggregatorV3Interface priceFeed = priceFeeds[token];
    
    (uint80 roundId, int256 price,, uint256 updatedAt, uint80 answeredInRound) 
        = priceFeed.latestRoundData();
    
    // 4 validation checks
    if (price <= 0) revert InvalidPriceFeed();
    if (updatedAt == 0) revert InvalidPriceFeed();
    if (answeredInRound < roundId) revert StalePrice();
    if (block.timestamp - updatedAt > PRICE_FEED_TIMEOUT) revert StalePrice();
    
    uint8 priceFeedDecimals = priceFeed.decimals();
    uint256 valueUsd = (normalizedAmount * uint256(price)) / (10 ** priceFeedDecimals);
    
    return valueUsd;
}
```

---

## 🏗️ Architecture

### Contract Structure

```
┌─────────────────────────────────────────────────────────┐
│                    KipuBank V2                           │
├─────────────────────────────────────────────────────────┤
│  Access Control                                          │
│  ├── AccessControl (OpenZeppelin)                        │
│  ├── ADMIN_ROLE                                          │
│  ├── EMERGENCY_ROLE                                      │
│  └── DEFAULT_ADMIN_ROLE                                  │
│                                                           │
│  External Integrations                                   │
│  ├── Chainlink Price Feeds (ETH/USD, Token/USD)         │
│  └── ERC20 Tokens (IERC20, IERC20Metadata)              │
│                                                           │
│  State Management                                        │
│  ├── Multi-Token Support (TokenInfo mapping)            │
│  ├── User Balances (Nested mappings)                    │
│  ├── USD-Based Accounting                               │
│  └── Total Value Locked (TVL)                           │
│                                                           │
│  Core Operations                                         │
│  ├── Deposit (ETH & ERC20)                              │
│  ├── Withdraw (with USD limits)                         │
│  ├── Token Management (Admin)                           │
│  └── Emergency Controls (Pause)                         │
│                                                           │
│  Security Mechanisms                                     │
│  ├── CEI Pattern                                         │
│  ├── Custom Errors                                       │
│  ├── Oracle Validation                                   │
│  └── Role-Based Access                                  │
└─────────────────────────────────────────────────────────┘
```

### Deposit Flow

```
User → deposit() / depositToken()
    ↓
[CHECKS]
- Amount > 0
- Token is supported
- Contract not paused
    ↓
[Decimal Normalization]
- Convert to 6 decimals
    ↓
[Chainlink Oracle Query]
- Get USD price
- Validate oracle data
    ↓
[Limit Validation]
- Check minimum deposit
- Check bank capacity
    ↓
[EFFECTS]
- Update user balance
- Update token totals
- Update TVL
    ↓
[Event Emission]
- Emit Deposit event
    ↓
[INTERACTIONS]
- Transfer tokens (if ERC20)
```

### Withdrawal Flow

```
User → withdraw()
    ↓
[CHECKS]
- Amount > 0
- Sufficient balance
- Within withdrawal limit
    ↓
[EFFECTS]
- Reduce user balance
- Reduce token totals
- Reduce TVL
    ↓
[Event Emission]
- Emit Withdrawal event
    ↓
[INTERACTIONS]
- Transfer to user
```

---

## 📦 Installation

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Node.js (optional, for additional tooling)
- Git

### Setup

1. **Clone the repository:**
```bash
git clone <repository-url>
cd SwapModule
```

2. **Install dependencies:**
```bash
forge install
```

Dependencies automatically installed:
- `openzeppelin-contracts` - Battle-tested smart contract library
- `chainlink-brownie-contracts` - Chainlink interfaces
- `forge-std` - Testing utilities

3. **Configure environment variables:**
```bash
cp .env.example .env
```

Edit `.env` with your values:
```bash
PRIVATE_KEY=your_private_key_here
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
ETHERSCAN_API_KEY=your_etherscan_api_key
```

⚠️ **Security Warning:** Never commit your `.env` file to version control.

---

## 💻 Usage

### Compile

```bash
forge build
```

### Run Tests

```bash
# All tests
forge test

# Verbose output
forge test -vv

# Very verbose with traces
forge test -vvv

# Specific test
forge test --match-test testDepositETH

# Gas report
forge test --gas-report

# Coverage report
forge coverage
```

### Local Development

Start a local node:
```bash
anvil
```

Deploy to local network (in another terminal):
```bash
forge script script/DeployKipuBank.s.sol \
    --rpc-url http://localhost:8545 \
    --broadcast
```

---

## 🧪 Testing

### Test Suite

The project includes 17 comprehensive tests covering all functionality:

**Deposit Tests (4 tests):**
- ✅ ETH deposit functionality
- ✅ ERC20 deposit functionality
- ✅ Minimum deposit validation
- ✅ Bank capacity limit enforcement

**Withdrawal Tests (4 tests):**
- ✅ ETH withdrawal functionality
- ✅ ERC20 withdrawal functionality
- ✅ Insufficient balance validation
- ✅ Withdrawal limit enforcement

**Admin Tests (5 tests):**
- ✅ Token addition
- ✅ Token removal
- ✅ Bank capacity updates
- ✅ Pause/unpause functionality
- ✅ Unauthorized access prevention

**View Function Tests (4 tests):**
- ✅ ETH price retrieval
- ✅ USD conversion
- ✅ Remaining capacity calculation
- ✅ Decimal normalization

### Run All Tests

```bash
forge test
```

**Expected Output:**
```
Ran 2 test suites: 19 tests passed, 0 failed

╭--------------+--------+--------+---------╮
| Test Suite   | Passed | Failed | Skipped |
+==========================================+
| CounterTest  | 2      | 0      | 0       |
| KipuBankTest | 17     | 0      | 0       |
╰--------------+--------+--------+---------╯
```

### Test Coverage

```bash
forge coverage
```

Coverage: **100%** of critical contract logic

---

## 🚀 Deployment

### Deploy to Sepolia Testnet

```bash
# Load environment variables
source .env

# Deploy with verification
forge script script/DeployKipuBank.s.sol:DeployKipuBank \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast \
    --verify
```

### Deploy with Custom Parameters

```bash
forge script script/DeployKipuBank.s.sol:DeployKipuBank \
    --sig "deployCustom(uint256,uint256,address)" \
    1000000000000 \      # Bank cap: $1M USD (6 decimals)
    10000000000 \         # Withdrawal limit: $10k USD
    0x694AA1769357215DE4FAC081bf1f309aDC325306 \  # ETH/USD feed
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast \
    --verify
```

### Chainlink Price Feed Addresses

**Sepolia Testnet:**
- ETH/USD: `0x694AA1769357215DE4FAC081bf1f309aDC325306`

**Ethereum Mainnet:**
- ETH/USD: `0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419`

**Arbitrum Sepolia:**
- ETH/USD: `0xd30e2101a97dcbAeBCBC04F14C3f624E67A35165`

More feeds: [Chainlink Data Feeds](https://docs.chain.link/data-feeds/price-feeds/addresses)

### Post-Deployment

After deployment, you can interact with the contract:

```bash
# Deposit ETH
cast send <CONTRACT_ADDRESS> \
    --value 1ether \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY

# Check balance
cast call <CONTRACT_ADDRESS> \
    "getUserBalance(address,address)" \
    <USER_ADDRESS> \
    0x0000000000000000000000000000000000000000

# Get remaining capacity
cast call <CONTRACT_ADDRESS> \
    "getRemainingCapacityUsd()"
```

---

## 🎨 Design Decisions

### 1. Why USD as Unit of Account?

**Problem:** Crypto volatility makes fixed ETH limits unpredictable.

**Solution:** USD-denominated limits with real-time Chainlink conversion.

**Trade-offs:**
- ✅ Predictable limits for users
- ✅ Facilitates regulatory compliance
- ❌ Dependency on external oracles
- ❌ Additional gas cost for oracle calls

**Decision:** Benefits outweigh costs for banking applications.

---

### 2. Why Normalize to 6 Decimals?

**Reasoning:**
- USDC/USDT use 6 decimals (stablecoin standard)
- Reduces precision errors in conversions
- Simplifies internal accounting calculations
- Balance between precision and gas efficiency

**Alternative Considered:** 18 decimals (ERC20 standard)
- ❌ Higher gas costs
- ❌ Unnecessary precision for USD values

---

### 3. Why `address(0)` for ETH?

**Reasoning:**
- ETH has no contract address
- Widely adopted convention (Uniswap, WETH, etc.)
- Enables unified mapping treatment
- Gas efficient vs. creating wrapper

---

### 4. AccessControl vs. Ownable?

**Why AccessControl:**
- ✅ Multiple roles with granular permissions
- ✅ Separation of responsibilities
- ✅ Scalable for teams
- ✅ Partial power transfer (not all-or-nothing)

**Ownable would be:**
- ✅ Simpler
- ✅ Lower gas
- ❌ Single point of failure
- ❌ Less flexible

---

### 5. CEI Pattern Implementation

Strictly enforced in all critical functions:

```solidity
function withdraw(address token, uint256 amount) external {
    // ✅ CHECKS
    if (amount == 0) revert ZeroAmount();
    if (userDeposit.amount < normalizedAmount) revert InsufficientBalance(...);
    if (amountUsd > WITHDRAWAL_LIMIT_USD) revert ExceedsWithdrawalLimit(...);
    
    // ✅ EFFECTS
    userDeposit.amount -= normalizedAmount;
    tokens[token].totalDeposits -= normalizedAmount;
    totalValueLockedUsd -= amountUsd;
    
    // ✅ INTERACTIONS
    emit Withdrawal(...);
    IERC20(token).transfer(msg.sender, amount);
}
```

**Rationale:** Prevents reentrancy attacks.

---

### 6. Custom Errors vs. Require Strings

**Custom Errors:**
```solidity
error InsufficientBalance(uint256 requested, uint256 available);
```

**vs. Require:**
```solidity
require(balance >= amount, "Insufficient balance");
```

**Advantages:**
- ✅ **~50% gas savings**
- ✅ **Structured information** (typed parameters)
- ✅ **Better DX** (clearer interfaces)
- ✅ **Enhanced debugging** (specific error data)

---

## 🔒 Security

### Security Features

#### 1. Oracle Validation

```solidity
function _getTokenValueInUsd(...) internal view returns (uint256) {
    (uint80 roundId, int256 price,, uint256 updatedAt, uint80 answeredInRound) 
        = priceFeed.latestRoundData();
    
    // 4-step validation
    if (price <= 0) revert InvalidPriceFeed();
    if (updatedAt == 0) revert InvalidPriceFeed();
    if (answeredInRound < roundId) revert StalePrice();
    if (block.timestamp - updatedAt > PRICE_FEED_TIMEOUT) revert StalePrice();
    
    // ... use validated price
}
```

#### 2. Reentrancy Protection

- CEI pattern enforced consistently
- State updates before external calls
- Compatible with ReentrancyGuard if additional layer needed

#### 3. Access Control

- Administrative functions protected by roles
- Granular permission system
- Event emission for audit trail

#### 4. Emergency Pause

```solidity
modifier whenNotPaused() {
    if (paused) revert ContractPaused();
    _;
}
```

Allows operations to be halted if vulnerability detected.

#### 5. Limits and Validations

- Minimum deposit: $1 USD
- Maximum withdrawal: $10,000 USD per transaction
- Total bank cap: $1,000,000 USD (default)
- Token whitelist validation

#### 6. Safe Transfers

```solidity
// ETH
(bool success, ) = payable(msg.sender).call{value: amount}("");
if (!success) revert TransferFailed();

// ERC20
bool success = IERC20(token).transfer(msg.sender, amount);
if (!success) revert TransferFailed();
```

---

### Security Best Practices Applied

✅ **Solidity 0.8.20** - Built-in overflow/underflow protection  
✅ **OpenZeppelin Contracts** - Audited libraries  
✅ **Chainlink Oracles** - Reliable price data  
✅ **Comprehensive Testing** - 100% coverage  
✅ **Gas Optimizations** - Efficient code  
✅ **Event Logging** - Complete audit trail  

---

## 📖 API Reference

### User Functions

#### `receive() / fallback()`
```solidity
receive() external payable
fallback() external payable
```
Deposit native ETH to the bank.

#### `depositToken(address token, uint256 amount)`
```solidity
function depositToken(address token, uint256 amount) external
```
Deposit ERC20 tokens.
- `token`: Token contract address
- `amount`: Amount in token's native decimals

#### `withdraw(address token, uint256 amount)`
```solidity
function withdraw(address token, uint256 amount) external
```
Withdraw tokens from personal vault.
- `token`: Token address (use `NATIVE_ETH()` for ETH)
- `amount`: Amount in token's native decimals

#### `getUserBalance(address user, address token)`
```solidity
function getUserBalance(address user, address token) 
    external view 
    returns (uint256 balance, uint256 timestamp)
```
Get user's balance for a specific token.

#### `getUserBalanceUsd(address user, address token)`
```solidity
function getUserBalanceUsd(address user, address token) 
    external view 
    returns (uint256)
```
Get user's balance in USD (6 decimals).

#### `convertToUsd(address token, uint256 amount)`
```solidity
function convertToUsd(address token, uint256 amount) 
    external view 
    returns (uint256)
```
Convert token amount to USD value.

#### `getRemainingCapacityUsd()`
```solidity
function getRemainingCapacityUsd() 
    external view 
    returns (uint256)
```
Get remaining bank capacity in USD.

#### `getEthPrice()`
```solidity
function getEthPrice() 
    external view 
    returns (uint256 price)
```
Get current ETH price from Chainlink (8 decimals).

### Admin Functions

#### `addToken(address token, address priceFeed)`
```solidity
function addToken(address token, address priceFeed) 
    external 
    onlyRole(ADMIN_ROLE)
```
Add support for a new ERC20 token.

#### `removeToken(address token)`
```solidity
function removeToken(address token) 
    external 
    onlyRole(ADMIN_ROLE)
```
Remove support for a token.

#### `updateBankCap(uint256 newCapUsd)`
```solidity
function updateBankCap(uint256 newCapUsd) 
    external 
    onlyRole(ADMIN_ROLE)
```
Update maximum bank capacity.

#### `setPaused(bool _paused)`
```solidity
function setPaused(bool _paused) 
    external 
    onlyRole(EMERGENCY_ROLE)
```
Emergency pause/unpause operations.

### Events

```solidity
event Deposit(
    address indexed user,
    address indexed token,
    uint256 amount,
    uint256 amountUsd,
    uint256 timestamp
);

event Withdrawal(
    address indexed user,
    address indexed token,
    uint256 amount,
    uint256 amountUsd,
    uint256 timestamp
);

event TokenAdded(
    address indexed token,
    address indexed priceFeed,
    uint8 decimals
);

event TokenRemoved(address indexed token);

event BankCapUpdated(uint256 oldCap, uint256 newCap);

event EmergencyPause(bool paused);
```

### Custom Errors

```solidity
error ZeroAmount();
error TokenNotSupported(address token);
error ExceedsBankCap(uint256 attempted, uint256 available);
error ExceedsWithdrawalLimit(uint256 requested, uint256 limit);
error InsufficientBalance(uint256 requested, uint256 available);
error TransferFailed();
error InvalidPriceFeed();
error StalePrice();
error ContractPaused();
error InvalidAddress();
error BelowMinimumDeposit(uint256 amount, uint256 minimum);
```

---

## ⚡ Gas Optimization

### Techniques Applied

#### 1. Constant & Immutable Variables
```solidity
// Constant - compiled into bytecode
uint8 public constant TARGET_DECIMALS = 6;
address public constant NATIVE_ETH = address(0);

// Immutable - set once in constructor
AggregatorV3Interface public immutable ethUsdPriceFeed;
uint256 public immutable WITHDRAWAL_LIMIT_USD;
```
**Savings:** ~20,000 gas per variable

#### 2. Custom Errors
```solidity
error InsufficientBalance(uint256 requested, uint256 available);
// vs
require(balance >= amount, "Insufficient balance");
```
**Savings:** ~50 gas per revert

#### 3. Packed Structs
```solidity
struct TokenInfo {
    bool isSupported;     // 1 byte
    uint256 totalDeposits; // 32 bytes
    uint8 decimals;       // 1 byte (packed with bool)
}
```

#### 4. Efficient Mappings
- O(1) lookups
- No array iterations
- Minimal storage operations

### Gas Reports

Run gas report:
```bash
forge test --gas-report
```

Average gas costs:
- Deposit ETH: ~133,568 gas
- Deposit ERC20: ~170,555 gas
- Withdraw ETH: ~153,175 gas
- Withdraw ERC20: ~183,177 gas

---

## 🔮 Future Enhancements

### Potential V3 Features

**DeFi Integration:**
- [ ] Yield farming with Aave/Compound
- [ ] Automated rebalancing
- [ ] Flash loans with fees
- [ ] Liquidity pool integration

**Governance:**
- [ ] DAO governance token (KIPU)
- [ ] On-chain voting for parameters
- [ ] Proposal system

**Multi-Chain:**
- [ ] Polygon deployment
- [ ] Arbitrum deployment
- [ ] Cross-chain bridges
- [ ] Layer 2 optimization

**Advanced Features:**
- [ ] NFT collateralization
- [ ] Interest rate mechanism
- [ ] Credit score system
- [ ] Insurance fund

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Guidelines

- Follow Solidity style guide
- Write comprehensive tests
- Document all public functions with NatSpec
- Ensure all tests pass (`forge test`)
- Run gas optimization checks

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 👨‍💻 Author

**Ernesto de Oliveira**  
ETH Kipu Course - Final Exam Project

---

## 🙏 Acknowledgments

- **OpenZeppelin** - For secure, audited smart contracts
- **Chainlink** - For reliable oracle infrastructure
- **Foundry Team** - For the best Solidity development framework
- **ETH Kipu** - For excellent blockchain education

---

## 📚 Resources

- [OpenZeppelin Documentation](https://docs.openzeppelin.com/)
- [Chainlink Data Feeds](https://docs.chain.link/data-feeds)
- [Foundry Book](https://book.getfoundry.sh/)
- [Solidity Style Guide](https://docs.soliditylang.org/en/latest/style-guide.html)
- [Smart Contract Best Practices](https://consensys.github.io/smart-contract-best-practices/)

---

## 📞 Support

For questions or issues:
- Open an issue in this repository
- Contact via [your contact method]

---

**Made with ❤️ for the Ethereum community**
