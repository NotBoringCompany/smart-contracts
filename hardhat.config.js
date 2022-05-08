/**
* @type import('hardhat/config').HardhatUserConfig
*/

const { task } = require('hardhat/config');

require("@nomiclabs/hardhat-waffle");
require('dotenv').config();

const accountOne = process.env.WALLET_1;
const moralisAPINode = process.env.MORALIS_NODEAPI;

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
 module.exports = {
  defaultNetwork: "polygonTestnet",
  networks: {
    polygonTestnet: {
      url: "https://rpc-mumbai.maticvigil.com",
      chainId: 80001,
      accounts: [`0x${accountOne}`]
    },
    ganache: {
      url: "HTTP://127.0.0.1:7545",
      chainId: 1337,
      accounts: [`0x${accountOne}`]
    },
    bscTestnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      gasPrice: 20000000000,
      accounts: [`0x${accountOne}`]
    },
    bscMainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      gasPrice: 20000000000,
      accounts: [`0x${accountOne}`]
    },
    ethRinkeby: {
      url: `https://speedy-nodes-nyc.moralis.io/${moralisAPINode}/eth/rinkeby`,
      // url: 'https://eth-rinkeby.alchemyapi.io/v2/WaN_fLthgNG17X2qVlz3DLj3K8AqRi9L',
      chainId: 4,
      accounts: [`0x${accountOne}`]
    }
  },
  solidity: {
  version: "0.8.13",
  settings: {
    optimizer: {
      enabled: true,
      runs: 200
    }
   }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 0
  }
};

