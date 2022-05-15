const { Wallet } = require("ethers");
const { ethers } = require("hardhat");
require('dotenv').config();
// var fs = require('fs');

async function main() {

  const marketplace = '0x8E71d31d525A298c2C065fCcf1eAd3D595c06A20';
  const MarketplaceContract = await ethers.getContractFactory("GenesisMarketplace");
  const marketplaceContract = await MarketplaceContract.attach(marketplace);

  // const setTeamWallet = await marketplaceContract.setTeamWallet('0x8FbFE537A211d81F90774EE7002ff784E352024a');
  // console.log(setTeamWallet);

  // const nbExcheq = await marketplaceContract.nbExchequer();
  // console.log(nbExcheq);

  const setNBExcheq = await marketplaceContract.setNBExchequer('0xe253773Fdd10B4Bd9d7567e37003F7029144EF90');
  console.log(setNBExcheq);

  // const acceptToken = await marketplaceContract.setPaymentTokens(['0x01BE23585060835E02B77ef475b0Cc51aA1e0709']);
  // console.log(acceptToken);
  // const checkToken = await marketplaceContract.paymentTokens('0x01BE23585060835E02B77ef475b0Cc51aA1e0709');
  // console.log(checkToken);

  // const setSalesFee = await marketplaceContract.setSalesFee(400);
  // console.log(setSalesFee);

  // const setDevCut = await marketplaceContract.setDevCut(100);
  // console.log(setDevCut);

  // const checkSalesFee = await marketplaceContract.salesFee();
  // console.log(checkSalesFee);
  // const genesisAAddress = '0x7C1718568eE932c38541a0DdEF7C2234eac927b0';
  // const GenesisAContract = await ethers.getContractFactory("GenesisNBMonMintingA");
  // const genesisAContract = await GenesisAContract.attach(genesisAAddress);
  
  // const moralisAPINode = process.env.MORALIS_NODEAPI;
  // const nodeURL = `https://speedy-nodes-nyc.moralis.io/${moralisAPINode}/eth/rinkeby`;
  // const customHttpProvider = new ethers.providers.JsonRpcProvider(nodeURL);

  // const txCount = await customHttpProvider.getTransactionCount('0x460107fAB29D57a6926DddC603B7331F4D3bCA05');
  // console.log(txCount);

  // const checkKey = await genesisAContract.checkValidKey("0225ca3a-4a08-48f6-a799-33ff583b6f4d");
  // console.log(checkKey);

  // const changeURI = await genesisAContract.setBaseURI("https://lol.com/");
  // console.log(changeURI);

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
  // let amountToMint = 10;
  // let hatchingDuration = 30;
  // let nbmonStats = [];
  // let types = [];
  // let potential = [];
  // let passives = [];
  // let isEgg = true;

  // const devMint = await genesisAContract.devGenesisEggMint(amountToMint, hatchingDuration, nbmonStats, types, potential, passives, isEgg);
  // console.log(devMint);

  // const publicMint = await genesisAContract.publicGenesisEggMint(owner, amountToMint, hatchingDuration, nbmonStats, types, potential, passives, isEgg);
  // console.log(publicMint);

  // const hatchEgg = await genesisAContract.hatchFromEgg("0225ca3a-4a08-48f6-a799-33ff583b6f4d", 1);
  // console.log(hatchEgg);

  // const ownerIds = await genesisAContract.getOwnerGenesisNBMonIds('0x6ef0f724e780E5D3aD66f2A4FCbEF64A774eA796');
  // console.log(ownerIds);

  // const tokenURI = await genesisAContract.tokenURI(1);
  // console.log(tokenURI);

  // const currentCount = (await genesisAContract.currentGenesisNBMonCount()) - 1;
  // console.log(currentCount);

  // const ownerNBMons = await genesisAContract.getGenesisNBMon(1);
  // console.log(ownerNBMons);

  // const mintWhitelist = await genesisAContract.whitelistedGenesisEggMint(owner, amountToMint, hatchingDuration, nbmonStats, types, potential, passives, isEgg);
  // console.log(mintWhitelist);

  // const whitelistAddress = await genesisAContract.whitelistAddress('0xa1BD4289940ed38100d9B93Bf4cBdf6E7de0689D');
  // console.log(whitelistAddress);
  // const checkWhitelist = await genesisAContract.whitelisted('0x6ef0f724e780E5D3aD66f2A4FCbEF64A774eA796');
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