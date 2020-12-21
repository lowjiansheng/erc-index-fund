// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// This index fund will take in Eth and buy the top 20 ERC20 tokens according to index distribution
// This is a test contract for the Kovan network
// The purchase will be triggered everyday
contract IndexFundCore {
    
    uint256 public totalUnspentEth;
    mapping(address => uint256) public userDepositedAmount;
    address[] usersDeposited;

    uint256 public totalUnwithdrawnTokens;
    mapping(address => uint256) public userWithdrawnAmount;
    address payable[] usersWithdrawn;

    // This NAV will be calculated daily at the end of the day. Expressed in ETH.
    uint256 public nav;

    struct TokenInformation {
        uint256 marketCap;
        address tokenAddress;
        uint256 tokenBalance;
    }
    string[] public tokens;
    mapping(string => TokenInformation) _tokenInformation;
    uint64 _totalTokensMarketCap;

    AggregatorV3Interface internal priceFeed;

    // input correct address of token
    address fundToken = 0x9326BFA02ADD2366b30bacB125260Af641031331;

    /**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     */
    constructor() {
        priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        totalUnspentEth = 0;
    }

    // User calls this to deposit their Eths. The Eths do not immediately purchase the underlying tokens. These will be purchased at the end of the day.
    function depositEth() public payable {
        uint256 amountOfEthDeposited = msg.value;
        address user = msg.sender;

        userDepositedAmount[user] = amountOfEthDeposited;
        totalUnspentEth = totalUnspentEth + amountOfEthDeposited;
    }

    // Users will call this function to redeem their tokens for Eth. Their tokens will be held by the contract until end of day.
    // The final amount of Eth that can be redeemed will be determined by the NAV at the end of the day.
    // amountToWithdraw is the number of units of Fund Tokens to be withdrawn
    function redeemFunds(uint32 amountToWithdraw) public payable {
        totalUnwithdrawnTokens = totalUnwithdrawnTokens + amountToWithdraw;
        userWithdrawnAmount[msg.sender] = amountToWithdraw;

        IERC20 tokenFund = IERC20(fundToken);
        // contract will withhold the token amount first until end of day
        tokenFund.transferFrom(msg.sender, address(this), amountToWithdraw);
    }

    /** 
    fundManagement should only be at the end of the day. 
    It does all the maintenance work for the fund. 
    Purchase units for new token holders.
    Redeem units for any new redemptions.
    Calculates new NAV.
     */
    function fundManagement() public payable {
        nav = calculateCurrentNAV();
        purchaseAndRedeem();
    }

    function purchaseAndRedeem() public payable {
        uint256 numTokens = 100000;
        uint256 navPerToken = nav / numTokens;

        int256 netDeposits = int256(totalUnspentEth) -
            (int256(totalUnwithdrawnTokens) * int256(navPerToken));
        if (netDeposits > 0) {
            // return ETH to withdrawers
            for (uint256 i = 0; i < usersWithdrawn.length; i++) {
                usersWithdrawn[i].transfer(
                    userWithdrawnAmount[usersWithdrawn[i]] * navPerToken
                );
                // TODO: burn token
            }

            // buy underlying ERC tokens

            // mint new tokens and send to depositers
            for (uint256 i = 0; i < usersDeposited.length; i++) {
                // TODO: mint new tokens based on NAV
            }
        } else {
            // sell underlying tokens
            // send Eth
        }
    }

    function calculateCurrentNAV() private returns (uint256) {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 _ercToken = IERC20(
                _tokenInformation[tokens[i]].tokenAddress
            );
            uint256 _tokenBalance = _ercToken.balanceOf(address(this));
            return _tokenBalance * uint256(getLatestTokenPrice());
        }
    }

    // swapToken will call uniswap to swap Eth to the token from the parameter
    function swapToken(address tokenAddress) public {}

    // This function will be run every night to rebalance all the tokens and do the necessary swaps
    /*
    function rebalanceTokens() public {
        uint256 _totalNAV = calculateCurrentNAV();

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 _tokenTargetPercentage = _tokenInformation[tokens[i]]
                .marketCap / _totalTokensMarketCap;

            IERC20 _ercToken = IERC20(
                _tokenInformation[tokens[i]].tokenAddress
            );
            uint256 _currentBalance = _ercToken.balanceOf(address(this));

            uint256 _currentTokenPercentage = _currentBalance / _totalNAV;
        }
    }
*/
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