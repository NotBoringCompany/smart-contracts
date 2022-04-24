const { Wallet } = require("ethers");
const { ethers } = require("hardhat");
require('dotenv').config();
// var fs = require('fs');

async function main() {
  const genesisAAddress = '0xf113759799E2616B662F63c1cbB3821E0cb9Dddb';
  const GenesisAContract = await ethers.getContractFactory("GenesisNBMonMintingA");
  const genesisAContract = await GenesisAContract.attach(genesisAAddress);
  
  const moralisAPINode = process.env.MORALIS_NODEAPI;
  const nodeURL = `https://speedy-nodes-nyc.moralis.io/${moralisAPINode}/eth/rinkeby`;
  const customHttpProvider = new ethers.providers.JsonRpcProvider(nodeURL);

  // const txHash = "0x415d35912236e643e69118e3ce396945b7409ae807f925eecb2c69fdccb599a0";

  // let txReceipt = await customHttpProvider.getTransaction(txHash);

  // if (txReceipt && txReceipt.blockNumber) {
  //   if (ethers.utils.formatEther(txReceipt.value) == 0.01) {
  //     console.log(txReceipt);
  //   } else {
  //     console.log("not valid");
  //   }
  // }


  // const signer = new ethers.Wallet(proces.env.WALLET_1, `https://speedy-nodes-nyc.moralis.io/${process.env.MORALIS_NODEAPI}/eth/rinkeby`);

  // let abi = 

  // name = NBC Experiment 1
  // let owner = "0xe253773Fdd10B4Bd9d7567e37003F7029144EF90";
  // let amountToMint = 1;
  // let hatchingDuration = 300;
  let nbmonStats = ["Male", "Common", "Fire", "Origin", "Lamox", "3000"];
  let types = ["Electric", "Spirit"];
  let potential = [26, 10, 2, 14, 2, 19];
  let passives = ["Electric Sword", "Test Lol"];
  // let isEgg = true;

  const hatchEgg = await genesisAContract.hatchFromEgg(102, nbmonStats, types, potential, passives);
  console.log(hatchEgg);

  // const devMint = await genesisAContract.devGenesisEggMint(amountToMint, hatchingDuration, nbmonStats, types, potential, passives, isEgg);
  // console.log(devMint);

  // const ownerIds = await genesisAContract.getOwnerGenesisNBMonIds('0x460107fAB29D57a6926DddC603B7331F4D3bCA05');
  // console.log(ownerIds);

  // const currentCount = await genesisAContract.currentGenesisNBMonCount();
  // console.log(currentCount);

  // const ownerNBMons = await genesisAContract.getGenesisNBMon(15);
  // console.log(ownerNBMons);

  // const mintWhitelist = await genesisAContract.whitelistedGenesisEggMint(owner, amountToMint, hatchingDuration, nbmonStats, types, potential, passives, isEgg);
  // console.log(mintWhitelist);

  // const whitelistAddress = await genesisAContract.whitelistAddress('0x6ef0f724e780E5D3aD66f2A4FCbEF64A774eA796');
  // console.log(whitelistAddress);
  // const checkWhitelist = await genesisAContract.whitelisted('0x6ef0f724e780E5D3aD66f2A4FCbEF64A774eA796');
  // console.log(checkWhitelist);

  // const amountMinted = await genesisAContract.amountMinted('0xe253773Fdd10B4Bd9d7567e37003F7029144EF90');
  // console.log(amountMinted);

  // const checkId = await genesisAContract.getGenesisNBMon(101);
  // console.log(checkId);

  


  // const balanceOf = await genesisAContract.balanceOf('0x6ef0f724e780E5D3aD66f2A4FCbEF64A774eA796');
  // console.log(balanceOf);


}


main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });