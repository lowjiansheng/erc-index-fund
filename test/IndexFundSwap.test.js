const { assert } = require('chai');
const { accounts } = require('@openzeppelin/test-environment');
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');

const { before } = require('underscore');
const IndexFundSwap = artifacts.require('IndexFundSwap');
const MockToken = artifacts.require('MockToken');

require('chai')
    .use(require('chai-as-promised'))
    .should()

contract('IndexFundSwap', ([buyer, seller]) => {
    let mockToken, indexFundSwap;
    beforeEach(async() => {
        mockToken = await MockToken.new();
        indexFundSwap = await IndexFundSwap.new();
    }) 
        
    describe('IndexFundSwap', async() => {
        it('correctly swaps Eth for Token', async() => {
            const truffleReceipt = await indexFundSwap.swapEthForToken(mockToken.address, 1);
            expectEvent(truffleReceipt, 'Swapped', { amountEth: '1', user: this.addresses[0] })
        }) 
    })
    
})

