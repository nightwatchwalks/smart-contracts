// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Script} from "forge-std/Script.sol";
import {NightWatch} from "../src/NightWatch.sol";
import {NightWatchVendor} from "../src/NightWatchVendor.sol";
import {NightWatchMetadata} from "../src/NightWatchMetadata.sol";
import {NightWatchPaymentDivider} from "../src/NightWatchPaymentDivider.sol";

/// @title Deploy Script for Night Watch
/// @author @YigitDuman
contract Deploy is Script {
    /// @notice Base URI for token metadata
    string public metadataURI = ""; // https://q558ifducp.us-east-1.awsapprunner.com/get/

    function run() external {
        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        // Deploy payment divider contract
        vm.startBroadcast(privateKey);
        NightWatchPaymentDivider nightWatchPaymentDivider = new NightWatchPaymentDivider(
                vm.envAddress("PARTNER_A_ADDRESS"),
                vm.envAddress("PARTNER_B_ADDRESS")
            );
        vm.stopBroadcast();

        // Deploy metadata contract
        vm.startBroadcast(privateKey);
        NightWatchMetadata nightWatchMetadata = new NightWatchMetadata(
            metadataURI
        );
        vm.stopBroadcast();

        // Deploy main Night Watch contract
        vm.startBroadcast(privateKey);
        new NightWatch(
            address(nightWatchMetadata),
            vm.envAddress("VAULT_ADDRESS"),
            500,
            address(nightWatchPaymentDivider)
        );
        vm.stopBroadcast();
    }
}
