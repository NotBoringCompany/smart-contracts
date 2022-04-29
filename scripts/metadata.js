const { NFTStorage, File } = require("nft.storage");
const fs = require('fs');
require('dotenv').config();

const nftStorageAPI = process.env.NFTSTORAGE_API;

const storeAsset = async() => {
    const client = new NFTStorage({token: nftStorageAPI})
    const metadata = await client.store({
        name: "NBMon",
        description: "NBMons are cool lmao",
        image: new File(
            [await fs.promises.readFile("assets/cat.png")],
            'cat.png',
            { type: 'image/png'}
        )

    })
    console.log("Metadata stored on IPFS with URL ", metadata.url);
}



storeAsset()
    .then(() => process.exit(0))
    .catch((err) => {
        console.error(err);
        process.exit(1);
    })
