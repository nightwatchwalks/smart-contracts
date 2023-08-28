// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Test} from "forge-std/Test.sol";
import {NightWatchPaymentDivider} from "../src/NightWatchPaymentDivider.sol";
import {MockERC20} from "solady-tests/utils/mocks/MockERC20.sol";

/// @title Night Watch Payment Divider Tests
/// @author @YigitDuman
contract NightWatchPaymentDividerTest is Test {
    NightWatchPaymentDivider private _nightWatchPaymentDivider;
    address private _partnerA = address(0x3);
    address private _partnerB = address(0x4);

    function setUp() public {
        vm.deal(address(this), type(uint256).max);
        _nightWatchPaymentDivider = new NightWatchPaymentDivider(
            _partnerA,
            _partnerB
        );
    }

    /*//////////////////////////////////////////////////////////////
                                TRANSFER
    //////////////////////////////////////////////////////////////*/

    function testTransferEtherLowAmount() public {
        payable(_nightWatchPaymentDivider).transfer(0.01 ether);
        assertEq(address(_nightWatchPaymentDivider).balance, 0.01 ether);
    }

    function testTransferEtherHighAmount() public {
        payable(_nightWatchPaymentDivider).transfer(100000 ether);
        assertEq(address(_nightWatchPaymentDivider).balance, 100000 ether);
    }

    function testTransferEtherFuzzy(uint256 amount) public {
        payable(_nightWatchPaymentDivider).transfer(amount);
        assertEq(address(_nightWatchPaymentDivider).balance, amount);
    }

    function testTransferERC20LowAmount() public {
        MockERC20 testErc20 = new MockERC20("test", "test", 18);
        testErc20.mint(address(_nightWatchPaymentDivider), 0.01 ether);
        assertEq(
            testErc20.balanceOf(address(_nightWatchPaymentDivider)),
            0.01 ether
        );
    }

    function testTransferERC20HighAmount() public {
        MockERC20 testErc20 = new MockERC20("test", "test", 18);
        testErc20.mint(address(_nightWatchPaymentDivider), 100000 ether);
        assertEq(
            testErc20.balanceOf(address(_nightWatchPaymentDivider)),
            100000 ether
        );
    }

    function testTransferERC20Fuzzy(uint256 amount) public {
        MockERC20 testErc20 = new MockERC20("test", "test", 18);
        testErc20.mint(address(_nightWatchPaymentDivider), amount);
        assertEq(
            testErc20.balanceOf(address(_nightWatchPaymentDivider)),
            amount
        );
    }

    /*//////////////////////////////////////////////////////////////
                                WITHDRAW
    //////////////////////////////////////////////////////////////*/

    function testWithdrawWithLowBalance() public {
        vm.deal(address(_nightWatchPaymentDivider), 0.01 ether);
        uint256 partnerAInitialBalance = _partnerA.balance;
        uint256 partnerBInitialBalance = _partnerB.balance;
        _nightWatchPaymentDivider.withdraw(
            address(_nightWatchPaymentDivider).balance
        );
        assertEq(_partnerA.balance, partnerAInitialBalance + 0.0065 ether);
        assertEq(_partnerB.balance, partnerBInitialBalance + 0.0035 ether);
    }

    function testWithdrawWithHighBalance() public {
        vm.deal(address(_nightWatchPaymentDivider), 1000 ether);
        uint256 partnerAInitialBalance = _partnerA.balance;
        uint256 partnerBInitialBalance = _partnerB.balance;
        _nightWatchPaymentDivider.withdraw(
            address(_nightWatchPaymentDivider).balance
        );
        assertEq(_partnerA.balance, partnerAInitialBalance + 650 ether);
        assertEq(_partnerB.balance, partnerBInitialBalance + 350 ether);
    }

    function testWithdrawFuzzy(uint256 amount) public {
        vm.assume(amount < type(uint256).max / 65);
        vm.assume(amount > 0);

        vm.deal(address(_nightWatchPaymentDivider), amount);
        uint256 partnerAInitialBalance = _partnerA.balance;
        uint256 partnerBInitialBalance = _partnerB.balance;

        _nightWatchPaymentDivider.withdraw(
            address(_nightWatchPaymentDivider).balance
        );

        uint256 amount65 = (amount * 65) / 100;
        uint256 amount35 = amount - amount65;
        assertEq(_partnerA.balance, partnerAInitialBalance + amount65);
        assertEq(_partnerB.balance, partnerBInitialBalance + amount35);
    }

    function testWithdrawNoFundsFails() public {
        vm.expectRevert(NightWatchPaymentDivider.NoFunds.selector);
        _nightWatchPaymentDivider.withdraw(0);

        vm.expectRevert(NightWatchPaymentDivider.NoFunds.selector);
        _nightWatchPaymentDivider.withdraw(1 ether);
    }

    function testWithdrawERC20WithLowBalance() public {
        MockERC20 testErc20 = new MockERC20("test", "test", 18);
        testErc20.mint(address(_nightWatchPaymentDivider), 0.01 ether);

        uint256 partnerAInitialBalance = testErc20.balanceOf(_partnerA);
        uint256 partnerBInitialBalance = testErc20.balanceOf(_partnerB);
        _nightWatchPaymentDivider.withdrawERC20(
            testErc20.balanceOf(address(_nightWatchPaymentDivider)),
            testErc20
        );

        assertEq(
            testErc20.balanceOf(_partnerA),
            partnerAInitialBalance + 0.0065 ether
        );
        assertEq(
            testErc20.balanceOf(_partnerB),
            partnerBInitialBalance + 0.0035 ether
        );
    }

    function testWithdrawERC20WithHighBalance() public {
        MockERC20 testErc20 = new MockERC20("test", "test", 18);
        testErc20.mint(address(_nightWatchPaymentDivider), 1000 ether);

        uint256 partnerAInitialBalance = testErc20.balanceOf(_partnerA);
        uint256 partnerBInitialBalance = testErc20.balanceOf(_partnerB);
        _nightWatchPaymentDivider.withdrawERC20(
            testErc20.balanceOf(address(_nightWatchPaymentDivider)),
            testErc20
        );

        assertEq(
            testErc20.balanceOf(_partnerA),
            partnerAInitialBalance + 650 ether
        );
        assertEq(
            testErc20.balanceOf(_partnerB),
            partnerBInitialBalance + 350 ether
        );
    }

    function testWithdrawERC20NoFundsFails() public {
        MockERC20 testErc20 = new MockERC20("test", "test", 18);

        vm.expectRevert(NightWatchPaymentDivider.NoFunds.selector);
        _nightWatchPaymentDivider.withdrawERC20(0, testErc20);

        vm.expectRevert(NightWatchPaymentDivider.NoFunds.selector);
        _nightWatchPaymentDivider.withdrawERC20(1 ether, testErc20);
    }

    function testWithdrawERC20Fuzzy(uint256 amount) public {
        vm.assume(amount < type(uint256).max / 65);
        vm.assume(amount > 0);

        MockERC20 testErc20 = new MockERC20("test", "test", 18);
        testErc20.mint(address(_nightWatchPaymentDivider), amount);

        uint256 partnerAInitialBalance = testErc20.balanceOf(_partnerA);
        uint256 partnerBInitialBalance = testErc20.balanceOf(_partnerB);
        _nightWatchPaymentDivider.withdrawERC20(
            testErc20.balanceOf(address(_nightWatchPaymentDivider)),
            testErc20
        );

        uint256 amount65 = (amount * 65) / 100;
        uint256 amount35 = amount - amount65;
        assertEq(
            testErc20.balanceOf(_partnerA),
            partnerAInitialBalance + amount65
        );
        assertEq(
            testErc20.balanceOf(_partnerB),
            partnerBInitialBalance + amount35
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ZERO ADDRESS
    //////////////////////////////////////////////////////////////*/

    function testZeroAddressFails() public {
        vm.expectRevert(NightWatchPaymentDivider.NoZeroAddress.selector);
        new NightWatchPaymentDivider(address(0), address(0x1));

        vm.expectRevert(NightWatchPaymentDivider.NoZeroAddress.selector);
        new NightWatchPaymentDivider(address(0x1), address(0));
    }
}
