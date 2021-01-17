// const IndexFund = artifacts.require("IndexFund");
// const IndexFundCore = artifacts.require("IndexFundCore");
 const MockToken = artifacts.require("MockToken");
// const FundToken = artifacts.require("FundToken");
const IndexFundSwap = artifacts.require("IndexFundSwap");
const IndexFundSwapPrep = artifacts.require("IndexFundSwapPrep");

module.exports = function (deployer, network, accounts) {
  // deployer.deploy(IndexFund);
  // deployer.deploy(IndexFundCore);
  deployer.deploy(MockToken);
  // deployer.deploy(FundToken);
  deployer.deploy(IndexFundSwap);
  deployer.deploy(IndexFundSwapPrep);
};
