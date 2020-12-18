// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

// This index fund will take in Eth and buy the top 20 ERC20 tokens according to index distribution
// This is a test contract for the Kovan network
// The purchase will be triggered everyday
contract IndexFund {
    uint256 public totalUnspentEth;
    mapping(address => uint256) public userDepositedAmount;
    uint256 public totalEthDeposits;

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     */
    constructor() public {
        priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
    }

    function depositEth() public payable {
        uint256 amountOfEthDeposited = msg.value;
        address user = msg.sender;

        userDepositedAmount[user] = amountOfEthDeposited;
        totalEthDeposits = totalEthDeposits + amountOfEthDeposited;
    }

    // for now have to withdraw everything
    /*
    function withdrawEth() public payable {
        require(
            userDepositedAmount[msg.sender] > 0,
            "user have not deposited any ether"
        );

        address payable userToSend = payable(address(msg.sender));

        userToSend.transfer(userDepositedAmount[msg.sender]);
        userDepositedAmount[msg.sender] = 0;
    }*/

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
