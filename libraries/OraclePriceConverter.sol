// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// convert price given by oracle to 1e18 base

library OracleConverter {

    // uniswaptwap
    function UNIto1e18(uint price) public pure returns (int) {
        price *= 1e12;
        return int(price);
    }

    // chainlink
    function LINKto1e18(int price) public pure returns (int) {
        price *= 1e10;
        return price;
    }
}
