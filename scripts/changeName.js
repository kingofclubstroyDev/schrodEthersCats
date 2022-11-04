// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  

    const META = await hre.ethers.getContractFactory("MetadataManager");
    const meta = await META.attach(
    "0xa3D13bA1B71B90e2EB19b2056b242218a3b3d6FB"
    );

    const SEC = await hre.ethers.getContractFactory("SchrodEthersTest");
    const sec = await SEC.attach(
    "0x031e714660E74DF6d6Ed0c23bfEc0cA161Be3f3f"
    );

    //setTraits();

    // await sec.testCollapse(0, Math.floor(Math.random() * 1000000000000000))

    // await meta.setCanChangeText(true);

    //await meta.changeName("Cat In a Box", 2, {value : hre.ethers.utils.parseEther("0.02")});

    // console.log("name set")

    // await meta.changeDescription("Cat likes to blink", 0, {value : hre.ethers.utils.parseEther("0.02")})

    // console.log("description set")

    let uri = await sec.tokenURI(0);

    console.log(uri)

    uri = await sec.tokenURI(1);

    console.log(uri)
}

async function setTraits() {

    let propertyName = ["Clothing"]

    let traitNames = ["Scuba", "Space Suit", "Owl"];

    let traits = [[1,2,3], [2,3]];

    let rarities = [[20, 150, 200], [100, 200]]

    let thresholds = [100, 200];

    await meta.initialize_attributes(0, traits, rarities, thresholds);
    await meta.initializeTraitNames(traitNames, propertyName[0], 0);

    propertyName = ["HeadGear"]

    traitNames = ["Default", "Brain Jar", "Top Hat", "Hazmat", "Battle Cat", "Space Suit", "Nasa Cap"];

    traits = [[1,2,3,4], [5,6,7]];

    rarities = [[50, 100, 150, 200], [40, 20, 140]];

    thresholds = [150, 200];

    await meta.initialize_attributes(1, traits, rarities, thresholds);
    await meta.initializeTraitNames(traitNames, propertyName[0], 1);

    propertyName = ["Head"]

    traitNames = ["Default", "Brain Jar", "Top Hat", "Hazmat", "Battle Cat", "Space Suit", "Nasa Cap"];

    traits = [[1,2,3,4], [5,6,7]];

    rarities = [[50, 100, 150, 200], [40, 20, 140]];

    thresholds = [150, 200];

    await meta.initialize_attributes(2, traits, rarities, thresholds);
    await meta.initializeTraitNames(traitNames, propertyName[0], 2);


  }

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
