// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Script} from "forge-std/Script.sol";
import {NightWatchVendor} from "../src/NightWatchVendor.sol";

/// @title Claim Tokens for Night Watch Vendor
/// @author @YigitDuman
contract ClaimTokens is Script {
    function run() external {
        uint256 privateKey = 0x0;
        address receiver = address(0x0);
        NightWatchVendor nightWatchVendor = NightWatchVendor(
            vm.envAddress("NIGHT_WATCH_VENDOR_CONTRACT_ADDRESS")
        );

        uint16[] memory tokens = new uint16[](1);
        tokens[0] = 393;

        bytes
            memory signature = hex"9cd4cad2b64a2976a8a257840e9504bf6c9933d463dd661ca8490f27a9830f96505ad8d6c6a5df956ba0127b5b07f77ba32f54afde5872787a2efff1f1e364731c";

        vm.startBroadcast(privateKey);
        nightWatchVendor.claimTokens(receiver, tokens, signature);
        vm.stopBroadcast();
    }
}
