// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { getContractAddress } = require('@ethersproject/address')

import { setPools, setTraitNames } from "./parseTraits"

import {deploy} from "./helpers/deployment";

let metadataManager;
let sec;
let deadCat;

async function main() {

    const deployment = await deploy(true);

    metadataManager = deployment.metadataManager;
    sec = deployment.sec;
    deadCat = deployment.deadCat;

}

async function setTraits() {

    let propertyName = ["Clothing"]

    let traitNames = ["Scuba", "Space Suit", "Owl"];

    let traits = [[1,2,3], [2,3]];

    let rarities = [[20, 150, 200], [100, 200]]

    let thresholds = [100, 200];

    await metadataManager.initialize_attributes(0, traits, rarities, thresholds);
    await metadataManager.initializeTraitNames(traitNames, propertyName[0], 0);

    propertyName = ["HeadGear"]

    traitNames = ["Default", "Brain Jar", "Top Hat", "Hazmat", "Battle Cat", "Space Suit", "Nasa Cap"];

    traits = [[1,2,3,4], [5,6,7]];

    rarities = [[50, 100, 150, 200], [40, 20, 140]];

    thresholds = [150, 200];

    await metadataManager.initialize_attributes(1, traits, rarities, thresholds);
    await metadataManager.initializeTraitNames(traitNames, propertyName[0], 1);

    propertyName = ["Head"]

    traitNames = ["Default", "Brain Jar", "Top Hat", "Hazmat", "Battle Cat", "Space Suit", "Nasa Cap"];

    traits = [[1,2,3,4], [5,6,7]];

    rarities = [[50, 100, 150, 200], [40, 20, 140]];

    thresholds = [150, 200];

    await metadataManager.initialize_attributes(2, traits, rarities, thresholds);
    await metadataManager.initializeTraitNames(traitNames, propertyName[0], 2);


  }

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
