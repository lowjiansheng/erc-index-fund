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
            assert.equal(contractName.toString(), "IndexFundSwapPrep");
        })

        it ('correctly sets the WETH address', async() => {
            WETHAdd = await indexFundSwapPrep.WETHAdd.call();
            assert.equal(WETHAdd.toString(), "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2")
        })

        /*
        it ('transfer mocktokens to smart contract', async() => {
            await mockToken.transfer(indexFundSwapPrep.address, tokens('0.1'), {from : addresses[0]});
            console.log(indexFundSwapPrep.address);
            const amountContractHas = await mockToken.balanceOf(indexFundSwapPrep.address);
            assert.equal(amountContractHas.toString(), tokens('0.1'));
        })*/

        it ('setup WETH & MockToken liquidity pool', async() => {
            const amountTokenDesired = tokens('0.1');
            await mockToken.approve(indexFundSwapPrep.address, amountTokenDesired, 
                {
                    from: addresses[0]
                });

            truffleReceipt = await indexFundSwapPrep.setupWETHTokenPair(mockToken.address, amountTokenDesired, {
                value: tokens('0.2')
            });

            pairAddress = await indexFundSwapPrep.pairAddress.call();
        })
        /*
        it ('creates WETH & MockToken Pair', async() => {
            truffleReceipt = await indexFundSwapPrep.createWETHPair(mockToken.address)
            expectEvent(truffleReceipt, 'ETHPairCreated', {})

            pairAddress = await indexFundSwapPrep.pairAddress.call()
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

