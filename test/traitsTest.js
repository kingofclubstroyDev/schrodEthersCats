const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

import {deploy} from "../scripts/helpers/deployment";



describe("Traits", function () {

  let sec;
  let metadataManager;
  let deadCat;
  let owner, addr1, addr2, addr3;
  let numProperties = 1;


  beforeEach(async function() {

    [owner, addr1, addr2, addr2, addr3] = await ethers.getSigners();

    const deployment = await deploy();

    sec = deployment.sec;
    metadataManager = deployment.metadataManager;
    
    deadCat = deployment.deadCat;


  });

  it("should return a chance of death", async function () {

    for(let i = 1; i < 8; i++) {

      console.log(i);

      let returnValues = await sec.collapseWavefunctionTest(i);

      console.log("rawr mawd = ");

      console.log(returnValues[0]);

      console.log("chance of death = ")
      console.log(returnValues[1])

    }

  })

  it("Alows minting", async function() {

    await sec.testMint(5);


  })

  it("Alows revealing", async function() {

    await sec.testMint(5);

    const estimation = await sec.estimateGas.testCollapse(0, Math.floor(Math.random() * 1000000000000000));

    console.log("gas to collapse = ");
    console.log(estimation);

    await sec.testCollapse(0, Math.floor(Math.random() * 1000000000000000))

    await setTraits()

    await metadataManager.setCanChangeText(true);

    await metadataManager.changeName("Leopold Stotch", 0, {value : hre.ethers.utils.parseEther("0.02")});

    console.log("name set")

    await metadataManager.changeDescription("Happy happy cat in a box", 0, {value : hre.ethers.utils.parseEther("0.02")})

    console.log("description set")

    let tokenUri = await sec.tokenURI(0);

    console.log(tokenUri);


  })

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

});
