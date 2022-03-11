async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account: ", deployer.address);
  console.log("Account balance: ", await deployer.getBalance().toString, " wei");

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
  

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });