// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Script} from "forge-std/Script.sol";
import {NightWatchMetadata} from "../src/NightWatchMetadata.sol";
import {Utilities} from "../test/utils/Utilities.sol";

/// @title TransferOwnership Script for Night Watch
/// @author  @YigitDuman
contract TransferNightWatchOwnership is Script {
    Utilities public utils;
    NightWatchMetadata public nightWatchMetadata;

    function run() external {
        utils = new Utilities();
        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address nwAddress = vm.envAddress(
            "NIGHT_WATCH_METADATA_CONTRACT_ADDRESS"
        );

        nightWatchMetadata = NightWatchMetadata(nwAddress);

        vm.startBroadcast(privateKey);
        nightWatchMetadata.transferOwnership(
            address(0xB293067C7198eDda9d41173fb30C65744094804e)
        );
        vm.stopBroadcast();
    }
}
