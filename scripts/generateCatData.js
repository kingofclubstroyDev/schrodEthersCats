// npx hardhat run ./scripts/generateCatData.js
const {deploy} =  require("./helpers/deployment");

const { ethers } = require('hardhat');
const { BigNumber } = require("ethers");

let metadataManager;
let sec;
let deadCat;

const numMintsPerGroup = 20;

const numGroups = 4;

const maxTime = (60*60*24*7)

const timePerGroup = maxTime / (numGroups - 1);

const generateImages = true;

let fileName = "handedness_aug_23_Jordan";

async function main() {

    const deployment = await deploy(true);

    metadataManager = deployment.metadataManager;
    sec = deployment.sec;
    deadCat = deployment.deadCat;

    await mint();

    await sec.tokenURI(1);

    let metadata = await getMetadata();

    let data = JSON.stringify(metadata);

    let path = "CatGenerations/jsonFiles/" + fileName + ".json";


    const fs = require("fs");

    try {
        fs.writeFileSync(path, data);
        console.log("JSON data is saved.");
    } catch (error) {
        console.error(error);
    }

    if(generateImages) {

    }

   

    
}

async function getMetadata() {

    const numMinted = numGroups * numMintsPerGroup;

    let metadataObject = {};

    let totalAlive = 0;
    let totalDead = 0;
    let numBatches = 0;

    for(let i = 0; i < numMinted; i++) {

        let metadata;

        if(i % numMintsPerGroup == 0 && i != 0) {

            numBatches += 1;

            console.log("Batch number: ", numBatches)
            console.log("Total Alive: ", totalAlive)
            console.log("Total Dead: ", totalDead);

            totalAlive = 0;
            totalDead = 0;

        }

        try {

            metadata = await sec.tokenURI(i);
            totalAlive += 1;


        } catch(error) {

            metadata = await deadCat.tokenURI(i);

            totalDead += 1;

        }

        metadataObject[i] = JSON.parse(metadata);

        let pools = await sec.getPools(i);

        let completedPools = [];

        for(pool in pools) {
            completedPools.push(BigNumber.from(pools[pool]).toNumber() + 1)
        }

        metadataObject[i]["pools"] = completedPools;
        metadataObject[i]["timeinBox"] = (((numBatches * timePerGroup) / maxTime) * 100).toFixed(2);

    }

   
    return metadataObject;

}


async function mint() {

    for(let i = 0; i < numGroups; i++) {

        let numMints = numMintsPerGroup;

        while(numMints > 0) {

            let numToMint = 100;
            if(numMints < 100) {
                numToMint = numMints;
            }

            await sec.testMint(numToMint);

            numMints -= numToMint;

        }

        console.log("minted group #", i + 1);

    }

    let currentId = 0;

    for(let j = 0; j < numGroups - 1; j++) {

        for(let i = 0; i < numMintsPerGroup; i++) {

            let ran = Math.floor(Math.random() * 1000000000000000);

            await sec.testCollapse(currentId, ran);

            currentId += 1; 
            
        }

        await ethers.provider.send('evm_increaseTime', [timePerGroup]);
        await ethers.provider.send('evm_mine');

    }

    for(let i = 0; i < numMintsPerGroup; i++) {

        await sec.testCollapse(currentId, Math.floor(Math.random() * 1000000000000000));

        currentId += 1;

    }


}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });