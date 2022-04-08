const { Wallet } = require("ethers");
const { ethers } = require("hardhat");
require('dotenv').config();
// var fs = require('fs');

async function main() {
  const genesisAAddress = '0xf113759799E2616B662F63c1cbB3821E0cb9Dddb';
  const GenesisAContract = await ethers.getContractFactory("GenesisNBMonMintingA");
  const genesisAContract = await GenesisAContract.attach(genesisAAddress);

  // const signer = new ethers.Wallet(proces.env.WALLET_1, `https://speedy-nodes-nyc.moralis.io/${process.env.MORALIS_NODEAPI}/eth/rinkeby`);

  // let abi = 

  // name = NBC Experiment 1
  let owner = "0xe253773Fdd10B4Bd9d7567e37003F7029144EF90";
  let amountToMint = 35;
  let hatchingDuration = 300;
  let nbmonStats = [];
  let types = [];
  let potential = [];
  let passives = [];
  let isEgg = true;

  const devMint = await genesisAContract.devGenesisEggMint(amountToMint, hatchingDuration, nbmonStats, types, potential, passives, isEgg);
  console.log(devMint);

  // const ownerIds = await genesisAContract.getOwnerGenesisNBMonIds('0x460107fAB29D57a6926DddC603B7331F4D3bCA05');
  // console.log(ownerIds);

  // const currentCount = await genesisAContract.currentGenesisNBMonCount();
  // console.log(currentCount);

  // const ownerNBMons = await genesisAContract.getGenesisNBMon(15);
  // console.log(ownerNBMons);

  // const mintWhitelist = await genesisAContract.whitelistedGenesisEggMint(owner, amountToMint, hatchingDuration, nbmonStats, types, potential, passives, isEgg);
  // console.log(mintWhitelist);

  // const whitelistAddress = await genesisAContract.whitelistAddress('0x460107fAB29D57a6926DddC603B7331F4D3bCA05');
  // console.log(whitelistAddress);
  // const checkWhitelist = await genesisAContract.whitelisted('0xe253773Fdd10B4Bd9d7567e37003F7029144EF90');
  // console.log(checkWhitelist);

  // const amountMinted = await genesisAContract.amountMinted('0xe253773Fdd10B4Bd9d7567e37003F7029144EF90');
  // console.log(amountMinted);

  // const checkId = await genesisAContract.getGenesisNBMon(1);
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