// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract MockToken is ERC20 {
    using SafeMath for uint256;

    uint256 CAP = 10000000000;
    uint256 TOTALSUPPLY = CAP.mul(10**18);
    string NAME = "MockToken";
    string SYMBOL = "MOCKT";

    constructor() public ERC20(NAME, SYMBOL) {
        _mint(msg.sender, TOTALSUPPLY);
    }
}
