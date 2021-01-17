// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import {
    UniswapV2Router02
} from "@uniswap/v2-periphery/contracts/UniswapV2Router02.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

// This contract is responsible for interacting with Uniswap
contract IndexFundSwap {
    UniswapV2Router02 internal uniswap;

    address factory_;
    string public contractName;
    address public WETHAdd;

    uint256 public pairTotalSupply;

    event Swapped(uint256 amountEth, address user);
    event FetchedWETHAddress(address user);

    constructor() public {
        // mainnet addresses
        uniswap = UniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        contractName = "IndexFundSwap";
        factory_ = uniswap.factory();
    }

    // debug function
    function getWETHAddress() public {
        WETHAdd = uniswap.WETH();

        emit FetchedWETHAddress(msg.sender);
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
