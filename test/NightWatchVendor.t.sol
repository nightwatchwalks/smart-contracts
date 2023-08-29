// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Test} from "forge-std/Test.sol";
import {NightWatchVendor} from "../src/NightWatchVendor.sol";
import {NightWatch, IERC721A} from "../src/NightWatch.sol";
import {ERC20} from "solady/tokens/ERC20.sol";
import {MockERC20} from "solady-tests/utils/mocks/MockERC20.sol";
import {LibPRNG} from "solady/utils/LibPRNG.sol";
import {Utilities} from "./utils/Utilities.sol";

/// @title Night Watch Vendor Tests
/// @author @YigitDuman
contract NightWatchVendorTest is Test {
    NightWatchVendor private _nightWatchVendor;
    NightWatch private _nightWatch;
    Utilities private _utils;

    address private _partnerA = address(0x3);
    address private _partnerB = address(0x4);
    address private _vaultAddress = address(0x423);
    address private _vendorSignerAddress =
        address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);

    uint16[] _mockTokenIds;
    bytes _mockSignature =
        hex"756e89a7076ed9d24b489c7f12ddca1e849653a668ba17f1bd911b1c608ce9f475abf3b7313b48c26fce1d5286f3b12ea60d5243388bf924f7072a7ca1e9ac611c";
    uint256 _mockRandomnessHash =
        44665504314655073991200450518861547724076055838120490854382706591569565158276;

    function setUp() public {
        _utils = new Utilities();

        vm.deal(address(this), type(uint256).max);

        // Initialize Night Watch
        _nightWatch = new NightWatch(
            address(0x696969),
            _vaultAddress,
            500,
            address(0x6825)
        );

        _nightWatchVendor = new NightWatchVendor(
            _nightWatch,
            _vaultAddress,
            _vendorSignerAddress,
            _partnerA,
            _partnerB,
            6825
        );

        // Give approval to the vendor from the vault
        vm.prank(_vaultAddress);
        _nightWatch.setApprovalForAll(address(_nightWatchVendor), true);

        // Mint all tokens
        _nightWatch.mintRemainingSupplyToVault();

        // Prepare mock token ids to purchase
        _mockTokenIds = _utils.getMockTokens();
    }

    function testDeploy() public {
        new NightWatchVendor(
            _nightWatch,
            address(0x423),
            address(0x6825),
            _partnerA,
            _partnerB,
            6825
        );
    }

    /*//////////////////////////////////////////////////////////////
                           OWNER ONLY CHECKS
    //////////////////////////////////////////////////////////////*/

    function testSetVaultAddressOwnerOnly() public {
        _expectRevertAsNonOwner();
        _nightWatchVendor.setVaultAddress(address(0x1));
    }

    function testSetMaxPurchaseLimitOwnerOnly() public {
        _expectRevertAsNonOwner();
        _nightWatchVendor.setMaxPurchaseLimit(1);
    }

    function testSetPriceOwnerOnly() public {
        _expectRevertAsNonOwner();
        _nightWatchVendor.setPrice(0);
    }

    function testSetSaleStateOwnerOnly() public {
        _expectRevertAsNonOwner();
        _nightWatchVendor.setSaleState(false);
    }

    function testSetNightWatchOwnerOnly() public {
        _expectRevertAsNonOwner();
        _nightWatchVendor.setNightWatch(address(0x33));
    }

    function testSetSignerOwnerOnly() public {
        _expectRevertAsNonOwner();
        _nightWatchVendor.setSigner(address(0x33));
    }

    function testWithdrawOwnerOnly() public {
        _expectRevertAsNonOwner();
        _nightWatchVendor.withdraw(1);
    }

    function testWithdrawERC20OwnerOnly() public {
        _expectRevertAsNonOwner();
        _nightWatchVendor.withdrawERC20(1, ERC20(address(0x33)));
    }

    function testSetSoldOutAmountOwnerOnly() public {
        _expectRevertAsNonOwner();
        _nightWatchVendor.setSoldOutAmount(1);
    }

    function testSetTotalSoldOwnerOnly() public {
        _expectRevertAsNonOwner();
        _nightWatchVendor.setTotalSold(1);
    }

    function testSetPartnerAAddressOwnerOnly() public {
        _expectRevertAsNonOwner();
        _nightWatchVendor.setPartnerAAddress(address(0x33));
    }

    function testSetPartnerBAddressOwnerOnly() public {
        _expectRevertAsNonOwner();
        _nightWatchVendor.setPartnerBAddress(address(0x33));
    }

    function _expectRevertAsNonOwner() private {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(address(0x1));
    }

    /*//////////////////////////////////////////////////////////////
                                WITHDRAW
    //////////////////////////////////////////////////////////////*/

    function testWithdrawWithLowBalance() public {
        vm.deal(address(_nightWatchVendor), 0.01 ether);
        uint256 partnerAInitialBalance = _partnerA.balance;
        uint256 partnerBInitialBalance = _partnerB.balance;
        _nightWatchVendor.withdraw(address(_nightWatchVendor).balance);
        assertEq(_partnerA.balance, partnerAInitialBalance + 0.0065 ether);
        assertEq(_partnerB.balance, partnerBInitialBalance + 0.0035 ether);
    }

    function testWithdrawWithHighBalance() public {
        vm.deal(address(_nightWatchVendor), 1000 ether);
        uint256 partnerAInitialBalance = _partnerA.balance;
        uint256 partnerBInitialBalance = _partnerB.balance;
        _nightWatchVendor.withdraw(address(_nightWatchVendor).balance);
        assertEq(_partnerA.balance, partnerAInitialBalance + 650 ether);
        assertEq(_partnerB.balance, partnerBInitialBalance + 350 ether);
    }

    function testWithdrawFuzzy(uint256 amount) public {
        vm.assume(amount < type(uint256).max / 65);
        vm.assume(amount > 0);

        vm.deal(address(_nightWatchVendor), amount);
        uint256 partnerAInitialBalance = _partnerA.balance;
        uint256 partnerBInitialBalance = _partnerB.balance;

        _nightWatchVendor.withdraw(address(_nightWatchVendor).balance);

        uint256 amount65 = (amount * 65) / 100;
        uint256 amount35 = amount - amount65;
        assertEq(_partnerA.balance, partnerAInitialBalance + amount65);
        assertEq(_partnerB.balance, partnerBInitialBalance + amount35);
    }

    function testWithdrawNoFundsFails() public {
        vm.expectRevert(NightWatchVendor.NoFunds.selector);
        _nightWatchVendor.withdraw(0);

        vm.expectRevert(NightWatchVendor.NoFunds.selector);
        _nightWatchVendor.withdraw(1 ether);
    }

    function testWithdrawERC20WithLowBalance() public {
        MockERC20 testErc20 = new MockERC20("test", "test", 18);
        testErc20.mint(address(_nightWatchVendor), 0.01 ether);

        uint256 partnerAInitialBalance = testErc20.balanceOf(_partnerA);
        uint256 partnerBInitialBalance = testErc20.balanceOf(_partnerB);
        _nightWatchVendor.withdrawERC20(
            testErc20.balanceOf(address(_nightWatchVendor)),
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
        testErc20.mint(address(_nightWatchVendor), 1000 ether);

        uint256 partnerAInitialBalance = testErc20.balanceOf(_partnerA);
        uint256 partnerBInitialBalance = testErc20.balanceOf(_partnerB);
        _nightWatchVendor.withdrawERC20(
            testErc20.balanceOf(address(_nightWatchVendor)),
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

        vm.expectRevert(NightWatchVendor.NoFunds.selector);
        _nightWatchVendor.withdrawERC20(0, testErc20);

        vm.expectRevert(NightWatchVendor.NoFunds.selector);
        _nightWatchVendor.withdrawERC20(1 ether, testErc20);
    }

    function testWithdrawERC20Fuzzy(uint256 amount) public {
        vm.assume(amount < type(uint256).max / 65);
        vm.assume(amount > 0);

        MockERC20 testErc20 = new MockERC20("test", "test", 18);
        testErc20.mint(address(_nightWatchVendor), amount);

        uint256 partnerAInitialBalance = testErc20.balanceOf(_partnerA);
        uint256 partnerBInitialBalance = testErc20.balanceOf(_partnerB);
        _nightWatchVendor.withdrawERC20(
            testErc20.balanceOf(address(_nightWatchVendor)),
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
                                PURCHASE
    //////////////////////////////////////////////////////////////*/

    function testPurchaseSaleIsNotActive() public {
        _nightWatchVendor.setSaleState(false);
        startHoax(address(0x777), 1 ether);
        vm.expectRevert(NightWatchVendor.SaleIsNotActive.selector);
        _nightWatchVendor.purchaseTokens{value: 0.3 ether}(10, address(0x777));
    }

    function testPurchaseSoldOut() public {
        _nightWatchVendor.setTotalSold(10);
        _nightWatchVendor.setSoldOutAmount(10);
        startHoax(address(0x777), 1 ether);
        vm.expectRevert(NightWatchVendor.SoldOut.selector);
        _nightWatchVendor.purchaseTokens{value: 0.3 ether}(10, address(0x777));
    }

    function testExceedingMaxPurchaseLimitFails() public {
        vm.expectRevert(NightWatchVendor.MaxPurchaseLimitExceeded.selector);
        _nightWatchVendor.purchaseTokens{value: 0.33 ether}(11, address(this));
    }

    function testPurchaseLowPriceFails() public {
        vm.expectRevert(NightWatchVendor.InvalidPrice.selector);
        _nightWatchVendor.purchaseTokens{value: 0.02 ether}(1, address(this));
    }

    function testPurchaseLowPriceFails2() public {
        vm.expectRevert(NightWatchVendor.InvalidPrice.selector);
        _nightWatchVendor.purchaseTokens{value: 0.03 ether}(10, address(this));
    }

    function testPurchaseLowPriceFails3() public {
        vm.expectRevert(NightWatchVendor.InvalidPrice.selector);
        _nightWatchVendor.purchaseTokens{value: 0.27 ether}(10, address(this));
    }

    function testPurchaseHighPriceFails() public {
        vm.expectRevert(NightWatchVendor.InvalidPrice.selector);
        _nightWatchVendor.purchaseTokens{value: 1 ether}(10, address(this));
    }

    function testPurchaseExactPriceSingleToken() public {
        startHoax(address(0x777), 1 ether);
        _nightWatchVendor.purchaseTokens{value: 0.03 ether}(1, address(0x777));

        uint256 unclaimedTokens = _nightWatchVendor._unclaimedTokens(
            address(0x777)
        );

        assertEq(address(0x777).balance, 0.97 ether);
        assertEq(unclaimedTokens, 1);
    }

    function testPurchaseExactPriceMultipleTokens() public {
        startHoax(address(0x777), 1 ether);
        _nightWatchVendor.purchaseTokens{value: 0.3 ether}(10, address(0x777));

        uint256 unclaimedTokens = _nightWatchVendor._unclaimedTokens(
            address(0x777)
        );

        assertEq(address(0x777).balance, 0.7 ether);
        assertEq(unclaimedTokens, 10);
    }

    function testPurchaseVaultReceiver() public {
        startHoax(address(0x777), 1 ether);
        vm.expectRevert(NightWatchVendor.ReceiverCantBeVaultAddress.selector);
        _nightWatchVendor.purchaseTokens{value: 0.03 ether}(1, _vaultAddress);
    }

    function testPurchaseZeroReceiver() public {
        _nightWatch.setMergePaused(false);
        startHoax(address(0x777), 1 ether);
        vm.expectRevert(NightWatchVendor.ReceiverCantBeZeroAddress.selector);
        _nightWatchVendor.purchaseTokens{value: 0.03 ether}(1, address(0));
    }

    function testPurchaseUnclaimedTokensExist() public {
        startHoax(address(0x777), 1 ether);
        _nightWatchVendor.purchaseTokens{value: 0.3 ether}(10, address(0x777));
        vm.expectRevert(NightWatchVendor.UnclaimedTokensExist.selector);
        _nightWatchVendor.purchaseTokens{value: 0.3 ether}(10, address(0x777));
    }

    event Purchase(address indexed receiver, uint256 amount);

    function testPurchaseEmitsEvent() public {
        startHoax(address(0x777), 1 ether);
        vm.expectEmit(true, true, false, false);
        emit Purchase(address(0x777), 10);
        _nightWatchVendor.purchaseTokens{value: 0.3 ether}(10, address(0x777));
    }

    function testInvalidSignatureFails() public {
        startHoax(address(0x777), 1 ether);
        _nightWatchVendor.purchaseTokens{value: 0.3 ether}(10, address(0x777));

        vm.expectRevert(NightWatchVendor.InvalidSignature.selector);
        _nightWatchVendor.claimTokens(address(0x777), _mockTokenIds, "");
    }

    function testSimilarInvalidSignatureFails() public {
        startHoax(address(0x777), 1 ether);
        _nightWatchVendor.purchaseTokens{value: 0.3 ether}(10, address(0x777));

        vm.expectRevert(NightWatchVendor.InvalidSignature.selector);
        _nightWatchVendor.claimTokens(
            address(0x777),
            _mockTokenIds,
            hex"756e89a7076ed9d24b489c7f12ddca1e849653a668ba17f1bd911b1c608ce9f475abf3b7313b48c26fce1d5286f3b12ea60d5243388bf924f7072a7ca1e9ac611d"
        );
    }

    function testInvalidTokenListFails() public {
        startHoax(address(0x777), 1 ether);
        _nightWatchVendor.purchaseTokens{value: 0.3 ether}(10, address(0x777));

        uint16[] memory invalidTokenIds = new uint16[](1);
        vm.expectRevert(NightWatchVendor.NoUnclaimedTokens.selector);
        _nightWatchVendor.claimTokens(
            address(0x777),
            invalidTokenIds,
            _mockSignature
        );
    }

    function testBalanceAfterClaim() public {
        startHoax(address(0x777), 1 ether);
        _nightWatchVendor.purchaseTokens{value: 0.3 ether}(10, address(0x777));

        _nightWatchVendor.claimTokens(
            address(0x777),
            _mockTokenIds,
            _mockSignature
        );

        assertEq(_nightWatch.balanceOf(address(0x777)), 10);
    }

    function testUnclaimedTokensUpdatesAfterClaim() public {
        startHoax(address(0x777), 1 ether);
        _nightWatchVendor.purchaseTokens{value: 0.3 ether}(10, address(0x777));

        uint256 unclaimedTokens = _nightWatchVendor._unclaimedTokens(
            address(0x777)
        );

        assertEq(unclaimedTokens, 10);

        _nightWatchVendor.claimTokens(
            address(0x777),
            _mockTokenIds,
            _mockSignature
        );

        uint256 newUnclaimedTokens = _nightWatchVendor._unclaimedTokens(
            address(0x777)
        );

        assertEq(newUnclaimedTokens, 0);
    }

    event Claim(address indexed receiver, uint16[] tokens);

    function testClaimEmitsEvent() public {
        startHoax(address(0x777), 1 ether);
        _nightWatchVendor.purchaseTokens{value: 0.3 ether}(10, address(0x777));

        vm.expectEmit(true, true, false, false);
        emit Claim(address(0x777), _mockTokenIds);
        _nightWatchVendor.claimTokens(
            address(0x777),
            _mockTokenIds,
            _mockSignature
        );
    }

    function testDoubleUseOfSameSignature() public {
        startHoax(address(0x777), 1 ether);
        _nightWatchVendor.purchaseTokens{value: 0.3 ether}(10, address(0x777));

        _nightWatchVendor.claimTokens(
            address(0x777),
            _mockTokenIds,
            _mockSignature
        );

        _nightWatchVendor.purchaseTokens{value: 0.3 ether}(10, address(0x777));

        vm.expectRevert(NightWatchVendor.SignatureUsed.selector);
        _nightWatchVendor.claimTokens(
            address(0x777),
            _mockTokenIds,
            _mockSignature
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ZERO ADDRESS
    //////////////////////////////////////////////////////////////*/

    function testNoZeroAddress() public {
        vm.expectRevert(NightWatchVendor.NoZeroAddress.selector);
        new NightWatchVendor(
            _nightWatch,
            address(0),
            _vendorSignerAddress,
            _partnerA,
            _partnerB,
            6825
        );
        vm.expectRevert(NightWatchVendor.NoZeroAddress.selector);
        new NightWatchVendor(
            _nightWatch,
            _vaultAddress,
            address(0),
            _partnerA,
            _partnerB,
            6825
        );
        vm.expectRevert(NightWatchVendor.NoZeroAddress.selector);
        new NightWatchVendor(
            _nightWatch,
            _vaultAddress,
            _vendorSignerAddress,
            address(0),
            _partnerB,
            6825
        );
        vm.expectRevert(NightWatchVendor.NoZeroAddress.selector);
        new NightWatchVendor(
            _nightWatch,
            _vaultAddress,
            _vendorSignerAddress,
            _partnerA,
            address(0),
            6825
        );
        vm.expectRevert(NightWatchVendor.NoZeroAddress.selector);
        _nightWatchVendor.setSigner(address(0));
        vm.expectRevert(NightWatchVendor.NoZeroAddress.selector);
        _nightWatchVendor.setVaultAddress(address(0));
    }
}
