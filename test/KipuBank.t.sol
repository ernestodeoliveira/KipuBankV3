// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/KipuBank.sol";
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
 * @title KipuBankTest
 * @notice Test suite for KipuBank contract
 */
contract KipuBankTest is Test {
    KipuBank public bank;
    MockV3Aggregator public ethUsdPriceFeed;
    MockV3Aggregator public usdcUsdPriceFeed;
    MockERC20 public usdc;
    
    address public admin = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    
    uint256 constant BANK_CAP_USD = 1_000_000e6;      // $1M
    uint256 constant WITHDRAWAL_LIMIT_USD = 10_000e6; // $10k
    uint256 constant ETH_PRICE_USD = 2000e8;          // $2000 with 8 decimals
    uint256 constant USDC_PRICE_USD = 1e8;            // $1 with 8 decimals

    function setUp() public {
        // Deploy mocks
        ethUsdPriceFeed = new MockV3Aggregator(8, int256(ETH_PRICE_USD));
        usdcUsdPriceFeed = new MockV3Aggregator(8, int256(USDC_PRICE_USD));
        usdc = new MockERC20("USD Coin", "USDC", 6);
        
        // Deploy KipuBank
        vm.prank(admin);
        bank = new KipuBank(
            BANK_CAP_USD,
            WITHDRAWAL_LIMIT_USD,
            address(ethUsdPriceFeed)
        );
        
        // Add USDC support
        vm.prank(admin);
        bank.addToken(address(usdc), address(usdcUsdPriceFeed));
        
        // Fund test users
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        
        usdc.transfer(user1, 100_000e6);
        usdc.transfer(user2, 100_000e6);
    }

    /*//////////////////////////////////////////////////////////////
                            DEPOSIT TESTS
    //////////////////////////////////////////////////////////////*/

    function testDepositETH() public {
        uint256 depositAmount = 1 ether;
        
        vm.prank(user1);
        (bool success, ) = address(bank).call{value: depositAmount}("");
        
        assertTrue(success);
        
        (uint256 balance, ) = bank.getUserBalance(user1, bank.NATIVE_ETH());
        assertGt(balance, 0);
    }
    
    function testDepositERC20() public {
        uint256 depositAmount = 1000e6; // 1000 USDC
        
        vm.startPrank(user1);
        usdc.approve(address(bank), depositAmount);
        bank.depositToken(address(usdc), depositAmount);
        vm.stopPrank();
        
        (uint256 balance, ) = bank.getUserBalance(user1, address(usdc));
        assertEq(balance, depositAmount);
    }
    
    function testDepositBelowMinimum() public {
        uint256 depositAmount = 0.0001 ether; // Very small amount
        
        vm.prank(user1);
        vm.expectRevert();
        (bool success, ) = address(bank).call{value: depositAmount}("");
    }
    
    function testDepositExceedsBankCap() public {
        // Try to deposit more than bank cap
        uint256 largeAmount = 600 ether; // More than $1M at $2k/ETH
        
        vm.prank(user1);
        vm.expectRevert();
        (bool success, ) = address(bank).call{value: largeAmount}("");
    }

    /*//////////////////////////////////////////////////////////////
                            WITHDRAWAL TESTS
    //////////////////////////////////////////////////////////////*/

    function testWithdrawETH() public {
        uint256 depositAmount = 1 ether;
        uint256 withdrawAmount = 0.5 ether;
        
        vm.startPrank(user1);
        
        // Deposit first
        (bool success, ) = address(bank).call{value: depositAmount}("");
        assertTrue(success);
        
        // Verify deposit
        (uint256 balance,) = bank.getUserBalance(user1, bank.NATIVE_ETH());
        assertGt(balance, 0, "Balance should be greater than 0");
        
        // Withdraw
        uint256 balanceBefore = user1.balance;
        bank.withdraw(bank.NATIVE_ETH(), withdrawAmount);
        
        assertEq(user1.balance, balanceBefore + withdrawAmount);
        
        vm.stopPrank();
    }
    
    function testWithdrawERC20() public {
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
        
        assertEq(usdc.balanceOf(user1), balanceBefore + withdrawAmount);
    }
    
    function testWithdrawInsufficientBalance() public {
        uint256 depositAmount = 1 ether;
        uint256 withdrawAmount = 2 ether;
        
        vm.startPrank(user1);
        (bool success, ) = address(bank).call{value: depositAmount}("");
        assertTrue(success);
        
        // Verify deposit worked
        (uint256 balance,) = bank.getUserBalance(user1, bank.NATIVE_ETH());
        assertGt(balance, 0, "Deposit should have worked");
        
        // Try to withdraw more than deposited - should revert with InsufficientBalance
        bool didRevert = false;
        try bank.withdraw(bank.NATIVE_ETH(), withdrawAmount) {
            // Should not succeed
        } catch {
            didRevert = true;
        }
        assertTrue(didRevert, "Withdraw should have reverted");
        
        vm.stopPrank();
    }
    
    function testWithdrawExceedsLimit() public {
        // Deposit large amount
        uint256 depositAmount = 10 ether; // $20k at $2k/ETH
        
        vm.startPrank(user1);
        (bool success, ) = address(bank).call{value: depositAmount}("");
        assertTrue(success);
        
        // Verify deposit worked
        (uint256 balance,) = bank.getUserBalance(user1, bank.NATIVE_ETH());
        assertGt(balance, 0, "Deposit should have worked");
        
        // Try to withdraw more than limit ($10k = 5 ETH at $2k/ETH)
        // Trying to withdraw 6 ETH = $12k which exceeds $10k limit
        bool didRevert = false;
        try bank.withdraw(bank.NATIVE_ETH(), 6 ether) {
            // Should not succeed
        } catch {
            didRevert = true;
        }
        assertTrue(didRevert, "Withdraw should have reverted");
        
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN TESTS
    //////////////////////////////////////////////////////////////*/

    function testAddToken() public {
        MockERC20 dai = new MockERC20("Dai", "DAI", 18);
        MockV3Aggregator daiUsdFeed = new MockV3Aggregator(8, 1e8);
        
        vm.prank(admin);
        bank.addToken(address(dai), address(daiUsdFeed));
        
        (bool isSupported, , ) = bank.tokens(address(dai));
        assertTrue(isSupported);
    }
    
    function testRemoveToken() public {
        vm.prank(admin);
        bank.removeToken(address(usdc));
        
        (bool isSupported, , ) = bank.tokens(address(usdc));
        assertFalse(isSupported);
    }
    
    function testUpdateBankCap() public {
        uint256 newCap = 2_000_000e6; // $2M
        
        vm.prank(admin);
        bank.updateBankCap(newCap);
        
        assertEq(bank.bankCapUsd(), newCap);
    }
    
    function testPause() public {
        vm.prank(admin);
        bank.setPaused(true);
        
        assertTrue(bank.paused());
        
        // Try to deposit while paused
        vm.prank(user1);
        vm.expectRevert();
        (bool success, ) = address(bank).call{value: 1 ether}("");
    }
    
    function testUnauthorizedAdminAction() public {
        vm.prank(user1);
        vm.expectRevert();
        bank.updateBankCap(2_000_000e6);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW TESTS
    //////////////////////////////////////////////////////////////*/

    function testGetEthPrice() public view {
        uint256 price = bank.getEthPrice();
        assertEq(price, ETH_PRICE_USD);
    }
    
    function testConvertToUsd() public {
        uint256 ethAmount = 1 ether;
        uint256 usdValue = bank.convertToUsd(bank.NATIVE_ETH(), ethAmount);
        
        // Should be approximately $2000 (with 6 decimals)
        assertApproxEqRel(usdValue, 2000e6, 0.01e18); // 1% tolerance
    }
    
    function testGetRemainingCapacity() public {
        uint256 capacity = bank.getRemainingCapacityUsd();
        assertEq(capacity, BANK_CAP_USD);
        
        // Deposit some ETH
        vm.prank(user1);
        (bool success, ) = address(bank).call{value: 1 ether}("");
        assertTrue(success);
        
        // Capacity should decrease
        uint256 newCapacity = bank.getRemainingCapacityUsd();
        assertLt(newCapacity, BANK_CAP_USD);
    }

    /*//////////////////////////////////////////////////////////////
                        DECIMAL CONVERSION TESTS
    //////////////////////////////////////////////////////////////*/

    function testDecimalNormalization() public {
        // Test with 18 decimal token (like DAI)
        MockERC20 dai = new MockERC20("Dai", "DAI", 18);
        MockV3Aggregator daiUsdFeed = new MockV3Aggregator(8, 1e8);
        
        vm.prank(admin);
        bank.addToken(address(dai), address(daiUsdFeed));
        
        uint256 depositAmount = 1000e18; // 1000 DAI
        dai.mint(user1, depositAmount);
        
        vm.startPrank(user1);
        dai.approve(address(bank), depositAmount);
        bank.depositToken(address(dai), depositAmount);
        vm.stopPrank();
        
        // Balance should be normalized to 6 decimals
        (uint256 balance, ) = bank.getUserBalance(user1, address(dai));
        assertEq(balance, 1000e6); // Normalized to 6 decimals
    }
}
