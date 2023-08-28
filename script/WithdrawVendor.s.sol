// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Script} from "forge-std/Script.sol";
import {NightWatchVendor} from "../src/NightWatchVendor.sol";

/// @title Withdraw script for Night Watch Vendor
/// @author @YigitDuman
contract WithdrawVendor is Script {
    function run() external {
        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        NightWatchVendor nightWatchVendor = NightWatchVendor(
            payable(vm.envAddress("NIGHT_WATCH_VENDOR_CONTRACT_ADDRESS"))
        );

        // Deploy the Night Watch Vendor contract
        vm.startBroadcast(privateKey);
        nightWatchVendor.withdraw(address(nightWatchVendor).balance);
        vm.stopBroadcast();
    }
}
