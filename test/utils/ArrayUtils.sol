// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Array Utils Library
/// @author @YigitDuman
library ArrayUtils {
    function uint24s(uint24 a) public pure returns (uint24[] memory array) {
        array = new uint24[](1);
        array[0] = a;
    }
}
