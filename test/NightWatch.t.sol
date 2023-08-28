// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Test} from "forge-std/Test.sol";
import {NightWatch, IERC721A} from "../src/NightWatch.sol";
import {NightWatchMetadata} from "../src/NightWatchMetadata.sol";
import {Utilities} from "./utils/Utilities.sol";
import {ArrayUtils} from "./utils/ArrayUtils.sol";
import {ERC20} from "solady/tokens/ERC20.sol";
import {MockERC20} from "solady-tests/utils/mocks/MockERC20.sol";

/// @title Night Watch Tests
/// @author @YigitDuman
contract NightWatchTest is Test {
    NightWatch private _nightWatch;
    Utilities private _utils;
    uint256 private immutable _maxSupply = 6825;
    address private constant _VAULT_ADDRESS = address(0x6825);

    function setUp() public {
        _nightWatch = _deployNightWatch();
        _utils = new Utilities();
    }

    function _deployNightWatch() private returns (NightWatch nightWatch) {
        nightWatch = new NightWatch(
            address(0x696969),
            _VAULT_ADDRESS,
            500,
            address(0x6825)
        );
    }

    /*//////////////////////////////////////////////////////////////
                          OWNER ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function testLockStateOwnerOnly() public {
        _expectRevertAsNonOwner();
        _nightWatch.lockState(true, true, false, false, false, false);
    }

    function testSetMergePausedOwnerOnly() public {
        _expectRevertAsNonOwner();
        _nightWatch.setMergePaused(false);
    }

    function testSetTransfersPausedOwnerOnly() public {
        _expectRevertAsNonOwner();
        _nightWatch.setTransfersPaused(false);
    }

    function testSetOperatorFilteringEnabledOwnerOnly() public {
        _expectRevertAsNonOwner();
        _nightWatch.setOperatorFilteringEnabled(false);
    }

    function testSetDefaultRoyaltyOwnerOnly() public {
        _expectRevertAsNonOwner();
        _nightWatch.setDefaultRoyalty(address(0x555), 0);
    }

    function testSetMetadataAddressOwnerOnly() public {
        _expectRevertAsNonOwner();
        _nightWatch.setMetadataAddress(address(0x1));
    }

    function testSetVaultAddressOwnerOnly() public {
        _expectRevertAsNonOwner();
        _nightWatch.setVaultAddress(address(0x1));
    }

    function testSetPriorityOperatorOwnerOnly() public {
        _expectRevertAsNonOwner();
        _nightWatch.setPriorityOperator(address(0x1));
    }

    function testMintOwnerOnly() public {
        _expectRevertAsNonOwner();
        _nightWatch.mint(address(0x1), 1);
    }

    function testMintRemainingSupplyToVaultOwnerOnly() public {
        _expectRevertAsNonOwner();
        _nightWatch.mintRemainingSupplyToVault();
    }

    function testWithdrawOwnerOnly() public {
        _expectRevertAsNonOwner();
        _nightWatch.withdraw(address(0x1), address(_nightWatch).balance);
    }

    function testWithdrawERC20OwnerOnly() public {
        _expectRevertAsNonOwner();
        _nightWatch.withdrawERC20(
            address(0x1),
            address(_nightWatch).balance,
            ERC20(address(0x10))
        );
    }

    function testFillTokenDataOwnerOnly() public {
        uint24[] memory tokenData = new uint24[](0);
        _expectRevertAsNonOwner();
        _nightWatch.fillTokenData(tokenData);
    }

    function testClearTokenDataOwnerOnly() public {
        _expectRevertAsNonOwner();
        _nightWatch.clearTokenData();
    }

    function testReplaceTokenDataOwnerOnly() public {
        _expectRevertAsNonOwner();
        _nightWatch.replaceTokenData(0, 1);
    }

    function _expectRevertAsNonOwner() private {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(address(0x1));
    }

    /*//////////////////////////////////////////////////////////////
                    LOCK STATE FUNCTIONALITY CHECKS
    //////////////////////////////////////////////////////////////*/

    function testLockStateTokenData() public {
        _nightWatch.lockState(true, false, false, false, false, false);

        // Prepare empty mock tokenData array
        uint24[] memory tokenData = new uint24[](0);

        vm.expectRevert(NightWatch.TokenDataChangeLocked.selector);
        _nightWatch.fillTokenData(tokenData);

        vm.expectRevert(NightWatch.TokenDataChangeLocked.selector);
        _nightWatch.clearTokenData();

        vm.expectRevert(NightWatch.TokenDataChangeLocked.selector);
        _nightWatch.replaceTokenData(0, 1);
    }

    function testLockStateMetadata() public {
        _nightWatch.lockState(false, true, false, false, false, false);
        vm.expectRevert(NightWatch.MetadataLocked.selector);
        _nightWatch.setMetadataAddress(address(0x1));
    }

    function testLockStateMergePause() public {
        _nightWatch.lockState(false, false, true, false, false, false);
        vm.expectRevert(NightWatch.MergePauseLocked.selector);
        _nightWatch.setMergePaused(true);
    }

    function testLockStateMergePauseCancelsPause() public {
        // Mint a Night Watch to test merge pause
        _nightWatch.mint(address(0x1), 1);
        uint256 token = _nightWatch.getOwnedTokens(address(0x1))[0];

        // Pause merge
        _nightWatch.setMergePaused(true);

        // Test burn during merge
        vm.expectRevert(NightWatch.CannotBurnDuringMergePause.selector);
        vm.prank(address(0x1));
        _nightWatch.burn(token);

        // Lock merge
        _nightWatch.lockState(false, false, true, false, false, false);

        // Burn the token to test merge pause cancelled
        vm.prank(address(0x1));
        _nightWatch.burn(token);

        // Make sure the token is burned
        assertEq(_nightWatch.balanceOf(address(0x1)), 0);
    }

    function testLockStateTransferPause() public {
        _nightWatch.lockState(false, false, false, true, false, false);
        vm.expectRevert(NightWatch.TransferPauseLocked.selector);
        _nightWatch.setTransfersPaused(true);
    }

    function testLockStateTransferPauseCancelsPause() public {
        // Mint a Night Watch to test transfer pause
        _nightWatch.mint(address(0x1), 1);
        uint256 token = _nightWatch.getOwnedTokens(address(0x1))[0];

        // Pause transfers
        _nightWatch.setTransfersPaused(true);

        // Test transfer during transfer pause
        vm.expectRevert(NightWatch.CannotTransferDuringTransferPause.selector);
        vm.prank(address(0x1));
        _nightWatch.transferFrom(address(0x1), address(0x2), token);

        // Lock transfer pausing
        _nightWatch.lockState(false, false, false, true, false, false);

        // Transfer the token to test transfer pause cancelled
        vm.prank(address(0x1));
        _nightWatch.transferFrom(address(0x1), address(0x2), token);

        // Make sure the token is transferred
        assertEq(_nightWatch.balanceOf(address(0x1)), 0);
        assertEq(_nightWatch.balanceOf(address(0x2)), 1);
    }

    function testLockStateVaultChange() public {
        _nightWatch.lockState(false, false, false, false, true, false);
        vm.expectRevert(NightWatch.VaultChangeLocked.selector);
        _nightWatch.setVaultAddress(address(0x1));
    }

    function testLockStateOperatorFiltering() public {
        _nightWatch.lockState(false, false, false, false, false, true);
        vm.expectRevert(NightWatch.TogglingOperatorFilteringLocked.selector);
        _nightWatch.setOperatorFilteringEnabled(true);
    }

    /*//////////////////////////////////////////////////////////////
                            METADATA CHECKS
    //////////////////////////////////////////////////////////////*/

    function testSetMetadataAddress() public {
        NightWatchMetadata nwm1 = new NightWatchMetadata("a");
        NightWatchMetadata nwm2 = new NightWatchMetadata("b");
        _nightWatch.setMetadataAddress(address(nwm1));
        assertEq(_nightWatch.tokenURI(0), "a0");
        _nightWatch.setMetadataAddress(address(nwm2));
        assertEq(_nightWatch.tokenURI(0), "b0");
    }

    /*//////////////////////////////////////////////////////////////
                           TOKEN DATA CHECKS
    //////////////////////////////////////////////////////////////*/

    function testFillTokenData() public {
        uint24[] memory tokenData = _utils.getTokenData("tokenData_1");
        _nightWatch.fillTokenData(tokenData);
        assertEq(_nightWatch.getSet(0), 420);
        assertEq(_nightWatch.getFrames(6822)[4], 1);
    }

    function testFillTokenDataMultipleTimes() public {
        _nightWatch.fillTokenData(ArrayUtils.uint24s(2752544));
        assertEq(_nightWatch.getSet(0), 84);
        assertEq(_nightWatch.getFrames(0)[5], 1);

        _nightWatch.fillTokenData(ArrayUtils.uint24s(10911745));
        assertEq(_nightWatch.getSet(1), 333);
        assertEq(_nightWatch.getFrames(1)[0], 1);
    }

    function testClearTokenData() public {
        _nightWatch.fillTokenData(ArrayUtils.uint24s(2752544));
        assertEq(_nightWatch.getSet(0), 84);
        _nightWatch.clearTokenData();
        vm.expectRevert(NightWatch.TokenDataNotFound.selector);
        _nightWatch.getSet(0);
    }

    function testReplaceTokenData() public {
        _nightWatch.fillTokenData(ArrayUtils.uint24s(0));
        _nightWatch.replaceTokenData(0, 2752544);
        assertEq(_nightWatch.getSet(0), 84);
    }

    function testSetAndFrameGetters() public {
        _nightWatch.fillTokenData(ArrayUtils.uint24s(2752544));
        assertEq(_nightWatch.getSet(0), 84);
        assertEq(_nightWatch.getFrames(0)[5], 1);
        assertEq(_nightWatch.getFrames(0)[8], 0);
    }

    function testTokenDataClearsAfterBurn() public {
        // Mint a token to burn
        _nightWatch.mint(address(0x6), 1);

        // Fill arbitrary token data
        _nightWatch.fillTokenData(ArrayUtils.uint24s(2752544));

        // Ensure token data filled
        assertEq(_nightWatch.getSet(0), 84);
        assertEq(_nightWatch.getFrames(0)[5], 1);
        assertEq(_nightWatch.getFrames(0)[8], 0);

        // Resume merge to allow burn
        _nightWatch.setMergePaused(false);

        // Burn the token
        vm.prank(address(0x6));
        _nightWatch.burn(0);

        // Ensure token data cleared
        assertEq(_nightWatch.getSet(0), 0);
        assertEq(_nightWatch.getFrames(0)[5], 0);
        assertEq(_nightWatch.getFrames(0)[8], 0);
    }

    /*//////////////////////////////////////////////////////////////
                        ERC721 FUNCTIONALITIES
    //////////////////////////////////////////////////////////////*/

    function testBurnDuringMergePause() public {
        // Mint a token to burn
        _nightWatch.mint(address(0x1), 1);

        // Pause merge
        _nightWatch.setMergePaused(true);

        // Try to burn the token and get reverted
        uint256 token = _nightWatch.getOwnedTokens(address(0x1))[0];
        vm.prank(address(0x1));
        vm.expectRevert(NightWatch.CannotBurnDuringMergePause.selector);
        _nightWatch.burn(token);
    }

    function testTransferDuringTransferPause() public {
        // Pause transfers
        _nightWatch.setTransfersPaused(true);

        // Mint a token
        _nightWatch.mint(address(0x1), 1);

        // Try to transfer the token and get reverted
        uint256 token = _nightWatch.getOwnedTokens(address(0x1))[0];
        vm.prank(address(0x1));
        vm.expectRevert(NightWatch.CannotTransferDuringTransferPause.selector);
        _nightWatch.transferFrom(address(0x1), address(0x2), token);
    }

    function testTokenUri() public {
        NightWatchMetadata customMetadata = new NightWatchMetadata(
            "testurl://"
        );
        _nightWatch.setMetadataAddress(address(customMetadata));
        assertEq(_nightWatch.tokenURI(666), "testurl://666");
    }

    /*//////////////////////////////////////////////////////////////
                              MINT CHECKS
    //////////////////////////////////////////////////////////////*/

    function testMintAfterSellOut() public {
        _nightWatch.mint(address(0x1), _maxSupply);
        assertEq(_nightWatch.totalSupply(), _maxSupply);
        vm.expectRevert(NightWatch.MaxSupplyExceeded.selector);
        _nightWatch.mint(address(0x2), 1);
    }

    function testMintingZeroTokens() public {
        vm.expectRevert(IERC721A.MintZeroQuantity.selector);
        _nightWatch.mint(address(0x1), 0);
    }

    function testTransferAfterMint() public {
        _nightWatch.mint(address(0x1), 1);
        _nightWatch.mint(address(0x2), 1);

        vm.startPrank(address(0x1));
        _nightWatch.transferFrom(address(0x1), address(0x3), 0);
        vm.stopPrank();

        vm.prank(address(0x2));
        _nightWatch.safeTransferFrom(address(0x2), address(0x1), 1);
    }

    function testMintRemainingSupplyToVault() public {
        _nightWatch.mintRemainingSupplyToVault();
        assertEq(_nightWatch.totalSupply(), _maxSupply);
    }

    function testMintRemainingSupplyToVaultPartiallyMinted() public {
        _nightWatch.mint(address(0x676), 676);
        assertEq(_nightWatch.totalSupply(), 676);

        _nightWatch.mintRemainingSupplyToVault();
        assertEq(_nightWatch.totalSupply(), _maxSupply);
    }

    function testMintRemainingSupplyToVaultMintedOut() public {
        _nightWatch.mint(address(0x676), _maxSupply);
        assertEq(_nightWatch.totalSupply(), _maxSupply);

        vm.expectRevert(NightWatch.MaxSupplyExceeded.selector);
        _nightWatch.mintRemainingSupplyToVault();
    }

    function testVaultTransferAfterMintOutLowTokenId() public {
        _nightWatch.mintRemainingSupplyToVault();
        assertEq(_nightWatch.totalSupply(), _maxSupply);

        vm.prank(_VAULT_ADDRESS);
        _nightWatch.transferFrom(_VAULT_ADDRESS, address(0x1), 0);

        assertEq(_nightWatch.balanceOf(address(0x1)), 1);
        assertEq(_nightWatch.balanceOf(_VAULT_ADDRESS), 6824);
    }

    function testVaultTransferAfterMintOutHighTokenId() public {
        _nightWatch.mintRemainingSupplyToVault();
        assertEq(_nightWatch.totalSupply(), _maxSupply);

        vm.prank(_VAULT_ADDRESS);
        _nightWatch.transferFrom(_VAULT_ADDRESS, address(0x1), 6824);

        assertEq(_nightWatch.balanceOf(address(0x1)), 1);
        assertEq(_nightWatch.balanceOf(_VAULT_ADDRESS), 6824);
    }

    /*//////////////////////////////////////////////////////////////
                         MERGE FUNCTIONALITIES
    //////////////////////////////////////////////////////////////*/

    function testMergeOfTwoFramesArbitraryData() public {
        // Min two tokens to two different addresses
        _nightWatch.mint(address(0x1), 1);
        _nightWatch.mint(address(0x2), 1);
        assertEq(_nightWatch.totalSupply(), 2);

        // Resume merge and clear token data
        _nightWatch.setMergePaused(false);
        _nightWatch.clearTokenData();

        // Fill arbitrary token data
        uint24[] memory contents = new uint24[](2);
        contents[0] = 1146882;
        contents[1] = 1146884;
        _nightWatch.fillTokenData(contents);

        // Ensure token data is correct
        assertEq(_nightWatch.getSet(0), 35);
        assertEq(_nightWatch.getSet(1), 35);
        assertEq(_nightWatch.getFrames(0)[1], 1);
        assertEq(_nightWatch.getFrames(1)[2], 1);
        assertEq(_nightWatch.getFrames(0)[0], 0);
        assertEq(_nightWatch.getFrames(1)[7], 0);

        // Transfer to merge
        vm.prank(address(0x1));
        _nightWatch.transferFrom(address(0x1), address(0x2), 0);

        // Ensure merge happened
        assertEq(_nightWatch.totalSupply(), 1);
        assertEq(_nightWatch.getFrames(0)[1], 1);
        assertEq(_nightWatch.getFrames(0)[2], 1);
    }

    function testMergeOfDifferentSetsArbitraryData() public {
        // Min two tokens to two different addresses
        _nightWatch.mint(address(0x1), 1);
        _nightWatch.mint(address(0x2), 1);
        assertEq(_nightWatch.totalSupply(), 2);

        // Resume merge and clear token data
        _nightWatch.setMergePaused(false);
        _nightWatch.clearTokenData();

        // Fill arbitrary token data
        uint24[] memory contents = new uint24[](2);
        contents[0] = 1507330;
        contents[1] = 1867780;
        _nightWatch.fillTokenData(contents);

        // Ensure token data is correct
        assertEq(_nightWatch.getSet(0), 46);
        assertEq(_nightWatch.getSet(1), 57);
        assertEq(_nightWatch.getFrames(0)[1], 1);
        assertEq(_nightWatch.getFrames(1)[2], 1);
        assertEq(_nightWatch.getFrames(0)[0], 0);
        assertEq(_nightWatch.getFrames(1)[7], 0);

        // Transfer the token
        vm.prank(address(0x1));
        _nightWatch.transferFrom(address(0x1), address(0x2), 0);

        // Ensure they are not merged and still correct
        assertEq(_nightWatch.totalSupply(), 2);
        assertEq(_nightWatch.getSet(0), 46);
        assertEq(_nightWatch.getSet(1), 57);
        assertEq(_nightWatch.getFrames(0)[1], 1);
        assertEq(_nightWatch.getFrames(1)[2], 1);
        assertEq(_nightWatch.getFrames(0)[0], 0);
        assertEq(_nightWatch.getFrames(1)[7], 0);
    }

    function testMergeWithTransfersArbitraryData() public {
        // Mint 20 tokens to two different addresses
        assertEq(_nightWatch.totalSupply(), 0);
        _nightWatch.mint(address(0x1), 10);
        _nightWatch.mint(address(0x2), 10);
        assertEq(_nightWatch.totalSupply(), 20);

        // Resume merge and clear token data
        _nightWatch.setMergePaused(false);
        _nightWatch.clearTokenData();

        // Fill arbitrary token data
        uint24[] memory tokenData = new uint24[](20);
        tokenData[0] = 14229504;
        tokenData[1] = 14221824;
        tokenData[2] = 14221376;
        tokenData[3] = 14221328;
        tokenData[4] = 14221320;
        tokenData[5] = 14696448;
        tokenData[6] = 14688256;
        tokenData[7] = 14684160;
        tokenData[8] = 14682112;
        tokenData[9] = 14681088;
        tokenData[10] = 14237696;
        tokenData[11] = 14225408;
        tokenData[12] = 14222336;
        tokenData[13] = 14221568;
        tokenData[14] = 14221344;
        tokenData[15] = 14680096;
        tokenData[16] = 14680080;
        tokenData[17] = 14680072;
        tokenData[18] = 14680068;
        tokenData[19] = 14680066;
        _nightWatch.fillTokenData(tokenData);

        // Create token array to merge the specified tokens
        uint256[][] memory tokenArray = new uint256[][](4);
        for (uint256 i = 0; i < 4; i++) {
            tokenArray[i] = new uint256[](5);
            for (uint256 j = 0; j < 5; j++) {
                tokenArray[i][j] = (i * 5) + j;
            }
        }

        // Merge the tokens in the token array
        _nightWatch.tryMergeTokenArray(tokenArray);

        // Ensure merge happened
        assertEq(_nightWatch.totalSupply(), 4);

        // Transfer the token 0 to merge
        vm.prank(address(0x1));
        _nightWatch.transferFrom(address(0x1), address(0x2), 0);

        // Ensure merge happened
        assertEq(_nightWatch.totalSupply(), 3);

        // Transfer the token 15 to merge
        vm.prank(address(0x2));
        _nightWatch.transferFrom(address(0x2), address(0x1), 15);

        // Ensure merge happened
        assertEq(_nightWatch.totalSupply(), 2);
    }

    function testMergeWithTransfers2ArbitraryData() public {
        assertEq(_nightWatch.totalSupply(), 0);
        _nightWatch.mint(address(0x1), 2); // Mint set 434, frame 1 and 2
        _nightWatch.mint(address(0x2), 2); // Mint set 111, frame 1 and 2
        _nightWatch.mint(address(0x3), 2); // Mint set 5, frame 1 and 2
        _nightWatch.mint(address(0x4), 2); // Mint set 31, frame 1 and 2
        _nightWatch.mint(address(0x5), 2); // Mint set 49, frame 1 and 2
        _nightWatch.mint(address(0x6), 2); // Mint set 69, frame 1 and 2
        _nightWatch.mint(address(0x7), 1); // Mint set 111, frame 5
        _nightWatch.mint(address(0x8), 1); // Mint set 111, frame 10
        _nightWatch.mint(address(0x9), 1); // Mint set 111, frame 13
        assertEq(_nightWatch.totalSupply(), 15);

        // Resume merge and clear token data
        _nightWatch.setMergePaused(false);
        _nightWatch.clearTokenData();

        // Fill arbitrary token data
        uint24[] memory tokenData = new uint24[](15);
        tokenData[0] = 14221313;
        tokenData[1] = 14221314;
        tokenData[2] = 3637249;
        tokenData[3] = 3637250;
        tokenData[4] = 163841;
        tokenData[5] = 163842;
        tokenData[6] = 1015809;
        tokenData[7] = 1015810;
        tokenData[8] = 1605633;
        tokenData[9] = 1605634;
        tokenData[10] = 2260993;
        tokenData[11] = 2260994;
        tokenData[12] = 3637264;
        tokenData[13] = 3638272;
        tokenData[14] = 3641360;
        _nightWatch.fillTokenData(tokenData);

        // Create token array to merge the specified tokens
        uint256[][] memory tokenArray = new uint256[][](6);
        for (uint256 i = 0; i < 6; i++) {
            tokenArray[i] = new uint256[](2);
            for (uint256 j = 0; j < 2; j++) {
                tokenArray[i][j] = (i * 2) + j;
            }
        }

        // Merge the tokens in the token array
        _nightWatch.tryMergeTokenArray(tokenArray);

        // Ensure merge happened
        assertEq(_nightWatch.totalSupply(), 9);

        // Send set 434 with frame 1 and 2 to account 3
        vm.prank(address(0x1));
        _nightWatch.transferFrom(address(0x1), address(0x2), 0);

        // Ensure nothing merged
        assertEq(_nightWatch.totalSupply(), 9);

        // Send set 111 with frame 1 and 2 to account 8 which has frame 5 of the same set
        vm.prank(address(0x2));
        _nightWatch.transferFrom(address(0x2), address(0x7), 2);

        // Ensure merge happened
        assertEq(_nightWatch.totalSupply(), 8);

        // Send set 111 with frame 10 to account 8 which now has frame 1,2,5 of the same set
        vm.prank(address(0x8));
        _nightWatch.transferFrom(address(0x8), address(0x7), 13);

        // Ensure merge happened
        assertEq(_nightWatch.totalSupply(), 7);

        // Send set 111 with frame 1,2,5 to account 10 which has frame 13 of set 111
        vm.prank(address(0x7));
        _nightWatch.transferFrom(address(0x7), address(0x9), 2);

        // Ensure merge happened
        assertEq(_nightWatch.totalSupply(), 6);
    }

    function testMergeDuringTransferPause() public {
        // Mint set 434, frame 1 and 2
        _nightWatch.mint(address(0x1), 2);

        // Resume merge and clear token data
        _nightWatch.setMergePaused(false);
        _nightWatch.clearTokenData();

        // Fill arbitrary token data
        uint24[] memory tokenData = new uint24[](2);
        tokenData[0] = 14221313;
        tokenData[1] = 14221314;
        _nightWatch.fillTokenData(tokenData);

        // Pause transfers
        _nightWatch.setTransfersPaused(true);

        // Try to transfer and get reverted
        vm.prank(address(0x1));
        vm.expectRevert(NightWatch.CannotTransferDuringTransferPause.selector);
        _nightWatch.transferFrom(address(0x1), address(0x2), 0);

        // Ensure nothing merged
        assertEq(_nightWatch.totalSupply(), 2);

        // Create token array to merge the specified tokens
        uint256[][] memory tokenArray = new uint256[][](1);
        tokenArray[0] = new uint256[](2);
        tokenArray[0][0] = 0;
        tokenArray[0][1] = 1;
        _nightWatch.tryMergeTokenArray(tokenArray);

        // Ensure merge happened
        assertEq(_nightWatch.totalSupply(), 1);
    }

    function testMergeWithTransfersWithRealisticData() public {
        // Load pre-generated tokenData and tokensArray from json files
        uint24[] memory tokenData = _utils.getTokenData("tokenData_1");
        uint256[][] memory tokensArray = _utils.getTokensArray("tokensArray_1");

        // Create 2047 arbitrary addresses
        address[] memory addresses = _utils.createUsers(2047);

        // Mint 682 tokens to reserve address
        _nightWatch.mint(address(0x45678), 682);

        // Mint 3 tokens for 2047 addresses
        for (uint256 i = 0; i < 2047; i++) {
            _nightWatch.mint(addresses[i], 3);
        }

        // Mint the leftover tokens to a random address
        _nightWatch.mint(address(0x66945), 2);

        // Ensure the project is minted out
        assertEq(_nightWatch.totalSupply(), _maxSupply);

        // Fill token data and resume merge
        _nightWatch.fillTokenData(tokenData);
        _nightWatch.setMergePaused(false);

        // Merge the tokens in the token array
        _nightWatch.tryMergeTokenArray(tokensArray);

        // Ensure the merges happened
        assertEq(_nightWatch.totalSupply(), _maxSupply - 333);

        // Transfer the token 305 to merge
        address ownerOf305 = _nightWatch.ownerOf(305);
        address ownerOf4232 = _nightWatch.ownerOf(4232);
        vm.prank(ownerOf305);
        _nightWatch.transferFrom(ownerOf305, ownerOf4232, 305);

        // Ensure merge happened
        assertEq(_nightWatch.totalSupply(), _maxSupply - 334);
    }

    function testTransferWhenTokenDataNotFilled() public {
        // Mint two tokens to two different addresses
        _nightWatch.mint(address(0x1), 1);
        _nightWatch.mint(address(0x2), 1);
        assertEq(_nightWatch.totalSupply(), 2);

        // Resume merge and clear token data
        _nightWatch.setMergePaused(false);
        _nightWatch.clearTokenData();

        // Try to transfer and get reverted
        vm.expectRevert(NightWatch.TokenDataNotFilled.selector);
        vm.prank(address(0x1));
        _nightWatch.transferFrom(address(0x1), address(0x2), 0);
    }

    function testTryMergeWhenTokenDataNotFilled() public {
        // Mint two tokens to two different addresses
        _nightWatch.mint(address(0x1), 1);
        _nightWatch.mint(address(0x2), 1);
        assertEq(_nightWatch.totalSupply(), 2);

        // Resume merge and clear token data
        _nightWatch.setMergePaused(false);
        _nightWatch.clearTokenData();

        // Try to merge and get reverted
        vm.expectRevert(NightWatch.TokenDataNotFilled.selector);
        uint256[][] memory tokenArray = new uint256[][](1);
        tokenArray[0] = new uint256[](2);
        tokenArray[0][0] = 0;
        tokenArray[0][1] = 1;
        _nightWatch.tryMergeTokenArray(tokenArray);
    }

    function testTryMergeWrongTokenOrder() public {
        // Mint two tokens to two different addresses
        _nightWatch.mint(address(0x1), 1);
        _nightWatch.mint(address(0x2), 1);
        assertEq(_nightWatch.totalSupply(), 2);

        // Resume merge and clear token data
        _nightWatch.setMergePaused(false);
        _nightWatch.clearTokenData();

        // Try to merge and get reverted
        vm.expectRevert(NightWatch.WrongTokenOrder.selector);
        uint256[][] memory tokenArray = new uint256[][](1);
        tokenArray[0] = new uint256[](2);
        tokenArray[0][0] = 1;
        tokenArray[0][1] = 0;
        _nightWatch.tryMergeTokenArray(tokenArray);
    }

    function testTryMergeSetMismatch() public {
        // Mint two tokens to two different addresses
        _nightWatch.mint(address(0x1), 1);
        _nightWatch.mint(address(0x2), 1);
        assertEq(_nightWatch.totalSupply(), 2);

        // Resume merge
        _nightWatch.setMergePaused(false);

        // Fill arbitrary token data with mismatching set
        uint24[] memory tokenData = new uint24[](2);
        tokenData[0] = 1;
        tokenData[1] = 2333332;
        _nightWatch.fillTokenData(tokenData);

        // Try to merge and get reverted
        vm.expectRevert(NightWatch.SetMismatch.selector);
        uint256[][] memory tokenArray = new uint256[][](1);
        tokenArray[0] = new uint256[](2);
        tokenArray[0][0] = 0;
        tokenArray[0][1] = 1;
        _nightWatch.tryMergeTokenArray(tokenArray);
    }

    function testTryMergeTokenOwnerMismatch() public {
        // Mint two tokens to two different addresses
        _nightWatch.mint(address(0x1), 1);
        _nightWatch.mint(address(0x2), 1);
        assertEq(_nightWatch.totalSupply(), 2);

        // Resume merge
        _nightWatch.setMergePaused(false);

        // Fill arbitrary token data with same set
        uint24[] memory tokenData = new uint24[](2);
        tokenData[0] = 1;
        tokenData[1] = 2;
        _nightWatch.fillTokenData(tokenData);

        // Try to merge and get reverted
        vm.expectRevert(NightWatch.TokenOwnerMismatch.selector);
        uint256[][] memory tokenArray = new uint256[][](1);
        tokenArray[0] = new uint256[](2);
        tokenArray[0][0] = 0;
        tokenArray[0][1] = 1;
        _nightWatch.tryMergeTokenArray(tokenArray);
    }

    function testTotalMergeUpdates() public {
        // Min two tokens to two different addresses
        _nightWatch.mint(address(0x1), 1);
        _nightWatch.mint(address(0x2), 1);
        assertEq(_nightWatch.totalSupply(), 2);

        // Resume merge and clear token data
        _nightWatch.setMergePaused(false);
        _nightWatch.clearTokenData();

        // Fill arbitrary token data
        uint24[] memory contents = new uint24[](2);
        contents[0] = 1146882;
        contents[1] = 1146884;
        _nightWatch.fillTokenData(contents);

        // Transfer to merge
        vm.prank(address(0x1));
        _nightWatch.transferFrom(address(0x1), address(0x2), 0);

        // Ensure merge happened
        assertEq(_nightWatch.totalMergeCount(), 1);
    }

    /*//////////////////////////////////////////////////////////////
                                WITHDRAW
    //////////////////////////////////////////////////////////////*/

    function testWithdrawWithLowBalance() public {
        vm.deal(address(_nightWatch), 0.01 ether);
        uint256 initialBalance = address(0x666).balance;
        _nightWatch.withdraw(address(0x666), address(_nightWatch).balance);
        assertEq(address(0x666).balance, initialBalance + 0.01 ether);
    }

    function testWithdrawWithHighBalance() public {
        vm.deal(address(_nightWatch), 1000 ether);
        uint256 initialBalance = address(0x666).balance;
        _nightWatch.withdraw(address(0x666), address(_nightWatch).balance);
        assertEq(address(0x666).balance, initialBalance + 1000 ether);
    }

    function testWithdrawZeroAddressFails() public {
        vm.expectRevert(NightWatch.CannotWithdrawToZeroAddress.selector);
        _nightWatch.withdraw(address(0x0), address(_nightWatch).balance);
    }

    function testWithdrawNoFundsFails() public {
        vm.expectRevert(NightWatch.NoFunds.selector);
        _nightWatch.withdraw(address(0x455), 0);

        vm.expectRevert(NightWatch.NoFunds.selector);
        _nightWatch.withdraw(address(0x455), 1 ether);
    }

    function testWithdrawERC20WithLowBalance() public {
        MockERC20 testErc20 = new MockERC20("test", "test", 18);
        testErc20.mint(address(_nightWatch), 0.01 ether);

        uint256 initialBalance = testErc20.balanceOf(address(0x666));
        _nightWatch.withdrawERC20(
            address(0x666),
            testErc20.balanceOf(address(_nightWatch)),
            testErc20
        );

        assertEq(
            testErc20.balanceOf(address(0x666)),
            initialBalance + 0.01 ether
        );
    }

    function testWithdrawERC20WithHighBalance() public {
        MockERC20 testErc20 = new MockERC20("test", "test", 18);
        testErc20.mint(address(_nightWatch), 1000 ether);

        uint256 initialBalance = testErc20.balanceOf(address(0x666));
        _nightWatch.withdrawERC20(
            address(0x666),
            testErc20.balanceOf(address(_nightWatch)),
            testErc20
        );

        assertEq(
            testErc20.balanceOf(address(0x666)),
            initialBalance + 1000 ether
        );
    }

    function testWithdrawERC20ZeroAddressFails() public {
        MockERC20 testErc20 = new MockERC20("test", "test", 18);
        testErc20.mint(address(_nightWatch), 1000 ether);
        uint256 balance = testErc20.balanceOf(address(_nightWatch));
        vm.expectRevert(NightWatch.CannotWithdrawToZeroAddress.selector);
        _nightWatch.withdrawERC20(address(0), balance, testErc20);
    }

    function testWithdrawERC20NoFundsFails() public {
        MockERC20 testErc20 = new MockERC20("test", "test", 18);

        vm.expectRevert(NightWatch.NoFunds.selector);
        _nightWatch.withdrawERC20(address(0x455), 0, testErc20);

        vm.expectRevert(NightWatch.NoFunds.selector);
        _nightWatch.withdrawERC20(address(0x455), 1 ether, testErc20);
    }

    /*//////////////////////////////////////////////////////////////
                              EVENT CHECKS
    //////////////////////////////////////////////////////////////*/

    event FirstStep();

    function testFirstStepEvent() public {
        vm.expectEmit(false, false, false, false);
        emit FirstStep();
        _deployNightWatch();
    }

    event MergePaused(bool isPaused);

    function testMergePausedEvent() public {
        vm.expectEmit(true, false, false, false);
        emit MergePaused(true);
        _nightWatch.setMergePaused(true);
        vm.expectEmit(true, false, false, false);
        emit MergePaused(false);
        _nightWatch.setMergePaused(false);
    }

    event TransfersPaused(bool isPaused);

    function testTransfersPausedEvent() public {
        vm.expectEmit(true, false, false, false);
        emit TransfersPaused(true);
        _nightWatch.setTransfersPaused(true);
        vm.expectEmit(true, false, false, false);
        emit TransfersPaused(false);
        _nightWatch.setTransfersPaused(false);
    }

    event MetadataAddressChanged(address newAddress);

    function testMetadataAddressChanged() public {
        vm.expectEmit(true, false, false, false);
        emit MetadataAddressChanged(address(0x1));
        _nightWatch.setMetadataAddress(address(0x1));
        vm.expectEmit(true, false, false, false);
        emit MetadataAddressChanged(address(0x2));
        _nightWatch.setMetadataAddress(address(0x2));
    }

    event BatchMetadataUpdate(uint256 fromTokenId, uint256 toTokenId);

    function testBatchMetadataUpdate() public {
        _nightWatch.mint(address(0x1), 100);
        vm.expectEmit(true, false, false, false);
        emit BatchMetadataUpdate(0, 99);
        _nightWatch.setMetadataAddress(address(0));
    }

    event Merge(
        uint256 indexed tokenId,
        uint256 indexed tokenIdBurned,
        uint256 oldTokenData,
        uint256 updatedTokenData,
        address owner
    );

    function testMergeEventEmits() public {
        // Fill arbitrary token data
        uint24[] memory tokenData = _utils.getTokenData("tokenData_1");
        _nightWatch.fillTokenData(tokenData);

        // Cancel merge pause
        _nightWatch.setMergePaused(false);

        // Mint all to vault
        _nightWatch.mintRemainingSupplyToVault();
        assertEq(_nightWatch.totalSupply(), _maxSupply);

        // Transfer two tokens that will be merged from vault to account 0x455
        vm.startPrank(_VAULT_ADDRESS);
        _nightWatch.transferFrom(_VAULT_ADDRESS, address(0x455), 305);

        vm.expectEmit(true, true, false, false);
        emit Merge(305, 4232, 0, 0, address(0x455));
        _nightWatch.transferFrom(_VAULT_ADDRESS, address(0x455), 4232);
    }

    /*//////////////////////////////////////////////////////////////
                              VAULT CHECKS
    //////////////////////////////////////////////////////////////*/

    function testTransferMergedTokenToVault() public {
        // Fill arbitrary token data
        uint24[] memory tokenData = _utils.getTokenData("tokenData_1");
        _nightWatch.fillTokenData(tokenData);

        // Cancel merge pause
        _nightWatch.setMergePaused(false);

        // Mint all to vault
        _nightWatch.mintRemainingSupplyToVault();
        assertEq(_nightWatch.totalSupply(), _maxSupply);

        // Transfer two tokens that will be merged from vault to account 0x455
        vm.startPrank(_VAULT_ADDRESS);
        _nightWatch.transferFrom(_VAULT_ADDRESS, address(0x455), 305);
        _nightWatch.transferFrom(_VAULT_ADDRESS, address(0x455), 4232);
        vm.stopPrank();

        // Make sure the tokens are transferred and the merge happened
        assertEq(_nightWatch.totalSupply(), _maxSupply - 1);

        // Transfer the merged token back to the vault
        vm.prank(address(0x455));
        _nightWatch.transferFrom(address(0x455), _VAULT_ADDRESS, 305);

        // Make sure the transfer happened
        assertEq(_nightWatch.balanceOf(address(0x455)), 0);

        // Make sure the merge did not happen in the vault
        assertEq(_nightWatch.totalSupply(), _maxSupply - 1);
    }

    function testMergeInVaultAddressFails() public {
        // Fill arbitrary token data
        uint24[] memory tokenData = _utils.getTokenData("tokenData_1");
        _nightWatch.fillTokenData(tokenData);

        // Cancel merge pause
        _nightWatch.setMergePaused(false);

        // Mint all to vault
        _nightWatch.mintRemainingSupplyToVault();
        assertEq(_nightWatch.totalSupply(), _maxSupply);

        vm.expectRevert(NightWatch.CannotMergeForVaultAddress.selector);
        _nightWatch.tryMergeTwoTokens(305, 4232);
    }

    function testVaultAddressCantBeZero() public {
        vm.expectRevert(NightWatch.NoZeroAddress.selector);
        new NightWatch(address(0x666), address(0), 500, address(0x423));

        vm.expectRevert(NightWatch.NoZeroAddress.selector);
        _nightWatch.setVaultAddress(address(0));
    }

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP CHECKS
    //////////////////////////////////////////////////////////////*/

    function testGetOwnedTokens() public {
        uint256 nextToken = _nightWatch.getNextToken();
        _nightWatch.mint(address(0x1), 1);
        _nightWatch.mint(address(0x2), 3);
        _nightWatch.mint(address(0x3), 7);
        _nightWatch.mint(address(0x1), 1);
        assertEq(_nightWatch.getOwnedTokens(address(0x1))[0], nextToken);
        assertEq(_nightWatch.getOwnedTokens(address(0x2))[0], nextToken + 1);
        assertEq(_nightWatch.getOwnedTokens(address(0x3))[0], nextToken + 4);
        assertEq(_nightWatch.getOwnedTokens(address(0x1))[1], nextToken + 11);
    }

    function testOwnershipAfterTransfer() public {
        // Mint out
        _nightWatch.mintRemainingSupplyToVault();

        // Make sure 0x1 has 0 tokens
        assertEq(_nightWatch.balanceOf(address(0x1)), 0);

        // Transfer token 305 from vault to 0x1
        vm.prank(_VAULT_ADDRESS);
        _nightWatch.transferFrom(_VAULT_ADDRESS, address(0x1), 305);

        // Ensure ownership has changed
        assertEq(_nightWatch.balanceOf(address(0x1)), 1);
        assertEq(_nightWatch.getOwnedTokens(address(0x1))[0], 305);
    }

    function testOwnershipAfterTransferToVaultAddress() public {
        // Mint 10 tokens to 0x1
        _nightWatch.mint(address(0x1), 10);
        assertEq(_nightWatch.balanceOf(address(0x1)), 10);

        // Transfer token 1 to the vault
        vm.prank(address(0x1));
        _nightWatch.transferFrom(address(0x1), _VAULT_ADDRESS, 1);
        assertEq(_nightWatch.balanceOf(address(0x1)), 9);
        assertEq(_nightWatch.balanceOf(_VAULT_ADDRESS), 1);

        // Ensure ownership is not on 0x1 anymore
        uint256[] memory ownedTokens = _nightWatch.getOwnedTokens(address(0x1));
        for (uint256 i = 0; i < ownedTokens.length; i++) {
            assert(ownedTokens[i] != 1);
        }
    }

    function testOwnershipAfterBurn() public {
        // Resume merge
        _nightWatch.setMergePaused(false);

        // Fill arbitrary token data
        uint24[] memory tokenData = new uint24[](1);
        _nightWatch.fillTokenData(tokenData);

        // Mint a token to 0x1
        _nightWatch.mint(address(0x1), 1);
        assertEq(_nightWatch.balanceOf(address(0x1)), 1);

        // Burn token 0
        vm.prank(address(0x1));
        _nightWatch.burn(0);
        assertEq(_nightWatch.balanceOf(address(0x1)), 0);

        // Make sure 0x1 owns nothing anymore
        uint256[] memory ownedTokens = _nightWatch.getOwnedTokens(address(0x1));
        assertEq(ownedTokens.length, 0);
    }

    function testOwnershipAfterBurnMultipleTokens() public {
        // Fill pre-generated token data
        uint24[] memory tokenData = _utils.getTokenData("tokenData_1");
        _nightWatch.fillTokenData(tokenData);

        // Mint 10 tokens to 0x1
        _nightWatch.mint(address(0x1), 10);
        assertEq(_nightWatch.balanceOf(address(0x1)), 10);

        // Resume merge
        _nightWatch.setMergePaused(false);

        // Burn token 0
        vm.prank(address(0x1));
        _nightWatch.burn(0);
        assertEq(_nightWatch.balanceOf(address(0x1)), 9);

        // Make sure 0x1 doesn't own token 0 anymore
        uint256[] memory ownedTokens = _nightWatch.getOwnedTokens(address(0x1));
        assertEq(ownedTokens.length, 9);
        for (uint256 i = 0; i < ownedTokens.length; i++) {
            assert(ownedTokens[i] != 0);
        }
    }

    function testGetOwnedTokensQueryZeroAddress() public {
        vm.expectRevert(NightWatch.CannotQueryZeroAddress.selector);
        _nightWatch.getOwnedTokens(address(0x0));
    }

    function testGetOwnedTokensQueryVaultAddress() public {
        vm.expectRevert(NightWatch.CannotQueryVaultAddress.selector);
        _nightWatch.getOwnedTokens(_VAULT_ADDRESS);
    }
}
