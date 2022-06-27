const { Wallet } = require("ethers");
const { ethers } = require("hardhat");
require('dotenv').config();
// var fs = require('fs');

async function main() {

  const marketplace = '0xDcfCF2d3517D658c10EEab5de488F01D5DBb85f1';
  const MarketplaceContract = await ethers.getContractFactory("Marketplace");
  const marketplaceContract = await MarketplaceContract.attach(marketplace);

  // const setTeamWallet = await marketplaceContract.setNBExchequer('0xe253773Fdd10B4Bd9d7567e37003F7029144EF90');
  // console.log(setTeamWallet);

  // const openmarketplace = await marketplaceContract.openMarketplace();
  // console.log(openmarketplace);


  // const linkContractAddr = '0x01BE23585060835E02B77ef475b0Cc51aA1e0709';
  // const BEP20Contract = await ethers.getContractFactory("BEP20");
  // const bep20Contract = BEP20Contract.attach(linkContractAddr);

  // const checkAllowance = await bep20Contract.allowance("0x8FbFE537A211d81F90774EE7002ff784E352024a","0x8E71d31d525A298c2C065fCcf1eAd3D595c06A20");
  // console.log(checkAllowance);

  // const nbExcheq = await marketplaceContract.nbExchequer();
  // console.log(nbExcheq);

  // const setNBExcheq = await marketplaceContract.setNBExchequer('0xe253773Fdd10B4Bd9d7567e37003F7029144EF90');
  // console.log(setNBExcheq);

  // const acceptToken = await marketplaceContract.setPaymentTokens([linkContractAddr]);
  // console.log(acceptToken);
  // const checkToken = await marketplaceContract.paymentTokens('0x01BE23585060835E02B77ef475b0Cc51aA1e0709');
  // console.log(checkToken);

  // const setSalesFee = await marketplaceContract.setSalesFee(400);
  // console.log(setSalesFee);

  // const setDevCut = await marketplaceContract.setDevCut(100);
  // console.log(setDevCut);

  // const checkSalesFee = await marketplaceContract.salesFee();
  // console.log(checkSalesFee);
  const genesisAAddress = '0x3534B3fc72b04C678f0008A75A5E19c8dCbB7bBc';
  const GenesisAContract = await ethers.getContractFactory("GenesisNBMon");
  const genesisAContract = GenesisAContract.attach(genesisAAddress);

  const getIds = await genesisAContract.getNFT(5);
  console.log(getIds);
  // const allowHatching = await genesisAContract.allowHatching();
  // console.log(allowHatching);

  // const registerAddress = await genesisAContract.addMinters(['0x6FdCB216A701f6Beb805E6f4F3714cb1581cEb80']);
  // console.log(registerAddress);


  // // const totalSupply = await genesisAContract.totalSupply();
  // // console.log(totalSupply);
  // const updateMaxSupply = await genesisAContract.updateMaxSupply();
  // console.log(updateMaxSupply);

  
  // const moralisAPINode = process.env.MORALIS_NODEAPI;
  // const nodeURL = `https://speedy-nodes-nyc.moralis.io/${moralisAPINode}/eth/rinkeby`;
  // const customHttpProvider = new ethers.providers.JsonRpcProvider(nodeURL);

  // const txCount = await customHttpProvider.getTransactionCount('0x460107fAB29D57a6926DddC603B7331F4D3bCA05');
  // console.log(txCount);

  // const checkKey = await genesisAContract.checkValidKey("0225ca3a-4a08-48f6-a799-33ff583b6f4d");
  // console.log(checkKey);

  // const changeURI = await genesisAContract.setBaseURI("https://lol.com/");
  // console.log(changeURI);

  // let amountToMint = 1;
  // let stringMetadata = ["Male", "Common", "Not mutated", "Origin", "Lamox"];
  // let numericMetadata = [300, 20, 24, 16, 3, 14, 20, 14, 3000];
  // let boolMetadata = [true];

  // const devMint = await genesisAContract.devMint(amountToMint, stringMetadata, numericMetadata, boolMetadata);
  // console.log(devMint);

  // const publicMint = await genesisAContract.publicGenesisEggMint(owner, amountToMint, hatchingDuration, nbmonStats, types, potential, passives, isEgg);
  // console.log(publicMint);

  // const hatchEgg = await genesisAContract.hatchFromEgg("0225ca3a-4a08-48f6-a799-33ff583b6f4d", 1);
  // console.log(hatchEgg);

  // const ownerIds = await genesisAContract.getOwnerNFTIds('0xe253773fdd10b4bd9d7567e37003f7029144ef90');
  // console.log(ownerIds);

  // const getOwner = await genesisAContract.ownerOf(2);
  // console.log(getOwner);

  // const checkSig = await marketplaceContract.usedSignatures("0x18ccde3a021904623e4e3c6f4e1e83edcf0c7af891f6dfdea6ee4164bf5e837544d3596c6595bca639a93daa13753d0194af585567345af151b20dc7c23c5d2a1b");
  // console.log(checkSig);

  // const tokenURI = await genesisAContract.tokenURI(1);
  // console.log(tokenURI);

  // const currentCount = (await genesisAContract.currentGenesisNBMonCount()) - 1;
  // console.log(currentCount);

  // const ownerNBMons = await genesisAContract.getNFT(1);
  // console.log(ownerNBMons);

  // const mintWhitelist = await genesisAContract.whitelistedGenesisEggMint(owner, amountToMint, hatchingDuration, nbmonStats, types, potential, passives, isEgg);
  // console.log(mintWhitelist);
  // const addressesToWL = ['0x6ef0f724e780E5D3aD66f2A4FCbEF64A774eA796'];

  // const whitelistAddress = await genesisAContract.whitelistAddresses(addressesToWL);
  // console.log(whitelistAddress);
  // const checkWhitelist = await genesisAContract.checkWhitelisted('0x6ef0f724e780E5D3aD66f2A4FCbEF64A774eA796');
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