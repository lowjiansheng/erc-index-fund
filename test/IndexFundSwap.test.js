const { assert, expect } = require('chai');
const { accounts } = require('@openzeppelin/test-environment');
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

const { before } = require('underscore');
const { web3 } = require('@openzeppelin/test-helpers/src/setup');
const { add } = require('lodash');
const IndexFundSwap = artifacts.require('IndexFundSwap');
const IndexFundSwapPrep = artifacts.require('IndexFundSwapPrep');
const MockToken = artifacts.require('MockToken');

require('chai')
    .use(require('chai-as-promised'))
    .should()

function tokens(n) {
    return web3.utils.toWei(n, 'Ether');
}

contract('IndexFundSwapPrep', (addresses) => {
    let mockToken, indexFundSwapPrep;
    let WETHAdd, pairAddress;

    beforeEach(async() => {
        mockToken = await MockToken.new({from : addresses[0]});
        indexFundSwapPrep = await IndexFundSwapPrep.new({from : addresses[0]});
    })

    describe('MockToken', async() => {
        it('correctly deployed', async() => {
            const name = await mockToken.name.call();
            assert.equal(name.toString(), 'MockToken');

            const symbol = await mockToken.symbol.call();
            assert.equal(symbol.toString(), 'MOCKT');
        })

        it('amount given to test user correct', async() => {
            const amountUserHas = await mockToken.balanceOf(addresses[0]);
            assert.equal(amountUserHas.toString(), tokens('10000000000'));
        })
    })
    
    describe('IndexFundSwapPrep', async() => {
        it('correctly deployed', async() => {
            const contractName = await indexFundSwapPrep.contractName.call();
            assert.equal(contractName.toString(), 'IndexFundSwapPrep');
        })

        it ('correctly sets the WETH address', async() => {
            WETHAdd = await indexFundSwapPrep.WETHAdd.call();
            assert.equal(WETHAdd.toString(), '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2')
        })

        it ('setup WETH & MockToken liquidity pool', async() => {
            const amountTokenDesired = tokens('100')
            const amountETHToAddToLiquidity = tokens('0.1')
            const amountETHValue = tokens('0.15')
            await mockToken.approve(indexFundSwapPrep.address, amountTokenDesired, 
                {
                    from: addresses[0]
                });

            truffleReceipt = await indexFundSwapPrep.setupWETHTokenPair(
                mockToken.address,
                amountETHToAddToLiquidity,
                amountTokenDesired, 
                {
                    value: amountETHValue
                }
            );
            expectEvent(truffleReceipt, 'LiquidityAdded', {});
        })

        it ('correctly estimateAmountOut', async() => {
            const amountETHIn = tokens('0.05')
            truffleReceipt = await indexFundSwapPrep.estimateAmountOut(
                mockToken.address, 
                amountETHIn
            )
            expectEvent(truffleReceipt, "AmountOut", {})
        })
        
        it ("correctly make an ETH swap for tokens", async() => {
            const amountETHToSwap = tokens("0.05")
            const amountETHValue = tokens("0.25")
            truffleReceipt = await debug(indexFundSwapPrep.swapETHForToken(
                mockToken.address,
                "50000000000000000",
                {
                    value: "1500000000000000000",
                    from: addresses[0]
                }
            ))
        })
        
        
        /*
        it('correctly swaps ETH for Token', async() => {
            truffleReceipt = await indexFundSwapPrep.swapEthForToken(mockToken.address, tokens('0.1'))
            expectEvent(truffleReceipt, 'Swapped');
        })*/

    })

})


/*
contract('IndexFundSwap', (addresses) => {
    let mockToken, indexFundSwap;
    let WETHAdd;
    before(async() => {
        mockToken = await MockToken.new();
        indexFundSwap = await IndexFundSwap.new();
    }) 
        
    describe('IndexFundSwap', async() => {
        it('correctly deployed', async () => {
            const contractName = await indexFundSwap.contractName();
            assert.equal(contractName.toString(), "IndexFundSwap")
        })
        // make sure that we are connected to a fork of mainnet
        it('correctly sets the WETH address', async() => {
            const truffleReceipt = await indexFundSwap.getWETHAddress()
            expectEvent(truffleReceipt, 'FetchedWETHAddress', { user: addresses[0] })

            WETHAdd = await indexFundSwap.WETHAdd()
            assert.equal(WETHAdd.toString(), "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2")
        })

        it('correctly gets the swap pair informstion', async() => {
            const pairTotalSupply = await indexFundSwap.pairInformation(WETHAdd, mockToken.address)
            assert.equal(pairTotalSupply.toString(), "0")
        })
        
    })
    
})*/

