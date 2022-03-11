const { ethers } = require("hardhat");
var fs = require('fs');

async function main() {
    const deployedContract = '0x53857051B7cB1713f9c44136b274C4F511FFd046';
    const NBCOpenSeaTestContract = await ethers.getContractFactory("NBCOpenSeaTest");
    const nbcopenseaTest = await NBCOpenSeaTestContract.attach(deployedContract);

    //get token URI for NFT #1
    // const tokenURI = await nbcopenseaTest.tokenURI(1);
    // console.log(tokenURI);

    //check for owner
    // const ownerOfToken3 = await nbcopenseaTest.ownerOf(3);
    // console.log(ownerOfToken3);

    
    // console.log(await nbcopenseaTest.totalSupply());
    await nbcopenseaTest.mintTo('0x5fa5c1998d4c11f59c17FDE8b3f07588C23837D5');
    // console.log(await nbcopenseaTest.totalSupply());
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