// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Script} from "forge-std/Script.sol";
import {NightWatchMetadata} from "../src/NightWatchMetadata.sol";
import {NightWatch} from "../src/NightWatch.sol";

/// @title Update metadata script for Night Watch
/// @author @YigitDuman
contract UpdateMetadata is Script {
    function run() external {
        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        NightWatchMetadata nightWatchMetadata = NightWatchMetadata(
            vm.envAddress("NIGHT_WATCH_METADATA_CONTRACT_ADDRESS")
        );
        NightWatch nightWatch = NightWatch(
            vm.envAddress("NIGHT_WATCH_CONTRACT_ADDRESS")
        );

        vm.startBroadcast(privateKey);
        nightWatchMetadata.setBaseURI(
            "https://q558ifducp.us-east-1.awsapprunner.com/get/"
        );
        vm.stopBroadcast();

        vm.startBroadcast(privateKey);
        nightWatch.setMetadataAddress(address(nightWatchMetadata));
        vm.stopBroadcast();
    }
}
