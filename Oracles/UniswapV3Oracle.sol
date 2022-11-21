//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../tools/uniswap-0.8/IUniswapV3Factory.sol";
import "../tools/uniswap-0.8/OracleLibrary.sol";

/// @title Uniswap V3 Oracle 
/// @author Souldev Network
/// @notice Gets price of token0 in terms of token1 from Uniswap V3 twap oracle
/// @dev Warning: not tested with ERC20 tokens with non-base 1e18 

contract UniswapV3twap {

    address public immutable _factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    // @dev gets pool address of token pair on uniswap v3
    function getPool(address token0, address token1, uint24 fee) internal view returns (address) {
        address pool = IUniswapV3Factory(_factory).getPool(
            token0,
            token1,
            fee
        );
        require(pool != address(0), "pool doesn't exist");
        return pool;
    }

    // @dev gets price of tokenIn in terms of tokenOut
    function estimateAmountOut(
        address tokenIn,
        uint128 amountIn,
        uint32 secondsAgo,
        address tokenOut

    ) public view returns (uint amountOut) {

        // 0.3% fee
        // @dev users need to be able to change fee
        address pool = getPool(tokenIn,tokenOut,3000);

        // Code copied from OracleLibrary.sol, consult()
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(pool).observe(
            secondsAgos
        );

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];

        int24 tick = int24(tickCumulativesDelta / int56(uint56(secondsAgo)));

        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int56(uint56(secondsAgo)) != 0)) tick--;

        amountOut = OracleLibrary.getQuoteAtTick(
            tick,
            amountIn,
            tokenIn,
            tokenOut
        );
    }
}