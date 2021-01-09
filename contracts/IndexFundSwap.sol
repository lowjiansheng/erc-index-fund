// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import {
    IUniswapV2Router02
} from "@uniswap/v2-periphery/contracts/UniswapV2Router02.sol";

// This contract is responsible for interacting with Uniswap
contract IndexFundSwap {
    IUniswapV2Router02 internal uniswap;

    event Swapped(uint256 amountEth, address user);

    constructor() public {
        uniswap = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
    }

    function swapEthForToken(address tokenAddress, uint256 amountEthToSwap)
        public
    {
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = tokenAddress;

        uniswap.swapExactETHForTokens(
            amountEthToSwap,
            path,
            msg.sender,
            block.timestamp
        );

        emit Swapped(amountEthToSwap, msg.sender);
    }
}
