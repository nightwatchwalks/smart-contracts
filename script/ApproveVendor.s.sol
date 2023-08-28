// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Script} from "forge-std/Script.sol";
import {NightWatch} from "../src/NightWatch.sol";

/// @title Approve Vendor for Night Watch
/// @author @YigitDuman
contract ApproveVendor is Script {
    function run() external {
        uint256 privateKey = vm.envUint("VAULT_ADDRESS_PRIVATE_KEY");
        NightWatch nightWatch = NightWatch(
            vm.envAddress("NIGHT_WATCH_CONTRACT_ADDRESS")
        );

        vm.startBroadcast(privateKey);
        nightWatch.setApprovalForAll(
            vm.envAddress("NIGHT_WATCH_VENDOR_CONTRACT_ADDRESS"),
            true
        );
        vm.stopBroadcast();
    }
}
