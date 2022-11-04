// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { getContractAddress } = require('@ethersproject/address')

const { setPools, setTraitNames } = require("../parseTraits");

async function deploy(isTest) {

  let schrodEthersCat;
  let MetadataManager;

  if(isTest) {
  
    schrodEthersCat = await hre.ethers.getContractFactory("SchrodEthersTest");
    MetadataManager = await hre.ethers.getContractFactory("MetadataManagerTest");


  } else {
    schrodEthersCat = await hre.ethers.getContractFactory("SchrodEtherCat");
    MetadataManager = await hre.ethers.getContractFactory("MetadataManager");
  }

  const [owner] = await ethers.getSigners()

  const metadataManager = await MetadataManager.deploy();

  console.log("metadata manager address: ", metadataManager.address);

  let transactionCount = await owner.getTransactionCount()

  let secLogicAddress = getContractAddress({
    from: owner.address,
    nonce: transactionCount
  })

  console.log("sec logic address = " , secLogicAddress);

  transactionCount += 1;

  let secContractAddress = getContractAddress({
    from: owner.address,
    nonce: transactionCount
  })

  console.log("expected sec contract address: ", secContractAddress);

  transactionCount += 1;

  let deadCatAddress = getContractAddress({
    from: owner.address,
    nonce: transactionCount
  })

  console.log("expeced dead cat contract address: ", deadCatAddress);


  const sec = await hre.upgrades.deployProxy(schrodEthersCat, [metadataManager.address, deadCatAddress], {kind: "uups"});

  await sec.deployed();

  console.log("sec address = ")
  console.log(sec.address);

  const DEADCAT = await hre.ethers.getContractFactory("DeadCat");

  const deadCat = await DEADCAT.deploy(sec.address, metadataManager.address, "");

  await deadCat.deployed();

  console.log("dead cat address = ")
  console.log(deadCat.address);

  await setPools(metadataManager, 1);

  await setTraitNames(metadataManager, 1);

  await metadataManager.addCollection(sec.address, 1);

  return { metadataManager, sec, deadCat, secLogicAddress }

}

module.exports = { deploy }


