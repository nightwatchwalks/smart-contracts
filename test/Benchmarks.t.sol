// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Test} from "forge-std/Test.sol";
import {NightWatch} from "../src/NightWatch.sol";
import {Utilities} from "./utils/Utilities.sol";

/// @title NightWatch Benchmarks
/// @author @YigitDuman
contract Benchmarks is Test {
    NightWatch private _nightWatch;
    Utilities private _utils;
    address private _nightWatchMetadata =
        0x5A0d2e8C526537DFCE9BFDcED048c9B8135edA6D;

    function setUp() public {
        vm.deal(address(0x1), 100 ether);
        _utils = new Utilities();
        _nightWatch = new NightWatch(
            _nightWatchMetadata,
            address(0x423),
            500,
            address(0x6825)
        );
    }

    function testDeploy() public {
        new NightWatch(
            _nightWatchMetadata,
            address(0x423),
            500,
            address(0x6825)
        );
    }

    function testMint1() public {
        _nightWatch.mint(address(0x1), 1);
    }

    function testMint5() public {
        _nightWatch.mint(address(0x1), 5);
    }

    function testMint10() public {
        _nightWatch.mint(address(0x1), 10);
    }

    function testMint100() public {
        _nightWatch.mint(address(0x1), 100);
    }

    function testMintVault() public {
        _nightWatch.mintRemainingSupplyToVault();
    }

    function testFillTokenDataOneBatch(uint24[3413] memory tokenData) public {
        vm.pauseGasMetering();
        uint24[] memory dynamicTokenData = new uint24[](3413);
        for (uint24 i = 0; i < 3413; i++) {
            dynamicTokenData[i] = tokenData[i];
        }
        vm.resumeGasMetering();
        _nightWatch.fillTokenData(dynamicTokenData);
    }

    function testClearTokenData(uint24[6825] memory tokenData) public {
        vm.pauseGasMetering();
        uint24[] memory dynamicTokenData = new uint24[](6825);
        for (uint24 i = 0; i < 6825; i++) {
            dynamicTokenData[i] = tokenData[i];
        }
        _nightWatch.fillTokenData(dynamicTokenData);
        vm.resumeGasMetering();
        _nightWatch.clearTokenData();
    }

    function testGetOwnedTokens() public {
        vm.pauseGasMetering();
        _nightWatch.mint(address(0x1), 10);
        vm.resumeGasMetering();
        _nightWatch.getOwnedTokens(address(0x1));
    }

    function testTransferAfterMintOut() public {
        vm.pauseGasMetering();
        _spreadedMintOut();
        uint256[][] memory tokenArray = _utils.getTokensArray("tokensArray_1");
        _nightWatch.tryMergeTokenArray(tokenArray);
        address owner2771 = _nightWatch.ownerOf(2771);
        vm.prank(owner2771);
        vm.resumeGasMetering();
        _nightWatch.transferFrom(owner2771, address(0x1), 2771);
    }

    function testTransferAfterMintOutInTheSameWallet() public {
        vm.pauseGasMetering();
        _nightWatch.setVaultAddress(address(0x5693));
        _nightWatch.mintRemainingSupplyToVault();
        vm.prank(address(0x5693));
        vm.resumeGasMetering();
        _nightWatch.transferFrom(address(0x5693), address(0x1), 6799);
    }

    function _spreadedMintOut() private {
        uint24[] memory tokenData = _utils.getTokenData("tokenData_1");
        address[] memory addresses = _utils.createUsers(2047);

        _nightWatch.mint(address(0x45678), 682);

        for (uint256 i = 0; i < 2047; i++) {
            _nightWatch.mint(addresses[i], 3);
        }

        _nightWatch.mint(address(0x66945), 2);

        assertEq(_nightWatch.totalSupply(), 6825);
        _nightWatch.fillTokenData(tokenData);
        _nightWatch.setMergePaused(false);
    }

    function testTransferFromGasAfterHavingAll455SetInTheSameWallet() public {
        vm.pauseGasMetering();

        // Get token data with first 455 items have the frame 0 and incremental set number
        uint24[] memory tokenData = _utils.getTokenData("tokenData_455");

        _nightWatch.mint(address(0x455), 455);
        _nightWatch.mint(address(0x456), 1);

        assertEq(_nightWatch.totalSupply(), 456);
        _nightWatch.fillTokenData(tokenData);
        _nightWatch.setMergePaused(false);

        vm.prank(address(0x456));

        vm.resumeGasMetering();
        _nightWatch.transferFrom(address(0x456), address(0x455), 455);
    }
}
