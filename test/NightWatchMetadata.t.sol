// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Test} from "forge-std/Test.sol";
import {NightWatch} from "../src/NightWatch.sol";
import {NightWatchMetadata} from "../src/NightWatchMetadata.sol";

/// @title Night Watch Metadata Tests
/// @author @YigitDuman
contract NightWatchMetadataTest is Test {
    NightWatch private _nightWatch;
    NightWatchMetadata private _nightWatchMetadata;

    function setUp() public {
        _nightWatchMetadata = new NightWatchMetadata("");
        _nightWatch = new NightWatch(
            address(_nightWatchMetadata),
            address(0x423),
            500,
            address(0x6825)
        );
    }

    function testSetBaseURIOwnerOnly() public {
        _nightWatchMetadata.setBaseURI("test");
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(address(0x1));
        _nightWatchMetadata.setBaseURI("test");
    }

    function testTokenUriCorrectness() public {
        _nightWatchMetadata.setBaseURI("a");
        assertEq(_nightWatchMetadata.tokenURI(1), "a1");
        _nightWatchMetadata.setBaseURI("b");
        assertEq(_nightWatchMetadata.tokenURI(2), "b2");
        _nightWatchMetadata.setBaseURI("https://www.google.com/");
        assertEq(_nightWatchMetadata.tokenURI(0), "https://www.google.com/0");
        _nightWatchMetadata.setBaseURI("ipfs://nightwatchwalks/");
        assertEq(_nightWatchMetadata.tokenURI(0), "ipfs://nightwatchwalks/0");
    }
}
