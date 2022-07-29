const { ethers } = require("hardhat");

/**
 * @dev This code is used to test gas prices for minting one or several batches of NFTs at once.
 */
const gasReporter = async () => {
    // deployed Genesis NBMon contract on Rinkeby testnet
    // const genesisAddress = '0xDd7d0595AADa35Ef7E11Ee448f871752978e2f17';
    const genesisAAddress = '0x31B0A7e9f7EDffbD5214A11693FFd286aDda8D89';
    const genesisAFactory = await ethers.getContractFactory("GenesisNBMonMintingA");
    const genesisAContract = await genesisAFactory.attach(genesisAAddress);

    /**
     * @dev Minting the genesis NBMon (WITH DATA)
     */
    // let owner = '0x460107fAB29D57a6926DddC603B7331F4D3bCA05';
    // let hatchingDuration = 100;
    // let nbmonStats = ["male", "common", "not mutated", "origin", "todillo", "3000"];
    // let types = ["earth", "reptile"];
    // let potential = [5, 10, 5, 10, 5, 10, 10];
    // let passives = ["passive 1", "passive 2"];
    // let isEgg = true;

    // await genesisContract.mintGenesisNBMon(owner, hatchingDuration, nbmonStats, types, potential, passives, isEgg)
    // .then(console.log("NBMon minted"));

    // mint 100 with for loop
    // let count = 1;
    // for (count; count <= 100; count++) {
    //     await genesisContract.mintGenesisNBMon(owner, hatchingDuration, nbmonStats, types, potential, passives, isEgg)
    //     .then(console.log("NBMon minted"));
    //     console.log(count);
    // }
    await genesisAContract.mintGenesisNBMon(owner, 4500, hatchingDuration, nbmonStats, types, potential, passives, isEgg).then(console.log("NBMon minted"));
}

gasReporter()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });