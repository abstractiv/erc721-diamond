
/* global ethers task */
require('@nomiclabs/hardhat-waffle')
require('@nomiclabs/hardhat-etherscan')
require('@nomiclabs/hardhat-ganache')
require('hardhat-contract-sizer')

require('hardhat-diamond-abi')
require('solidity-coverage')
require('hardhat-gas-reporter')

require("@nomiclabs/hardhat-web3")
require("hardhat-gas-trackooor");

require('dotenv').config()

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', 'Prints the list of accounts', async () => {
  const accounts = await ethers.getSigners()

  for (const account of accounts) {
    console.log(account.address)
  }
})

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: '0.8.15',
  settings: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  },
  networks: {
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [process.env.PRIVATE_KEY],
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  gasReporter: {
    enabled: true,
    currency: 'USD',
    gasPrice: 20
  },
  diamondAbi: {
    name: 'ERC721Diamond',
    include: [
      'AccessControlFacet',
      'ERC721URIStorage',
      'DiamondLoupeFacet',
      'DiamondCutFacet',
      'OwnershipFacet'
    ]
  }
}
