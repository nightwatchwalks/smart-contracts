// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Test} from "forge-std/Test.sol";

/// @title Utilities for testing
/// @author @YigitDuman
contract Utilities is Test {
    bytes32 private _nextUser = keccak256(abi.encodePacked("user address"));

    function getNextUserAddress() external returns (address user) {
        user = address(uint160(uint256(_nextUser)));
        _nextUser = keccak256(abi.encodePacked(_nextUser));
    }

    function createUsers(
        uint256 userNum
    ) external returns (address[] memory users) {
        users = new address[](userNum);
        for (uint256 i = 0; i < userNum; ++i) {
            users[i] = this.getNextUserAddress();
        }
    }

    function getTokenData(
        string calldata id
    ) external view returns (uint24[] memory tokenData) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/test/data/", id, ".json");
        string memory json = vm.readFile(path);
        tokenData = abi.decode(vm.parseJson(json), (uint24[]));
    }

    function getTokensArray(
        string calldata id
    ) external view returns (uint256[][] memory tokensArray) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/test/data/", id, ".json");
        string memory json = vm.readFile(path);
        tokensArray = abi.decode(vm.parseJson(json), (uint256[][]));
    }

    function getMockTokens()
        external
        view
        returns (uint16[] memory mockTokens)
    {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/test/data/mockTokens.json");
        string memory json = vm.readFile(path);
        mockTokens = abi.decode(vm.parseJson(json), (uint16[]));
    }
}
