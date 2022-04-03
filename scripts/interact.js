const { ethers } = require("hardhat");
var fs = require('fs');

async function main() {
    const genesisAAddress = '0x31B0A7e9f7EDffbD5214A11693FFd286aDda8D89';
    const GenesisAContract = await ethers.getContractFactory("GenesisNBMonMintingA");
    const genesisAContract = await GenesisAContract.attach(genesisAAddress);

    //check for Token URI
    const tokenURI = await genesisAContract.tokenURI(1500);
    console.log(tokenURI);

    // let count = 7;
    // for (count; count <= 10; count++) {
        // await nbcopenseaTest.mintTo('0x460107fAB29D57a6926DddC603B7331F4D3bCA05');
        // let nftJson = {
        //     "image": `https://kkrudhwauj3f.usemoralis.com/${count}.png`,
        //     "description": "ok",
        //     "name": `${count}th NFT` 
        // }

        // let stringify = JSON.stringify(nftJson);
        // fs.writeFile(`./jsonFiles/${count}.json`, stringify, (err) => {
        //     console.log(err);
        // })
    //     console.log(count);
    // }

    

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });