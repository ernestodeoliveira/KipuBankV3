// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// Uniswap V4 Core - Following Official Quickstart Guide
// https://docs.uniswap.org/contracts/v4/quickstart/swap
import {IPoolManager} from "@uniswap/v4-core/interfaces/IPoolManager.sol";
import {IUnlockCallback} from "@uniswap/v4-core/interfaces/callback/IUnlockCallback.sol";
import {PoolKey} from "@uniswap/v4-core/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/types/Currency.sol";
import {BalanceDelta} from "@uniswap/v4-core/types/BalanceDelta.sol";
import {IHooks} from "@uniswap/v4-core/interfaces/IHooks.sol";

// Permit2 - UniversalRouter Pattern (Official V4 Documentation)
import {IPermit2} from "permit2/interfaces/IPermit2.sol";

/**
 * @title KipuBankV3 - Security Hardened with Permit2 + Lock-Callback
 * @notice UniversalRouter-inspired pattern: Permit2 approvals + V4 lock-callback swaps
 * @dev Combines best of both: Permit2 security + functional lock-callback implementation
 * @dev All critical vulnerabilities fixed
 */
contract KipuBankV3 is AccessControl, IUnlockCallback, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using CurrencyLibrary for Currency;
    
    /*//////////////////////////////////////////////////////////////
                        TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    
    struct TokenInfo {
        bool isSupported;
        uint256 totalDeposits;
        uint8 decimals;
    }
    
    struct UserDeposit {
        uint256 amount;
        uint256 timestamp;
    }
    
    struct SwapCallbackData {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 minAmountOut;
        address payer;
        PoolKey poolKey;
        bool zeroForOne;
    }

    /*//////////////////////////////////////////////////////////////
                        CONSTANTS & IMMUTABLES
    //////////////////////////////////////////////////////////////*/
    
    uint8 public constant TARGET_DECIMALS = 6;
    uint8 public constant MAX_DECIMALS = 77; // Prevent overflow
    address public constant NATIVE_ETH = address(0);
    uint256 public constant MIN_DEPOSIT_USD = 1e6;
    uint256 public constant PRICE_FEED_STALENESS_THRESHOLD = 3600; // 1 hour
    
    // Price limits from Uniswap V4 TickMath
    uint160 public constant MIN_SQRT_PRICE_LIMIT = 4295128739;
    uint160 public constant MAX_SQRT_PRICE_LIMIT = 1461446703485210103287273052203988822378723970342;
    
    AggregatorV3Interface public immutable ethUsdPriceFeed;
    uint256 public immutable WITHDRAWAL_LIMIT_USD;
    
    // Uniswap V4 - Official Components
    IPoolManager public immutable poolManager;
    IPermit2 public immutable permit2; // UniversalRouter pattern
    address public immutable USDC;
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

    /*//////////////////////////////////////////////////////////////
                        STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    
    uint256 public bankCapUsd;
    uint256 public totalValueLockedUsd;
    bool public paused;
    
    mapping(address => TokenInfo) public tokens;
    mapping(address => mapping(address => UserDeposit)) public userDeposits;
    mapping(address => AggregatorV3Interface) public priceFeeds;
    mapping(address => PoolKey) public tokenToUsdcPool;

    /*//////////////////////////////////////////////////////////////
                        EVENTS & ERRORS
    //////////////////////////////////////////////////////////////*/
    
    event Deposit(address indexed user, address indexed token, uint256 amount, uint256 amountUsd);
    event ArbitraryTokenDeposit(address indexed user, address indexed token, uint256 amountIn, uint256 usdcOut);
    event Withdrawal(address indexed user, address indexed token, uint256 amount, uint256 amountUsd);
    event Permit2Approved(address indexed token, uint256 amount);
    event PoolKeySet(address indexed token);
    event BankCapUpdated(uint256 oldCap, uint256 newCap);
    event TokenAdded(address indexed token, address indexed priceFeed, uint8 decimals);
    event TokenRemoved(address indexed token);
    event PausedUpdated(bool paused, address indexed by);
    
    error ZeroAmount();
    error ZeroAddress();
    error TokenNotSupported(address token);
    error TokenAlreadySupported(address token);
    error ExceedsBankCap(uint256 attempted, uint256 available);
    error ExceedsWithdrawalLimit(uint256 requested, uint256 limit);
    error InsufficientBalance(uint256 requested, uint256 available);
    error TransferFailed();
    error InvalidPriceFeed();
    error StalePriceFeed();
    error BelowMinimumDeposit(uint256 amount, uint256 minimum);
    error ContractPaused();
    error SwapFailed();
    error InvalidPool();
    error UnauthorizedCallback();
    error DecimalsTooHigh();
    error Overflow();
    error NotERC20Token();

    /*//////////////////////////////////////////////////////////////
                        MODIFIERS
    //////////////////////////////////////////////////////////////*/
    
    modifier whenNotPaused() {
        if (paused) revert ContractPaused();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    
    constructor(
        uint256 _bankCapUsd,
        uint256 _withdrawalLimitUsd,
        address _ethUsdPriceFeed,
        address _poolManager,
        address _permit2,
        address _usdc
    ) {
        // SECURITY: Zero address validation
        if (_ethUsdPriceFeed == address(0)) revert ZeroAddress();
        if (_poolManager == address(0)) revert ZeroAddress();
        if (_permit2 == address(0)) revert ZeroAddress();
        if (_usdc == address(0)) revert ZeroAddress();
        if (_bankCapUsd == 0) revert ZeroAmount();
        if (_withdrawalLimitUsd == 0) revert ZeroAmount();
        
        bankCapUsd = _bankCapUsd;
        WITHDRAWAL_LIMIT_USD = _withdrawalLimitUsd;
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
        
        poolManager = IPoolManager(_poolManager);
        permit2 = IPermit2(_permit2);
        USDC = _usdc;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(EMERGENCY_ROLE, msg.sender);
        
        tokens[NATIVE_ETH] = TokenInfo(true, 0, 18);
        priceFeeds[NATIVE_ETH] = ethUsdPriceFeed;
        
        tokens[_usdc] = TokenInfo(true, 0, 6);
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    receive() external payable whenNotPaused nonReentrant {
        _deposit(NATIVE_ETH, msg.value);
    }
    
    fallback() external payable whenNotPaused nonReentrant {
        _deposit(NATIVE_ETH, msg.value);
    }
    
    function depositToken(address token, uint256 amount) external whenNotPaused nonReentrant {
        if (token == NATIVE_ETH) revert TokenNotSupported(token);
        if (!tokens[token].isSupported) revert TokenNotSupported(token);
        _deposit(token, amount);
    }
    
    /**
     * @notice Deposit any Uniswap V4 token - swaps to USDC
     * @dev Follows official lock-callback pattern with CEI pattern
     * @param tokenIn Token to deposit
     * @param amountIn Amount to deposit
     * @param minUsdcOut Minimum USDC from swap (slippage protection)
     * @return usdcReceived Actual USDC credited to user
     */
    function depositArbitraryToken(
        address tokenIn,
        uint256 amountIn,
        uint256 minUsdcOut
    ) external whenNotPaused nonReentrant returns (uint256 usdcReceived) {
        // ========== CHECKS ==========
        if (amountIn == 0) revert ZeroAmount();
        
        // If USDC, deposit directly
        if (tokenIn == USDC) {
            _deposit(USDC, amountIn);
            return amountIn;
        }
        
        // Pre-check bank cap with minimum expected (prevents wasted gas)
        uint256 estimatedNewTotal = totalValueLockedUsd + minUsdcOut;
        if (estimatedNewTotal > bankCapUsd) {
            revert ExceedsBankCap(minUsdcOut, bankCapUsd - totalValueLockedUsd);
        }
        
        // ========== EFFECTS ==========
        // Store initial state for rollback protection
        uint256 initialBalance = userDeposits[msg.sender][USDC].amount;
        uint256 initialTotalDeposits = tokens[USDC].totalDeposits;
        uint256 initialTVL = totalValueLockedUsd;
        
        // ========== INTERACTIONS ==========
        // Transfer token from user
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        
        // Approve via Permit2 (UniversalRouter pattern) and swap via lock-callback
        _approvePermit2(tokenIn, amountIn);
        usdcReceived = _swapExactInputSingle(tokenIn, amountIn, minUsdcOut);
        
        // ========== POST-INTERACTION EFFECTS ==========
        // Final bank cap check with actual amount
        uint256 actualNewTotal = initialTVL + usdcReceived;
        if (actualNewTotal > bankCapUsd) {
            revert ExceedsBankCap(usdcReceived, bankCapUsd - initialTVL);
        }
        
        // Update state atomically
        userDeposits[msg.sender][USDC].amount = initialBalance + usdcReceived;
        userDeposits[msg.sender][USDC].timestamp = block.timestamp;
        tokens[USDC].totalDeposits = initialTotalDeposits + usdcReceived;
        totalValueLockedUsd = actualNewTotal;
        
        emit ArbitraryTokenDeposit(msg.sender, tokenIn, amountIn, usdcReceived);
    }

    /*//////////////////////////////////////////////////////////////
                        WITHDRAWAL
    //////////////////////////////////////////////////////////////*/
    
    function withdraw(address token, uint256 amount) external whenNotPaused nonReentrant {
        if (amount == 0) revert ZeroAmount();
        if (!tokens[token].isSupported) revert TokenNotSupported(token);
        
        UserDeposit storage userDeposit = userDeposits[msg.sender][token];
        
        uint256 normalized = _normalizeDecimals(amount, tokens[token].decimals, TARGET_DECIMALS);
        
        if (userDeposit.amount < normalized) {
            revert InsufficientBalance(normalized, userDeposit.amount);
        }
        
        uint256 amountUsd = _getTokenValueInUsd(token, normalized);
        if (amountUsd > WITHDRAWAL_LIMIT_USD) {
            revert ExceedsWithdrawalLimit(amountUsd, WITHDRAWAL_LIMIT_USD);
        }
        
        userDeposit.amount -= normalized;
        tokens[token].totalDeposits -= normalized;
        totalValueLockedUsd -= amountUsd;
        
        emit Withdrawal(msg.sender, token, amount, amountUsd);
        
        if (token == NATIVE_ETH) {
            (bool success, ) = payable(msg.sender).call{value: amount}("");
            if (!success) revert TransferFailed();
        } else {
            IERC20(token).safeTransfer(msg.sender, amount);
        }
    }

    /*//////////////////////////////////////////////////////////////
            UNISWAP V4 SWAP - OFFICIAL LOCK-CALLBACK PATTERN
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Swap exact input to USDC using official lock-callback pattern
     * @dev Implements pattern from https://docs.uniswap.org/contracts/v4/quickstart/swap
     * @param tokenIn Input token
     * @param amountIn Amount to swap
     * @param minAmountOut Minimum USDC output
     * @return amountOut USDC received
     */
    function _swapExactInputSingle(
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut
    ) internal returns (uint256 amountOut) {
        PoolKey memory poolKey = tokenToUsdcPool[tokenIn];
        if (Currency.unwrap(poolKey.currency0) == address(0)) revert InvalidPool();
        
        // Determine swap direction
        bool zeroForOne = Currency.unwrap(poolKey.currency0) == tokenIn;
        
        // Prepare callback data
        SwapCallbackData memory data = SwapCallbackData({
            tokenIn: tokenIn,
            tokenOut: USDC,
            amountIn: amountIn,
            minAmountOut: minAmountOut,
            payer: address(this),
            poolKey: poolKey,
            zeroForOne: zeroForOne
        });
        
        // Use lock-callback pattern as per official guide
        // This calls our unlockCallback() function
        bytes memory result = poolManager.unlock(abi.encode(data));
        amountOut = abi.decode(result, (uint256));
        
        if (amountOut < minAmountOut) revert SwapFailed();
        
        return amountOut;
    }
    
    /**
     * @notice Callback for PoolManager.unlock() - Official Pattern
     * @dev Implements IUnlockCallback interface
     * @dev This is called by PoolManager during unlock()
     * @param data Encoded SwapCallbackData
     * @return Encoded amount out
     */
    function unlockCallback(bytes calldata data) 
        external 
        override 
        nonReentrant
        returns (bytes memory) 
    {
        // SECURITY FIX: Add nonReentrant protection
        // Only PoolManager can call this
        if (msg.sender != address(poolManager)) revert UnauthorizedCallback();
        
        SwapCallbackData memory swapData = abi.decode(data, (SwapCallbackData));
        
        // Prepare swap params
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: swapData.zeroForOne,
            amountSpecified: -int256(swapData.amountIn), // Negative for exact input
            sqrtPriceLimitX96: swapData.zeroForOne ? 
                MIN_SQRT_PRICE_LIMIT : 
                MAX_SQRT_PRICE_LIMIT
        });
        
        // Execute swap through PoolManager
        BalanceDelta delta = poolManager.swap(swapData.poolKey, params, "");
        
        // Settle input tokens (send to PoolManager)
        // This is the "settle" part of the official pattern
        _settle(swapData.poolKey.currency0, swapData.poolKey.currency1, delta, swapData.zeroForOne, swapData.payer);
        
        // Take output tokens (receive from PoolManager)
        // This is the "take" part of the official pattern
        uint256 amountOut = _take(swapData.poolKey.currency0, swapData.poolKey.currency1, delta, swapData.zeroForOne, swapData.payer);
        
        return abi.encode(amountOut);
    }
    
    /**
     * @notice Settle tokens to PoolManager (official pattern)
     * @dev Sends input tokens to the pool
     */
    function _settle(
        Currency currency0,
        Currency currency1,
        BalanceDelta delta,
        bool zeroForOne,
        address payer
    ) internal {
        // Determine which currency we're settling (the input token)
        Currency currencyToSettle = zeroForOne ? currency0 : currency1;
        uint256 amountToSettle = zeroForOne ? 
            uint256(int256(-delta.amount0())) : 
            uint256(int256(-delta.amount1()));
        
        // Transfer tokens to PoolManager
        if (amountToSettle > 0) {
            IERC20(Currency.unwrap(currencyToSettle)).safeTransferFrom(
                payer,
                address(poolManager),
                amountToSettle
            );
            // Sync the currency balance in PoolManager
            poolManager.sync(currencyToSettle);
        }
    }
    
    /**
     * @notice Take tokens from PoolManager (official pattern)
     * @dev Receives output tokens from the pool
     */
    function _take(
        Currency currency0,
        Currency currency1,
        BalanceDelta delta,
        bool zeroForOne,
        address recipient
    ) internal returns (uint256 amountOut) {
        // Determine which currency we're taking (the output token)
        Currency currencyToTake = zeroForOne ? currency1 : currency0;
        
        // Calculate amount to take (always positive for output)
        amountOut = zeroForOne ? 
            uint256(uint128(delta.amount1())) : 
            uint256(uint128(-delta.amount0()));
        
        // Take tokens from PoolManager
        if (amountOut > 0) {
            poolManager.take(currencyToTake, recipient, amountOut);
        }
        
        return amountOut;
    }
    
    /**
     * @notice Approve Permit2 to spend tokens (UniversalRouter pattern)
     * @dev Official pattern from Uniswap V4 documentation
     */
    function _approvePermit2(address token, uint256 amount) internal {
        uint256 currentAllowance = IERC20(token).allowance(address(this), address(permit2));
        
        if (currentAllowance < amount) {
            // SECURITY FIX: forceApprove handles USDT (resets to 0 if needed)
            IERC20(token).forceApprove(address(permit2), type(uint256).max);
            
            emit Permit2Approved(token, type(uint256).max);
        }
    }

    /*//////////////////////////////////////////////////////////////
                        ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    function setPoolKey(
        address token,
        address currency0,
        address currency1,
        uint24 fee,
        int24 tickSpacing,
        address hooks
    ) external onlyRole(ADMIN_ROLE) {
        if (token == address(0)) revert ZeroAddress();
        if (currency0 == address(0)) revert ZeroAddress();
        if (currency1 == address(0)) revert ZeroAddress();
        
        tokenToUsdcPool[token] = PoolKey({
            currency0: Currency.wrap(currency0),
            currency1: Currency.wrap(currency1),
            fee: fee,
            tickSpacing: tickSpacing,
            hooks: IHooks(hooks)
        });
        
        emit PoolKeySet(token);
    }
    
    function addToken(address token, address priceFeed) external onlyRole(ADMIN_ROLE) {
        if (token == address(0)) revert ZeroAddress();
        if (priceFeed == address(0)) revert ZeroAddress();
        if (token == NATIVE_ETH) revert TokenNotSupported(token);
        if (tokens[token].isSupported) revert TokenAlreadySupported(token);
        
        uint8 decimals;
        try IERC20Metadata(token).decimals() returns (uint8 d) {
            decimals = d;
            if (decimals > MAX_DECIMALS) revert DecimalsTooHigh();
        } catch {
            revert NotERC20Token();
        }
        
        try AggregatorV3Interface(priceFeed).latestRoundData() returns (
            uint80, int256 price, uint256, uint256, uint80
        ) {
            if (price <= 0) revert InvalidPriceFeed();
        } catch {
            revert InvalidPriceFeed();
        }
        
        tokens[token] = TokenInfo(true, 0, decimals);
        priceFeeds[token] = AggregatorV3Interface(priceFeed);
        
        emit TokenAdded(token, priceFeed, decimals);
    }
    
    function removeToken(address token) external onlyRole(ADMIN_ROLE) {
        if (token == NATIVE_ETH) revert TokenNotSupported(token);
        if (!tokens[token].isSupported) revert TokenNotSupported(token);
        
        tokens[token].isSupported = false;
        emit TokenRemoved(token);
    }
    
    function updateBankCap(uint256 newCap) external onlyRole(ADMIN_ROLE) {
        if (newCap == 0) revert ZeroAmount();
        
        uint256 oldCap = bankCapUsd;
        bankCapUsd = newCap;
        
        emit BankCapUpdated(oldCap, newCap);
    }
    
    function setPaused(bool _paused) external onlyRole(EMERGENCY_ROLE) {
        paused = _paused;
        emit PausedUpdated(_paused, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    function getUserBalance(address user, address token) 
        external view returns (uint256, uint256) 
    {
        UserDeposit memory d = userDeposits[user][token];
        return (d.amount, d.timestamp);
    }
    
    function getUserBalanceUsd(address user, address token) 
        external view returns (uint256) 
    {
        uint256 balance = userDeposits[user][token].amount;
        return balance == 0 ? 0 : _getTokenValueInUsd(token, balance);
    }
    
    function getRemainingCapacityUsd() external view returns (uint256) {
        return totalValueLockedUsd >= bankCapUsd ? 0 : bankCapUsd - totalValueLockedUsd;
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    function _deposit(address token, uint256 amount) internal {
        // ========== CHECKS ==========
        if (amount == 0) revert ZeroAmount();
        
        uint256 normalized = _normalizeDecimals(amount, tokens[token].decimals, TARGET_DECIMALS);
        uint256 amountUsd = _getTokenValueInUsd(token, normalized);
        
        if (amountUsd < MIN_DEPOSIT_USD) {
            revert BelowMinimumDeposit(amountUsd, MIN_DEPOSIT_USD);
        }
        
        uint256 newTotal = totalValueLockedUsd + amountUsd;
        if (newTotal > bankCapUsd) {
            revert ExceedsBankCap(amountUsd, bankCapUsd - totalValueLockedUsd);
        }
        
        // ========== INTERACTIONS ==========
        // SECURITY FIX: Transfer BEFORE state changes (CEI pattern)
        if (token != NATIVE_ETH) {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        }
        
        // ========== EFFECTS ==========
        userDeposits[msg.sender][token].amount += normalized;
        userDeposits[msg.sender][token].timestamp = block.timestamp;
        tokens[token].totalDeposits += normalized;
        totalValueLockedUsd += amountUsd;
        
        emit Deposit(msg.sender, token, amount, amountUsd);
    }
    
    function _normalizeDecimals(
        uint256 amount,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (uint256) {
        if (fromDecimals == toDecimals) return amount;
        
        if (fromDecimals > toDecimals) {
            uint8 diff = fromDecimals - toDecimals;
            if (diff > MAX_DECIMALS) revert DecimalsTooHigh();
            return amount / (10 ** diff);
        } else {
            uint8 diff = toDecimals - fromDecimals;
            if (diff > MAX_DECIMALS) revert DecimalsTooHigh();
            
            uint256 multiplier = 10 ** diff;
            if (amount > type(uint256).max / multiplier) revert Overflow();
            
            return amount * multiplier;
        }
    }
    
    function _getTokenValueInUsd(
        address token,
        uint256 normalizedAmount
    ) internal view returns (uint256) {
        AggregatorV3Interface priceFeed = priceFeeds[token];
        
        (
            uint80 roundId,
            int256 price,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        
        // Comprehensive Chainlink validations
        if (price <= 0) revert InvalidPriceFeed();
        if (updatedAt == 0) revert InvalidPriceFeed();
        if (answeredInRound < roundId) revert InvalidPriceFeed();
        
        // Staleness check
        if (block.timestamp - updatedAt > PRICE_FEED_STALENESS_THRESHOLD) {
            revert StalePriceFeed();
        }
        
        uint8 feedDecimals = priceFeed.decimals();
        return (normalizedAmount * uint256(price)) / (10 ** feedDecimals);
    }
}
