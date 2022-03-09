const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account: ", deployer.address);
    console.log("Account balance: ", (await deployer.getBalance()).to.String, " wei");

    const NBMonContract = await ethers.getContractFactory("NBMonBreeding");
    const nbmonContract = await NBMonContract.deploy();
    await nbmonContract.deployed();
    console.log("Contract address: ", nbmonContract.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });