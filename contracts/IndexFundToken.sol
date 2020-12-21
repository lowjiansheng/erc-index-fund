// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FundToken is ERC20 {
    address indexFundCore;

    modifier onlyIndexFundContract {
        require(
            msg.sender == indexFundCore,
            "Only index fund core can call this function"
        );
        _;
    }

    // IndexFundCore should be the contract that deploys this contract
    constructor() ERC20("ERCIndexFundToken", "EIFT") {
        indexFundCore = msg.sender;
    }

    function mintToken(address account, uint32 amount) public onlyIndexFundContract {
        _mint(account, amount);
    }

    function burnToken(address account, uint32 amount) public onlyIndexFundContract {
        _burn(account, amount);
    }

}
