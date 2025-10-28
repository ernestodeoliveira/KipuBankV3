# KipuBankV3 - Uniswap V4 Integration

A decentralized bank smart contract that accepts ETH, USDC, and any ERC20 token, automatically swapping them to USDC using Uniswap V4's official lock-callback pattern.

## 🎯 Overview

KipuBankV3 implements the **official Uniswap V4 lock-callback pattern** as documented in the [Uniswap V4 Quickstart Guide](https://docs.uniswap.org/contracts/v4/quickstart/swap), allowing users to deposit any token and receive USDC credit in their account.

### Key Features

- ✅ **Uniswap V4 Integration** - Official lock-callback pattern implementation
- ✅ **Multi-Token Support** - Accept ETH, USDC, or any ERC20 token
- ✅ **Automatic Swaps** - Convert deposited tokens to USDC via Uniswap V4
- ✅ **Bank Cap Management** - Configurable TVL limits
- ✅ **Withdrawal Limits** - Prevent large single withdrawals
- ✅ **Access Control** - Role-based admin functions
- ✅ **Emergency Pause** - Circuit breaker for security
- ✅ **Chainlink Oracles** - USD value tracking

## 📋 Technical Stack

- **Solidity** ^0.8.26
- **Uniswap V4** Core (lock-callback pattern)
- **OpenZeppelin** (AccessControl, SafeERC20)
- **Chainlink** (Price Feeds)
- **Permit2** (Token approvals)
- **Foundry** (Development & Testing)

## 🏗️ Architecture

### Core Components

```
┌─────────────────────────────────────────┐
│         KipuBankV3 Contract             │
├─────────────────────────────────────────┤
│ ✓ IUnlockCallback (Uniswap V4)         │
│ ✓ AccessControl (OpenZeppelin)         │
├─────────────────────────────────────────┤
│                                         │
│  User Deposits Token                    │
│         ↓                               │
│  depositArbitraryToken()                │
│         ↓                               │
│  _swapExactInputSingle()                │
│         ↓                               │
│  poolManager.unlock() ← LOCK            │
│         ↓                               │
│  unlockCallback() ← CALLBACK            │
│         ↓                               │
│  poolManager.swap()                     │
│         ↓                               │
│  _settle() - Send tokens to pool        │
│         ↓                               │
│  _take() - Receive USDC from pool       │
│         ↓                               │
│  Credit user USDC balance               │
│                                         │
└─────────────────────────────────────────┘
```

### Uniswap V4 Lock-Callback Pattern

The contract implements the official Uniswap V4 pattern:

1. **Lock Phase**: Call `poolManager.unlock()` with encoded swap data
2. **Callback Phase**: PoolManager calls `unlockCallback()`
3. **Swap Execution**: Execute swap via `poolManager.swap()`
4. **Settle**: Send input tokens to PoolManager
5. **Take**: Receive output tokens from PoolManager
6. **Unlock**: PoolManager releases lock

## 📦 Installation

```bash
# Clone repository
git clone <repository-url>
cd SwapModule

# Install dependencies
forge install

# Compile contracts
forge build
```

## 🚀 Deployment

### Prerequisites

Set environment variables in `.env`:

```bash
PRIVATE_KEY=<your-private-key>
SEPOLIA_RPC_URL=<sepolia-rpc-url>
ETHERSCAN_API_KEY=<etherscan-api-key>
```

### Deploy Script

```bash
# Deploy to Sepolia testnet
forge script script/DeployKipuBankV3.s.sol:DeployKipuBankV3 \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast \
    --verify
```

### Constructor Parameters

```solidity
constructor(
    uint256 _bankCapUsd,           // e.g., 1_000_000e6 ($1M)
    uint256 _withdrawalLimitUsd,   // e.g., 10_000e6 ($10k)
    address _ethUsdPriceFeed,      // Chainlink ETH/USD feed
    address _poolManager,          // Uniswap V4 PoolManager
    address _permit2,              // Permit2 contract
    address _usdc                  // USDC token address
)
```

## 💡 Usage

### For Users

#### 1. Deposit ETH

```solidity
// Send ETH directly to contract
(bool success, ) = address(kipuBank).call{value: 1 ether}("");
```

#### 2. Deposit USDC

```solidity
// Approve USDC
IERC20(usdc).approve(address(kipuBank), 1000e6);

// Deposit USDC
kipuBank.depositToken(usdc, 1000e6);
```

#### 3. Deposit Any Token (Swaps to USDC)

```solidity
// Approve token
IERC20(token).approve(address(kipuBank), amount);

// Deposit with slippage protection
kipuBank.depositArbitraryToken(
    token,      // Token address
    amount,     // Amount to deposit
    minUsdcOut  // Minimum USDC to receive (slippage)
);
```

#### 4. Withdraw

```solidity
// Withdraw USDC
kipuBank.withdraw(usdc, 1000e6);

// Withdraw ETH
kipuBank.withdraw(address(0), 1 ether);
```

#### 5. Check Balance

```solidity
// Get balance and timestamp
(uint256 balance, uint256 timestamp) = kipuBank.getUserBalance(user, token);

// Get balance in USD
uint256 balanceUsd = kipuBank.getUserBalanceUsd(user, token);
```

### For Admins

#### Configure Pool Keys

Before users can deposit arbitrary tokens, configure the Uniswap V4 pool keys:

```solidity
// Example: DAI/USDC pool
kipuBank.setPoolKey(
    DAI,                    // Token to configure
    DAI,                    // currency0
    USDC,                   // currency1
    3000,                   // Fee (0.3%)
    60,                     // Tick spacing
    address(0)              // Hooks (none)
);
```

#### Add Supported Tokens

```solidity
kipuBank.addToken(
    tokenAddress,
    priceFeedAddress  // Chainlink price feed
);
```

#### Update Bank Cap

```solidity
kipuBank.updateBankCap(2_000_000e6); // $2M cap
```

#### Emergency Pause

```solidity
kipuBank.setPaused(true);  // Pause deposits/withdrawals
kipuBank.setPaused(false); // Resume operations
```

## 🔑 Key Functions

### User Functions

| Function | Description |
|----------|-------------|
| `receive()` / `fallback()` | Deposit ETH directly |
| `depositToken(token, amount)` | Deposit supported token |
| `depositArbitraryToken(token, amount, minOut)` | Deposit any token, swap to USDC |
| `withdraw(token, amount)` | Withdraw deposited tokens |
| `getUserBalance(user, token)` | Get user balance |
| `getUserBalanceUsd(user, token)` | Get balance in USD |

### Admin Functions (ADMIN_ROLE)

| Function | Description |
|----------|-------------|
| `setPoolKey(...)` | Configure Uniswap V4 pool for token |
| `addToken(token, priceFeed)` | Add supported token |
| `removeToken(token)` | Remove token support |
| `updateBankCap(newCap)` | Update TVL limit |

### Emergency Functions (EMERGENCY_ROLE)

| Function | Description |
|----------|-------------|
| `setPaused(bool)` | Pause/unpause contract |

## 🔍 Uniswap V4 Implementation Details

### Lock-Callback Pattern

```solidity
// 1. Initiate swap with unlock
function _swapExactInputSingle(...) internal returns (uint256) {
    SwapCallbackData memory data = SwapCallbackData({...});
    bytes memory result = poolManager.unlock(abi.encode(data));
    return abi.decode(result, (uint256));
}

// 2. Callback executed by PoolManager
function unlockCallback(bytes calldata data) external override {
    require(msg.sender == address(poolManager));
    
    SwapCallbackData memory swapData = abi.decode(data, (...));
    
    // Execute swap
    BalanceDelta delta = poolManager.swap(swapData.poolKey, params, "");
    
    // Settle input tokens
    _settle(...);
    
    // Take output tokens
    uint256 amountOut = _take(...);
    
    return abi.encode(amountOut);
}
```

### Settle (Send Tokens to Pool)

```solidity
function _settle(...) internal {
    Currency currencyToSettle = zeroForOne ? currency0 : currency1;
    uint256 amountToSettle = uint256(int256(-delta.amount0()));
    
    IERC20(Currency.unwrap(currencyToSettle)).safeTransferFrom(
        payer, 
        address(poolManager), 
        amountToSettle
    );
    
    poolManager.sync(currencyToSettle);
}
```

### Take (Receive Tokens from Pool)

```solidity
function _take(...) internal returns (uint256) {
    Currency currencyToTake = zeroForOne ? currency1 : currency0;
    uint256 amountOut = uint256(uint128(delta.amount1()));
    
    poolManager.take(currencyToTake, recipient, amountOut);
    
    return amountOut;
}
```

## 📊 State Variables

### Immutable

- `ethUsdPriceFeed` - Chainlink ETH/USD price feed
- `WITHDRAWAL_LIMIT_USD` - Max USD per withdrawal
- `poolManager` - Uniswap V4 PoolManager
- `permit2` - Permit2 contract
- `USDC` - USDC token address

### Configurable

- `bankCapUsd` - Maximum TVL in USD
- `totalValueLockedUsd` - Current TVL
- `paused` - Emergency pause state

### Mappings

- `tokens` - Token info (supported, deposits, decimals)
- `userDeposits` - User balances per token
- `priceFeeds` - Chainlink price feeds per token
- `tokenToUsdcPool` - Uniswap V4 PoolKey per token

## ⚙️ Constants

```solidity
uint8 public constant TARGET_DECIMALS = 6;           // Normalize to 6 decimals
address public constant NATIVE_ETH = address(0);     // ETH representation
uint256 public constant MIN_DEPOSIT_USD = 1e6;       // $1 minimum deposit

// Uniswap V4 Price Limits
uint160 public constant MIN_SQRT_PRICE_LIMIT = 4295128739;
uint160 public constant MAX_SQRT_PRICE_LIMIT = 1461446703485210103287273052203988822378723970342;
```

## 🛡️ Security Features

### Access Control
- **DEFAULT_ADMIN_ROLE**: Can grant/revoke all roles
- **ADMIN_ROLE**: Can configure tokens and limits
- **EMERGENCY_ROLE**: Can pause contract

### Protections
- ✅ SafeERC20 for all token transfers
- ✅ Withdrawal limits per transaction
- ✅ Bank cap enforcement
- ✅ Emergency pause mechanism
- ✅ Role-based access control
- ✅ Slippage protection on swaps
- ✅ Callback authorization (only PoolManager)

### Price Feed Validation
- Checks `price > 0` from Chainlink oracle
- Prevents invalid price data

## 📝 Events

```solidity
event Deposit(address indexed user, address indexed token, uint256 amount, uint256 amountUsd);
event ArbitraryTokenDeposit(address indexed user, address indexed token, uint256 amountIn, uint256 usdcOut);
event Withdrawal(address indexed user, address indexed token, uint256 amount, uint256 amountUsd);
```

## ❌ Custom Errors

```solidity
error ZeroAmount();
error TokenNotSupported(address token);
error ExceedsBankCap(uint256 attempted, uint256 available);
error ExceedsWithdrawalLimit(uint256 requested, uint256 limit);
error InsufficientBalance(uint256 requested, uint256 available);
error TransferFailed();
error InvalidPriceFeed();
error BelowMinimumDeposit(uint256 amount, uint256 minimum);
error ContractPaused();
error SwapFailed();
error InvalidPool();
error UnauthorizedCallback();
```

## 🧪 Testing

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run specific test
forge test --match-test testDepositArbitraryToken

# Gas report
forge test --gas-report
```

## 📈 Example Flow

### Depositing DAI and Receiving USDC

```solidity
// 1. User approves DAI
DAI.approve(address(kipuBank), 1000e18);

// 2. User deposits DAI
kipuBank.depositArbitraryToken(
    address(DAI),
    1000e18,     // 1000 DAI
    990e6        // Min 990 USDC (1% slippage)
);

// Behind the scenes:
// - Contract receives 1000 DAI
// - Calls poolManager.unlock() with swap data
// - unlockCallback() executes:
//   - poolManager.swap(DAI/USDC pool)
//   - _settle(): Sends DAI to pool
//   - _take(): Receives USDC from pool
// - User credited ~995 USDC in their balance

// 3. Check balance
(uint256 balance,) = kipuBank.getUserBalance(msg.sender, USDC);
// balance ≈ 995e6 (depends on actual swap rate)
```

## 🔗 Contract Addresses

### Sepolia Testnet

| Contract | Address |
|----------|---------|
| KipuBankV3 | `<deploy-address>` |
| PoolManager | `<uniswap-v4-address>` |
| Permit2 | `0x000000000022D473030F116dDEE9F6B43aC78BA3` |
| USDC | `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238` |
| ETH/USD Feed | `0x694AA1769357215DE4FAC081bf1f309aDC325306` |

## 📚 References

- [Uniswap V4 Documentation](https://docs.uniswap.org/contracts/v4/overview)
- [Uniswap V4 Quickstart - Swap](https://docs.uniswap.org/contracts/v4/quickstart/swap)
- [Uniswap V4 Core Repository](https://github.com/Uniswap/v4-core)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts)
- [Chainlink Data Feeds](https://docs.chain.link/data-feeds)
- [Permit2](https://github.com/Uniswap/permit2)

## ⚠️ Important Notes

### For Production

1. **Security Audit Required** - This contract should be professionally audited before mainnet deployment
2. **Gas Optimization** - Consider optimizing for gas costs in production
3. **Multi-Sig Admin** - Use multi-signature wallet for admin roles
4. **Monitoring** - Set up monitoring for all admin actions and unusual activity
5. **Insurance** - Consider protocol insurance for user funds

### Limitations

- Relies on Chainlink price feeds being up-to-date
- Uniswap V4 pool must exist and have liquidity
- Slippage on swaps depends on pool depth
- Single withdrawal limit enforced per transaction

## 📄 License

MIT License - see LICENSE file for details

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Add tests for new features
4. Submit a pull request

## 👨‍💻 Authors

**Ernesto de Oliveira**  
ETH Kipu - Uniswap V4 Integration Project

---

**Built with Uniswap V4 Official Lock-Callback Pattern** 🦄

For questions or support, please open an issue in the repository.
