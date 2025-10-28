// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title KipuBank - Simplified Version
 * @author Ernesto de Oliveira
 * @notice Decentralized bank with multi-token support and USD-based limits
 * @dev Implements all required exam features in a simplified way
 */
contract KipuBank is AccessControl {
    
    /*//////////////////////////////////////////////////////////////
                        TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Token information
    struct TokenInfo {
        bool isSupported;
        uint256 totalDeposits;  // Normalized to 6 decimals
        uint8 decimals;
    }
    
    /// @notice User deposit information
    struct UserDeposit {
        uint256 amount;         // Normalized to 6 decimals
        uint256 timestamp;
    }

    /*//////////////////////////////////////////////////////////////
                        CONSTANTS & IMMUTABLES
    //////////////////////////////////////////////////////////////*/
    
    // CONSTANTS
    uint8 public constant TARGET_DECIMALS = 6;
    address public constant NATIVE_ETH = address(0);
    uint256 public constant MIN_DEPOSIT_USD = 1e6; // $1 USD
    
    // IMMUTABLES
    AggregatorV3Interface public immutable ethUsdPriceFeed;
    uint256 public immutable WITHDRAWAL_LIMIT_USD;
    
    // ROLES
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

    /*//////////////////////////////////////////////////////////////
                        STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    
    uint256 public bankCapUsd;
    uint256 public totalValueLockedUsd;
    bool public paused;
    
    /*//////////////////////////////////////////////////////////////
                        MAPPINGS (NESTED)
    //////////////////////////////////////////////////////////////*/
    
    mapping(address => TokenInfo) public tokens;
    mapping(address => mapping(address => UserDeposit)) public userDeposits;
    mapping(address => AggregatorV3Interface) public priceFeeds;

    /*//////////////////////////////////////////////////////////////
                        EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event Deposit(address indexed user, address indexed token, uint256 amount, uint256 amountUsd);
    event Withdrawal(address indexed user, address indexed token, uint256 amount, uint256 amountUsd);
    event TokenAdded(address indexed token, address indexed priceFeed);

    /*//////////////////////////////////////////////////////////////
                        ERRORS
    //////////////////////////////////////////////////////////////*/
    
    error ZeroAmount();
    error TokenNotSupported(address token);
    error ExceedsBankCap(uint256 attempted, uint256 available);
    error ExceedsWithdrawalLimit(uint256 requested, uint256 limit);
    error InsufficientBalance(uint256 requested, uint256 available);
    error TransferFailed();
    error InvalidPriceFeed();
    error BelowMinimumDeposit(uint256 amount, uint256 minimum);
    error ContractPaused();

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
        address _ethUsdPriceFeed
    ) {
        bankCapUsd = _bankCapUsd;
        WITHDRAWAL_LIMIT_USD = _withdrawalLimitUsd;
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
        
        // Setup roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(EMERGENCY_ROLE, msg.sender);
        
        // Setup native ETH
        tokens[NATIVE_ETH] = TokenInfo({
            isSupported: true,
            totalDeposits: 0,
            decimals: 18
        });
        priceFeeds[NATIVE_ETH] = ethUsdPriceFeed;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Deposit native ETH
    receive() external payable whenNotPaused {
        _deposit(NATIVE_ETH, msg.value);
    }
    
    fallback() external payable whenNotPaused {
        _deposit(NATIVE_ETH, msg.value);
    }
    
    /// @notice Deposit ERC20 tokens
    function depositToken(address token, uint256 amount) external whenNotPaused {
        if (token == NATIVE_ETH) revert TokenNotSupported(token);
        if (!tokens[token].isSupported) revert TokenNotSupported(token);
        _deposit(token, amount);
    }

    /*//////////////////////////////////////////////////////////////
                        WITHDRAWAL FUNCTION
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Withdraw tokens
    function withdraw(address token, uint256 amount) external whenNotPaused {
        if (amount == 0) revert ZeroAmount();
        if (!tokens[token].isSupported) revert TokenNotSupported(token);
        
        UserDeposit storage userDeposit = userDeposits[msg.sender][token];
        
        // Normalize amount
        uint256 normalizedAmount = _normalizeDecimals(
            amount,
            tokens[token].decimals,
            TARGET_DECIMALS
        );
        
        // Check balance
        if (userDeposit.amount < normalizedAmount) {
            revert InsufficientBalance(normalizedAmount, userDeposit.amount);
        }
        
        // Check withdrawal limit
        uint256 amountUsd = _getTokenValueInUsd(token, normalizedAmount);
        if (amountUsd > WITHDRAWAL_LIMIT_USD) {
            revert ExceedsWithdrawalLimit(amountUsd, WITHDRAWAL_LIMIT_USD);
        }
        
        // Effects
        userDeposit.amount -= normalizedAmount;
        tokens[token].totalDeposits -= normalizedAmount;
        totalValueLockedUsd -= amountUsd;
        
        emit Withdrawal(msg.sender, token, amount, amountUsd);
        
        // Interactions
        if (token == NATIVE_ETH) {
            (bool success, ) = payable(msg.sender).call{value: amount}("");
            if (!success) revert TransferFailed();
        } else {
            bool success = IERC20(token).transfer(msg.sender, amount);
            if (!success) revert TransferFailed();
        }
    }

    /*//////////////////////////////////////////////////////////////
                        ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Add new token support
    function addToken(address token, address priceFeed) external onlyRole(ADMIN_ROLE) {
        if (tokens[token].isSupported) revert TokenNotSupported(token);
        
        uint8 decimals = IERC20Metadata(token).decimals();
        
        tokens[token] = TokenInfo({
            isSupported: true,
            totalDeposits: 0,
            decimals: decimals
        });
        
        priceFeeds[token] = AggregatorV3Interface(priceFeed);
        
        emit TokenAdded(token, priceFeed);
    }
    
    /// @notice Remove token support
    function removeToken(address token) external onlyRole(ADMIN_ROLE) {
        if (token == NATIVE_ETH) revert TokenNotSupported(token);
        tokens[token].isSupported = false;
    }
    
    /// @notice Update bank capacity
    function updateBankCap(uint256 newCapUsd) external onlyRole(ADMIN_ROLE) {
        bankCapUsd = newCapUsd;
    }
    
    /// @notice Emergency pause/unpause
    function setPaused(bool _paused) external onlyRole(EMERGENCY_ROLE) {
        paused = _paused;
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Get user balance
    function getUserBalance(address user, address token) 
        external 
        view 
        returns (uint256 balance, uint256 timestamp) 
    {
        UserDeposit memory deposit = userDeposits[user][token];
        return (deposit.amount, deposit.timestamp);
    }
    
    /// @notice Get user balance in USD
    function getUserBalanceUsd(address user, address token) 
        external 
        view 
        returns (uint256) 
    {
        uint256 balance = userDeposits[user][token].amount;
        if (balance == 0) return 0;
        return _getTokenValueInUsd(token, balance);
    }
    
    /// @notice Convert token amount to USD
    function convertToUsd(address token, uint256 amount) 
        external 
        view 
        returns (uint256) 
    {
        uint256 normalizedAmount = _normalizeDecimals(
            amount,
            tokens[token].decimals,
            TARGET_DECIMALS
        );
        return _getTokenValueInUsd(token, normalizedAmount);
    }
    
    /// @notice Get remaining capacity
    function getRemainingCapacityUsd() external view returns (uint256) {
        if (totalValueLockedUsd >= bankCapUsd) return 0;
        return bankCapUsd - totalValueLockedUsd;
    }
    
    /// @notice Get current ETH price
    function getEthPrice() external view returns (uint256 price) {
        (, int256 answer, , , ) = ethUsdPriceFeed.latestRoundData();
        return uint256(answer);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Internal deposit logic
    function _deposit(address token, uint256 amount) internal {
        if (amount == 0) revert ZeroAmount();
        
        // Normalize amount
        uint256 normalizedAmount = _normalizeDecimals(
            amount,
            tokens[token].decimals,
            TARGET_DECIMALS
        );
        
        // Get USD value
        uint256 amountUsd = _getTokenValueInUsd(token, normalizedAmount);
        
        // Check minimum
        if (amountUsd < MIN_DEPOSIT_USD) {
            revert BelowMinimumDeposit(amountUsd, MIN_DEPOSIT_USD);
        }
        
        // Check capacity
        uint256 newTotalUsd = totalValueLockedUsd + amountUsd;
        if (newTotalUsd > bankCapUsd) {
            revert ExceedsBankCap(amountUsd, bankCapUsd - totalValueLockedUsd);
        }
        
        // Effects
        userDeposits[msg.sender][token].amount += normalizedAmount;
        userDeposits[msg.sender][token].timestamp = block.timestamp;
        tokens[token].totalDeposits += normalizedAmount;
        totalValueLockedUsd += amountUsd;
        
        emit Deposit(msg.sender, token, amount, amountUsd);
        
        // Interactions (only for ERC20)
        if (token != NATIVE_ETH) {
            bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
            if (!success) revert TransferFailed();
        }
    }
    
    /// @notice Normalize decimals between different precisions
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
    
    /// @notice Get token value in USD (simplified oracle validation)
    function _getTokenValueInUsd(
        address token,
        uint256 normalizedAmount
    ) internal view returns (uint256) {
        AggregatorV3Interface priceFeed = priceFeeds[token];
        
        (, int256 price, , , ) = priceFeed.latestRoundData();
        
        // Simple validation
        if (price <= 0) revert InvalidPriceFeed();
        
        uint8 priceFeedDecimals = priceFeed.decimals();
        uint256 valueUsd = (normalizedAmount * uint256(price)) / (10 ** priceFeedDecimals);
        
        return valueUsd;
    }
}
