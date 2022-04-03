const { ethers } = require("hardhat");
// var fs = require('fs');

async function main() {
    const genesisAAddress = '0x5B93b2156d47A3133173b8E87f9F9425575b76A7';
    const GenesisAContract = await ethers.getContractFactory("GenesisNBMonMintingA");
    const genesisAContract = await GenesisAContract.attach(genesisAAddress);

    // const totalSupply = await genesisAContract.totalSupply();
    // console.log(ethers.utils.formatEther(totalSupply) * 10 ** 18);

    // const mintLimit = await genesisAContract.mintLimit();
    // console.log(ethers.utils.formatEther(mintLimit) * 10 ** 18);

    let toAddress = "0x5fa5c1998d4c11f59c17FDE8b3f07588C23837D5";
    let hatchingDuration = 300;
    let nbmonStats = [];
    let types = [];
    let potential = [];
    let passives = [];
    let isEgg = true;

    const whitelistedMint = await genesisAContract.whitelistedGenesisEggMint(toAddress, hatchingDuration, nbmonStats, types, potential, passives, isEgg);
    console.log(whitelistedMint);
    





    

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });