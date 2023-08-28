// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Script} from "forge-std/Script.sol";
import {NightWatch} from "../src/NightWatch.sol";
import {NightWatchVendor} from "../src/NightWatchVendor.sol";

/// @title Deploy Script for Night Watch Vendor
/// @author @YigitDuman
contract DeployVendor is Script {
    function run() external {
        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address vaultAddress = vm.envAddress("VAULT_ADDRESS");
        address vendorSignerAddress = vm.envAddress("VENDOR_SIGNER_ADDRESS");
        address partnerAAddress = vm.envAddress("PARTNER_A_ADDRESS");
        address partnerBAddress = vm.envAddress("PARTNER_B_ADDRESS");

        NightWatch nightWatch = NightWatch(
            vm.envAddress("NIGHT_WATCH_CONTRACT_ADDRESS")
        );

        // Deploy the Night Watch Vendor contract
        vm.startBroadcast(privateKey);
        new NightWatchVendor(
            nightWatch,
            vaultAddress,
            vendorSignerAddress,
            partnerAAddress,
            partnerBAddress,
            6825
        );
        vm.stopBroadcast();
    }
}
