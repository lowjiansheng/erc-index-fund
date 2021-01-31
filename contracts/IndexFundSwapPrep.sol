// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import {
    UniswapV2Router02
} from "@uniswap/v2-periphery/contracts/UniswapV2Router02.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// This contract prepares the test environment for Uniswap
// 1 contract will be used for 1 pair
// TODO: is this too much?
contract IndexFundSwapPrep {
    using SafeMath for uint256;

    UniswapV2Router02 internal uniswapRouter;
    IUniswapV2Factory internal uniswapFactory;

    string public contractName;
    address public WETHAdd;
    address public contractOwner;

    uint256 public pairTotalSupply;
    address public pairAddress;

    event Swapped(uint256 amountEth, address user);
    event FetchedWETHAddress(address user);
    event ETHPairCreated();
    event LiquidityAdded();
    event AmountOut(uint256 amountOut);

    event DebugEvent(uint256 debugAmount);

    constructor() public {
        contractName = "IndexFundSwapPrep";
        contractOwner = msg.sender;
        // mainnet addresses
        uniswapRouter = UniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapFactory = IUniswapV2Factory(
            0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
        );

        WETHAdd = uniswapRouter.WETH();

        emit FetchedWETHAddress(msg.sender);
    }

    // make sure that amountETHInput < msg.value, if not transaction will be rejected
    function setupWETHTokenPair(
        address token,
        uint256 amountETHInput,
        uint256 amountTokenDesired
    ) public payable {
        IERC20 mockToken = IERC20(token);
        mockToken.transferFrom(msg.sender, address(this), amountTokenDesired);

        require(
            mockToken.approve(address(uniswapRouter), amountTokenDesired),
            "approve failed"
        );
        createWETHPair(token);

        uniswapRouter.addLiquidityETH{value: msg.value}(
            token,
            amountTokenDesired,
            amountTokenDesired,
            amountETHInput,
            msg.sender,
            block.timestamp + 300
        );
        emit LiquidityAdded();
    }

    function createWETHPair(address token) private {
        pairAddress = uniswapFactory.createPair(token, WETHAdd);
        emit ETHPairCreated();
    }

    function estimateAmountOut(address token, uint256 amountIn) public {
        address[] memory path = new address[](2);
        path[0] = this.WETHAdd();
        path[1] = token;
        uint256[] memory amountOut =
            uniswapRouter.getAmountsOut(amountIn, path);
        emit AmountOut(amountOut[0]);
    }

    function pairInformation(address tokenA, address tokenB)
        public
        returns (uint256)
    {
        IUniswapV2Pair pair =
            IUniswapV2Pair(
                UniswapV2Library.pairFor(
                    address(uniswapFactory),
                    tokenA,
                    tokenB
                )
            );
        pairTotalSupply = pair.totalSupply();

        return pairTotalSupply;
    }

    // this function is used for testing
    // wrapper function

    function swapETHForToken(address tokenAddress, uint256 amountEthToSwap)
        public
        payable
    {
        address[] memory path = new address[](2);
        path[0] = this.WETHAdd();
        path[1] = tokenAddress;

        uniswapRouter.swapExactETHForTokens{value: msg.value}(
            amountEthToSwap,
            path,
            msg.sender,
            block.timestamp + 500
        );

        emit Swapped(amountEthToSwap, msg.sender);
    }
}
