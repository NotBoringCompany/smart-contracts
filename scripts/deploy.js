const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account: ", deployer.address);
  const balance = await deployer.getBalance();
  console.log("Account balance: ", balance.toString(), " wei");

  /**
   * @dev Genesis NBMon A (BEP721A) contract
   */
   const GenesisAContract = await ethers.getContractFactory("GenesisNBMon").catch((err) => console.log(err));
   console.log("genesis contract factory received");
   const genesisAContract = await GenesisAContract.deploy().catch((err) => console.log(err));
   console.log("genesis contract being deployed");
   await genesisAContract.deployed();
   console.log("Contract address: ", genesisAContract.address);

  // @dev marketplace contract
  // const MarketplaceContract = await ethers.getContractFactory("Marketplace").catch((err) => console.log(err));
  // console.log("genesis contract factory received");
  // const marketplaceContract = await MarketplaceContract.deploy().catch((err) => console.log(err));
  // console.log("genesis contract being deployed");
  // await marketplaceContract.deployed();
  // console.log("Contract address: ", marketplaceContract.address);

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });