// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../tools/chainlink/AggregatorV3Interface.sol";

/// @title Chainlink Data Feed
/// @author Souldev Network
/// @notice Gets price of token from Chainlink oracle
/// @dev Yet to be integrated to check against v3 twap

contract ChainlinkPriceFeed {

    AggregatorV3Interface internal ETHprice;
    AggregatorV3Interface internal BTCprice;
    AggregatorV3Interface internal LINKprice;
    AggregatorV3Interface internal SOLprice;
    AggregatorV3Interface internal MATICprice;

    constructor() {
        ETHprice = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        BTCprice = AggregatorV3Interface(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c);
        LINKprice = AggregatorV3Interface(0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c);
        SOLprice = AggregatorV3Interface(0x4ffC43a60e009B551865A93d232E33Fce9f01507);
        MATICprice = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);
    }

    function PriceETH() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = ETHprice.latestRoundData();
        return price;
    }

    function PriceBTC() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = BTCprice.latestRoundData();
        return price;
    }

    function PriceLink() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = LINKprice.latestRoundData();
        return price;
    }

    function PriceSol() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = SOLprice.latestRoundData();
        return price;
    }

    function PriceMatic() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = MATICprice.latestRoundData();
        return price;
    }

    
}