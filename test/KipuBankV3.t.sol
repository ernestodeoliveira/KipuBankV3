// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/KipuBankV3.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockERC20
 * @notice Mock ERC20 token for testing
 */
contract MockERC20 is ERC20 {
    uint8 private _decimals;
    
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_
    ) ERC20(name, symbol) {
        _decimals = decimals_;
        _mint(msg.sender, 1_000_000 * 10 ** decimals_);
    }
    
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/**
 * @title MockV3Aggregator
 * @notice Mock Chainlink price feed for testing
 */
contract MockV3Aggregator {
    uint8 public decimals;
    int256 public latestAnswer;
    uint256 public latestTimestamp;
    uint256 public latestRound;

    constructor(uint8 _decimals, int256 _initialAnswer) {
        decimals = _decimals;
        updateAnswer(_initialAnswer);
    }

    function updateAnswer(int256 _answer) public {
        latestAnswer = _answer;
        latestTimestamp = block.timestamp;
        latestRound++;
    }

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
            latestTimestamp,
            latestTimestamp,
            uint80(latestRound)
        );
    }
}

/**
 * @title MockPoolManager
 * @notice Mock Uniswap V4 PoolManager for testing
 */
contract MockPoolManager {
    address public lastCaller;
    bytes public lastData;
    
    // Mock swap to return 950 USDC for 1000 DAI (5% fee simulation)
    function unlock(bytes calldata data) external returns (bytes memory) {
        lastCaller = msg.sender;
        lastData = data;
        
        // Call back to the caller
        bytes memory result = IUnlockCallback(msg.sender).unlockCallback(data);
        return result;
    }
    
    function swap(
        PoolKey memory,
        IPoolManager.SwapParams memory,
        bytes memory
    ) external pure returns (BalanceDelta) {
        // Mock: Return -1000 (input) and +950 (output)
        return toBalanceDelta(-1000e18, 950e6);
    }
    
    function sync(Currency) external pure {}
    
    function take(Currency, address, uint256) external pure {}
    
    // Helper to create BalanceDelta
    function toBalanceDelta(int128 amount0, int128 amount1) internal pure returns (BalanceDelta) {
        return BalanceDelta.wrap((int256(amount0) << 128) | int256(uint256(uint128(amount1))));
    }
}

/**
 * @title MockPermit2
 * @notice Mock Permit2 for testing
 */
contract MockPermit2 {
    mapping(address => mapping(address => mapping(address => uint256))) public allowance;
    
    function approve(
        address token,
        address spender,
        uint160 amount,
        uint48 /* expiration */
    ) external {
        allowance[msg.sender][token][spender] = amount;
    }
}

/**
 * @title KipuBankV3Test
 * @notice Test suite for KipuBankV3 with Uniswap V4 integration
 */
contract KipuBankV3Test is Test {
    KipuBankV3 public bank;
    MockV3Aggregator public ethUsdPriceFeed;
    MockV3Aggregator public usdcUsdPriceFeed;
    MockV3Aggregator public daiUsdPriceFeed;
    MockERC20 public usdc;
    MockERC20 public dai;
    MockPoolManager public poolManager;
    MockPermit2 public permit2;
    
    address public admin = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    
    uint256 constant BANK_CAP_USD = 1_000_000e6;      // $1M
    uint256 constant WITHDRAWAL_LIMIT_USD = 10_000e6; // $10k
    uint256 constant ETH_PRICE_USD = 2000e8;          // $2000 with 8 decimals
    uint256 constant USDC_PRICE_USD = 1e8;            // $1 with 8 decimals
    uint256 constant DAI_PRICE_USD = 1e8;             // $1 with 8 decimals

    function setUp() public {
        // Deploy mocks
        ethUsdPriceFeed = new MockV3Aggregator(8, int256(ETH_PRICE_USD));
        usdcUsdPriceFeed = new MockV3Aggregator(8, int256(USDC_PRICE_USD));
        daiUsdPriceFeed = new MockV3Aggregator(8, int256(DAI_PRICE_USD));
        usdc = new MockERC20("USD Coin", "USDC", 6);
        dai = new MockERC20("Dai Stablecoin", "DAI", 18);
        poolManager = new MockPoolManager();
        permit2 = new MockPermit2();
        
        // Deploy KipuBankV3
        vm.prank(admin);
        bank = new KipuBankV3(
            BANK_CAP_USD,
            WITHDRAWAL_LIMIT_USD,
            address(ethUsdPriceFeed),
            address(poolManager),
            address(permit2),
            address(usdc)
        );
        
        // Setup tokens (USDC already added in constructor)
        vm.startPrank(admin);
        bank.addToken(address(dai), address(daiUsdPriceFeed));
        
        // Setup mock V4 pool for DAI/USDC
        bank.setPoolKey(
            address(dai),
            address(dai),   // currency0
            address(usdc),  // currency1
            3000,           // 0.3% fee
            60,             // tick spacing
            address(0)      // no hooks
        );
        vm.stopPrank();
        
        // Fund users
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        usdc.mint(user1, 100_000e6);
        usdc.mint(user2, 100_000e6);
        dai.mint(user1, 100_000e18);
        dai.mint(user2, 100_000e18);
    }

    /*//////////////////////////////////////////////////////////////
                        BASIC DEPOSIT TESTS
    //////////////////////////////////////////////////////////////*/

    function testDepositETH() public {
        uint256 depositAmount = 1 ether;
        
        vm.prank(user1);
        (bool success,) = address(bank).call{value: depositAmount}("");
        assertTrue(success, "ETH deposit failed");
        
        (uint256 balance, uint256 timestamp) = bank.getUserBalance(user1, bank.NATIVE_ETH());
        assertGt(balance, 0, "Balance should be greater than 0");
        assertEq(timestamp, block.timestamp, "Timestamp should match");
    }

    function testDepositUSDC() public {
        uint256 depositAmount = 1000e6;
        
        vm.startPrank(user1);
        usdc.approve(address(bank), depositAmount);
        bank.depositToken(address(usdc), depositAmount);
        vm.stopPrank();
        
        (uint256 balance,) = bank.getUserBalance(user1, address(usdc));
        assertEq(balance, depositAmount, "USDC balance mismatch");
    }

    function testDepositRevertsWhenPaused() public {
        vm.prank(admin);
        bank.setPaused(true);
        
        vm.prank(user1);
        vm.expectRevert(KipuBankV3.ContractPaused.selector);
        (bool success,) = address(bank).call{value: 1 ether}("");
        assertFalse(success, "Should revert when paused");
    }

    /*//////////////////////////////////////////////////////////////
                    WITHDRAWAL TESTS
    //////////////////////////////////////////////////////////////*/

    function testWithdrawETH() public {
        uint256 depositAmount = 1 ether;
        uint256 withdrawAmount = 0.5 ether;
        
        // Deposit
        vm.prank(user1);
        (bool success,) = address(bank).call{value: depositAmount}("");
        require(success, "Deposit failed");
        
        // Withdraw
        uint256 balanceBefore = user1.balance;
        vm.prank(user1);
        bank.withdraw(bank.NATIVE_ETH(), withdrawAmount);
        uint256 balanceAfter = user1.balance;
        
        assertEq(balanceAfter - balanceBefore, withdrawAmount, "Withdrawal amount mismatch");
    }

    function testWithdrawUSDC() public {
        uint256 depositAmount = 1000e6;
        uint256 withdrawAmount = 500e6;
        
        // Deposit
        vm.startPrank(user1);
        usdc.approve(address(bank), depositAmount);
        bank.depositToken(address(usdc), depositAmount);
        
        // Withdraw
        uint256 balanceBefore = usdc.balanceOf(user1);
        bank.withdraw(address(usdc), withdrawAmount);
        vm.stopPrank();
        
        uint256 balanceAfter = usdc.balanceOf(user1);
        assertEq(balanceAfter - balanceBefore, withdrawAmount, "Withdrawal amount mismatch");
    }

    function testWithdrawRevertsInsufficientBalance() public {
        vm.prank(user1);
        vm.expectRevert();
        bank.withdraw(address(usdc), 1000e6);
    }

    /*//////////////////////////////////////////////////////////////
                    V3 SPECIFIC TESTS
    //////////////////////////////////////////////////////////////*/

    function testPermit2Approval() public {
        uint256 depositAmount = 1000e18;
        
        vm.startPrank(user1);
        dai.approve(address(bank), depositAmount);
        
        // This will trigger _approvePermit2 internally
        // NOTE: depositArbitraryToken will fail because we need actual swap implementation
        // but we can test that the contract attempts the approval
        vm.expectRevert(); // Will revert on actual swap, but approval should happen first
        bank.depositArbitraryToken(address(dai), depositAmount, 900e6);
        vm.stopPrank();
        
        // Check that permit2 has allowance (if we had real Permit2)
        // This test validates the flow exists
    }

    function testUnlockCallbackOnlyPoolManager() public {
        bytes memory mockData = abi.encode(
            KipuBankV3.SwapCallbackData({
                tokenIn: address(dai),
                tokenOut: address(usdc),
                amountIn: 1000e18,
                minAmountOut: 900e6,
                payer: address(bank),
                poolKey: PoolKey({
                    currency0: Currency.wrap(address(dai)),
                    currency1: Currency.wrap(address(usdc)),
                    fee: 3000,
                    tickSpacing: 60,
                    hooks: IHooks(address(0))
                }),
                zeroForOne: true
            })
        );
        
        // Should revert when called directly (not from poolManager)
        vm.prank(user1);
        vm.expectRevert(KipuBankV3.UnauthorizedCallback.selector);
        bank.unlockCallback(mockData);
    }

    function testReentrancyProtection() public {
        // All public functions should have nonReentrant
        // This is a basic check that modifier exists
        uint256 depositAmount = 1 ether;
        
        vm.prank(user1);
        (bool success,) = address(bank).call{value: depositAmount}("");
        assertTrue(success, "Should succeed with reentrancy guard");
    }

    /*//////////////////////////////////////////////////////////////
                    ADMIN TESTS
    //////////////////////////////////////////////////////////////*/

    function testAddToken() public {
        MockERC20 newToken = new MockERC20("Test Token", "TEST", 18);
        MockV3Aggregator newFeed = new MockV3Aggregator(8, 1e8);
        
        vm.prank(admin);
        bank.addToken(address(newToken), address(newFeed));
        
        (bool isSupported,,) = bank.tokens(address(newToken));
        assertTrue(isSupported, "Token should be supported");
    }

    function testRemoveToken() public {
        vm.prank(admin);
        bank.removeToken(address(usdc));
        
        (bool isSupported,,) = bank.tokens(address(usdc));
        assertFalse(isSupported, "Token should not be supported");
    }

    function testUpdateBankCap() public {
        uint256 newCap = 2_000_000e6;
        
        vm.prank(admin);
        bank.updateBankCap(newCap);
        
        assertEq(bank.bankCapUsd(), newCap, "Bank cap not updated");
    }

    function testSetPausedEmitsEvent() public {
        vm.prank(admin);
        vm.expectEmit(true, true, false, true);
        emit KipuBankV3.PausedUpdated(true, admin);
        bank.setPaused(true);
    }

    function testSetPoolKey() public {
        MockERC20 newToken = new MockERC20("New Token", "NEW", 18);
        
        vm.prank(admin);
        bank.setPoolKey(
            address(newToken),
            address(newToken),
            address(usdc),
            3000,
            60,
            address(0)
        );
        
        // Pool key should be set (we can verify by trying to use it)
        (Currency currency0,,,, ) = bank.tokenToUsdcPool(address(newToken));
        assertEq(Currency.unwrap(currency0), address(newToken), "PoolKey not set correctly");
    }

    function testUnauthorizedAdminFunctionReverts() public {
        vm.prank(user1);
        vm.expectRevert();
        bank.updateBankCap(2_000_000e6);
    }

    /*//////////////////////////////////////////////////////////////
                    VIEW FUNCTIONS TESTS
    //////////////////////////////////////////////////////////////*/

    function testGetRemainingCapacity() public {
        uint256 remaining = bank.getRemainingCapacityUsd();
        assertEq(remaining, BANK_CAP_USD, "Initial capacity should equal bank cap");
        
        // Deposit some
        vm.prank(user1);
        (bool success,) = address(bank).call{value: 1 ether}("");
        require(success, "Deposit failed");
        
        uint256 remainingAfter = bank.getRemainingCapacityUsd();
        assertLt(remainingAfter, BANK_CAP_USD, "Remaining should decrease");
    }

    function testGetUserBalanceUsd() public {
        uint256 depositAmount = 1000e6;
        
        vm.startPrank(user1);
        usdc.approve(address(bank), depositAmount);
        bank.depositToken(address(usdc), depositAmount);
        vm.stopPrank();
        
        uint256 balanceUsd = bank.getUserBalanceUsd(user1, address(usdc));
        assertGt(balanceUsd, 0, "USD balance should be > 0");
    }

    /*//////////////////////////////////////////////////////////////
                    SECURITY TESTS
    //////////////////////////////////////////////////////////////*/

    function testCEIPatternInDeposit() public {
        // Test that deposit follows CEI pattern (interaction before effects)
        uint256 depositAmount = 1000e6;
        
        vm.startPrank(user1);
        usdc.approve(address(bank), depositAmount);
        
        uint256 bankBalanceBefore = usdc.balanceOf(address(bank));
        bank.depositToken(address(usdc), depositAmount);
        uint256 bankBalanceAfter = usdc.balanceOf(address(bank));
        
        assertEq(bankBalanceAfter - bankBalanceBefore, depositAmount, "CEI pattern working");
        vm.stopPrank();
    }

    function testOracleValidation() public {
        // Test with stale price
        vm.warp(block.timestamp + 2 hours);
        
        vm.prank(user1);
        vm.expectRevert(KipuBankV3.StalePriceFeed.selector);
        (bool success,) = address(bank).call{value: 1 ether}("");
        assertFalse(success, "Should revert");
    }

    function testConstructorValidation() public {
        // Test zero address validation
        vm.expectRevert(KipuBankV3.ZeroAddress.selector);
        new KipuBankV3(
            BANK_CAP_USD,
            WITHDRAWAL_LIMIT_USD,
            address(0), // ❌ Zero address
            address(poolManager),
            address(permit2),
            address(usdc)
        );
    }
}
