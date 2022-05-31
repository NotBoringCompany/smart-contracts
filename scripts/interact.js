const { Wallet } = require("ethers");
const { ethers } = require("hardhat");
require('dotenv').config();
// var fs = require('fs');

async function main() {

  // const marketplace = '0x8E71d31d525A298c2C065fCcf1eAd3D595c06A20';
  // const MarketplaceContract = await ethers.getContractFactory("GenesisMarketplace");
  // const marketplaceContract = await MarketplaceContract.attach(marketplace);

  // const setTeamWallet = await marketplaceContract.setTeamWallet('0x8FbFE537A211d81F90774EE7002ff784E352024a');
  // console.log(setTeamWallet);

  // const linkContractAddr = '0x01BE23585060835E02B77ef475b0Cc51aA1e0709';
  // const BEP20Contract = await ethers.getContractFactory("BEP20");
  // const bep20Contract = BEP20Contract.attach(linkContractAddr);

  // const checkAllowance = await bep20Contract.allowance("0x8FbFE537A211d81F90774EE7002ff784E352024a","0x8E71d31d525A298c2C065fCcf1eAd3D595c06A20");
  // console.log(checkAllowance);

  // const nbExcheq = await marketplaceContract.nbExchequer();
  // console.log(nbExcheq);

  // const setNBExcheq = await marketplaceContract.setNBExchequer('0xe253773Fdd10B4Bd9d7567e37003F7029144EF90');
  // console.log(setNBExcheq);

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
  const genesisAAddress = '0xb0D9C83F3116f7c8f88Ae42f435b92CE8174162a';
  const GenesisAContract = await ethers.getContractFactory("GenesisNBMon");
  const genesisAContract = GenesisAContract.attach(genesisAAddress);

  
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

  // const ownerIds = await genesisAContract.getOwnerGenesisNBMonIds('0x8FbFE537A211d81F90774EE7002ff784E352024a');
  // console.log(ownerIds);

  // const getOwner = await genesisAContract.ownerOf(2);
  // console.log(getOwner);

  // const checkSig = await marketplaceContract.usedSignatures("0x18ccde3a021904623e4e3c6f4e1e83edcf0c7af891f6dfdea6ee4164bf5e837544d3596c6595bca639a93daa13753d0194af585567345af151b20dc7c23c5d2a1b");
  // console.log(checkSig);

  // const tokenURI = await genesisAContract.tokenURI(1);
  // console.log(tokenURI);

  // const currentCount = (await genesisAContract.currentGenesisNBMonCount()) - 1;
  // console.log(currentCount);

  const ownerNBMons = await genesisAContract.getNFT(1);
  console.log(ownerNBMons);

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