const { task } = require("hardhat/config");
const { getAccount } = require("./helpers.js");
const { ethers } = require("hardhat");

async function main() {
  // const [deployer] = await ethers.getSigners();
  // console.log("Deploying contracts with the account: ", deployer.address);
  // console.log("Account balance: ", await deployer.getBalance().toString, " wei");

  /**
   * @dev NBMon contract
   */
  //     const NBMonContract = await ethers.getContractFactory("NBMonBreeding");
  //     const nbmonContract = await NBMonContract.deploy();
  //     await nbmonContract.deployed();
  //     console.log("Contract address: ", nbmonContract.address);

  /**
   * @dev Test OpenSea Contract
   */

  // const OpenSeaTestContract = await ethers.getContractFactory("NBCOpenSeaTest");
  // const openseaTestContract = await OpenSeaTestContract.deploy();
  // await openseaTestContract.deployed();
  // console.log("Contract address: ", openseaTestContract.address);

  task("check-balance", "Shows the balance of your account").setAction(async(taskArguments, hre) => {
    const account = getAccount();
    console.log(`Account balance for ${account.address}: ${await account.getBalance()}`);
  });

  task("deploy", "Deploys the OpenSea test contract").setAction(async(taskArguments, hre) => {
    const OpenSeaTestContract = await hre.ethers.getContractFactory("NBCOpenSeaTest", getAccount());
    const openseaTestContract = await OpenSeaTestContract.deploy();
    console.log(`Contract deployed to address: ${openseaTestContract.address}`);
  });
  

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });