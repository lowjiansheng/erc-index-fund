// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/UniswapV2Router02.sol";

import "./IndexFundToken.sol";

// This index fund will take in Eth and buy the top 20 ERC20 tokens according to index distribution
// This is a test contract for the Kovan network
// The purchase will be triggered everyday
contract IndexFundCore {

    FundToken public indexFundToken;

    uint256 public totalDepositedEth;
    mapping(address => uint256) public userDepositedAmount;
    address[] usersDeposited;

    uint256 public totalUnwithdrawnTokens;
    mapping(address => uint256) public usersWithdrawnAmount;
    address payable[] usersWithdrawn;

    // This NAV will be calculated daily at the end of the day. Expressed in ETH.
    uint256 public nav;

    struct TokenInformation {
        uint marketCap;
        address tokenAddress;
        uint tokenBalance;
        uint tokenPrice;        
    }
    string[] public tokens;
    mapping(string => TokenInformation) tokensInformation;

    uint64 totalTokensMarketCap;

    AggregatorV3Interface internal priceFeed;
    UniswapV2Router02 internal uniswap;

    /**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     */
    constructor() {
        priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        indexFundToken = new FundToken();
        totalDepositedEth = 0;
        nav = 0;
    }

    // User calls this to deposit their Eths. The Eths do not immediately purchase the underlying tokens. These will be purchased at the end of the day.
    function depositEth() public payable {
        uint256 amountOfEthDeposited = msg.value;
        address user = msg.sender;

        userDepositedAmount[user] = amountOfEthDeposited;
        totalDepositedEth = totalDepositedEth + amountOfEthDeposited;
    }

    // Users will call this function to redeem their tokens for Eth. Their tokens will be held by the contract until end of day.
    // The final amount of Eth that can be redeemed will be determined by the NAV at the end of the day.
    // amountToWithdraw is the number of units of Fund Tokens to be withdrawn
    function redeemFunds(uint32 amountToWithdraw) public payable {
        totalUnwithdrawnTokens = totalUnwithdrawnTokens + amountToWithdraw;
        usersWithdrawnAmount[msg.sender] = amountToWithdraw;
        usersWithdrawn.push(msg.sender);

        // contract will withhold the token amount first until end of day
        indexFundToken.transferFrom(msg.sender, address(this), amountToWithdraw);
    }

    /** 
    fundManagement should only be at the end of the day. 
    It does all the maintenance work for the fund. 
    Purchase units for new token holders.
    Redeem units for any new redemptions.
    Calculates new NAV.
     */
    // TODO: come up with a fee mechanism to pay for gas
    function fundManagement() public payable {
        if (nav == 0) {
            // then number of tokens should be 0 as well. else the contract is broken
            assert(indexFundToken.totalSupply() == 0);

            initialPurchaseAndTokenValuation();
        } else {
            purchaseAndRedeem();
        }
    }

    function initialPurchaseAndTokenValuation() private {
        // buy underlying tokens

        nav = calculateCurrentNAV();
        
        // Always mint 100 tokens as a base value
        uint256 navPerToken = nav / 100;

        for (uint i = 0; i < usersDeposited.length; i++) {
            indexFundToken.mintToken(usersDeposited[i], userDepositedAmount[usersDeposited[i]] / navPerToken);
            
            delete userDepositedAmount[usersDeposited[i]];
            delete usersDeposited[i];
        }
        totalDepositedEth = 0;

    }

    function purchaseAndRedeem() private {

        nav = calculateCurrentNAV();

        uint256 navPerToken = nav / indexFundToken.totalSupply();

        int256 netDeposits = int256(totalDepositedEth) -
            (int256(totalUnwithdrawnTokens) * int256(navPerToken));
        if (netDeposits > 0) {
            // buy underlying ERC tokens
        } else {    // more withdrawals than deposits
            // sell underlying tokens
        }

        // return ETH to withdrawers
        for (uint i = 0; i < usersWithdrawn.length; i++) {
            // this might be a wrong calculation
            usersWithdrawn[i].transfer(
                usersWithdrawnAmount[usersWithdrawn[i]] * navPerToken
            );
            indexFundToken.burnToken(address(this), totalUnwithdrawnTokens);

            delete usersWithdrawnAmount[usersWithdrawn[i]];
            delete usersWithdrawn[i];
        }
        totalUnwithdrawnTokens = 0;

        // mint new tokens and send to depositers
        for (uint i = 0; i < usersDeposited.length; i++) {
            indexFundToken.mintToken(usersDeposited[i], userDepositedAmount[usersDeposited[i]] / navPerToken);
            
            delete userDepositedAmount[usersDeposited[i]];
            delete usersDeposited[i];
        }
        totalDepositedEth = 0;

    }

    function calculateCurrentNAV() private returns (uint256) {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 _ercToken = IERC20(
                tokensInformation[tokens[i]].tokenAddress
            );
            uint256 _tokenBalance = _ercToken.balanceOf(address(this));
            return _tokenBalance * uint256(getLatestTokenPrice());
        }
    }

    // buyTokens will purchase tokens based on the % of the tokens specified
    function buyTokens() private {
        for (uint i = 0 ; i < tokens.length; i++) {
            uint percentageOfToken = tokensInformation[tokens[i]].marketCap / totalTokensMarketCap;
            uint amountEthToSwap = totalDepositedEth * percentageOfToken;
            this.swapToken(tokensInformation[tokens[i]].tokenAddress, amountEthToSwap);
        }
    }

    // swapToken will call uniswap to swap Eth to the token from the parameter
    // there will be some spread difference 
    function swapToken(TokenInformation tokenToSwap, uint amountEthToSwap) public {
        IERC20 token = IERC20(tokenAddress);
        address uniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        
        address WETHAddress = UniswapV2Router02.WETH();
        
        // for now assume there's always liquidity and a direct pair.
        // TODO: will need to make this programatic
        address payable [] path;
        path.push(WETHAddress);
        path.push(tokenToSwap.tokenAddress);

        // TODO: should do a 1% spread
        uint amountOutMin = amountEthToSwap / tokenToSwap.tokenPrice;
        UniswapV2Router02.swapExactETHForTokens(amountOutMin, path, address(this), now + 100000); // deadline is 100 seconds
    }

    // TODO: correct implementation
    function getLatestTokenPrice() private returns (int256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

    function getLatestEthPrice() public view returns (int256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
}
