// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const airnodeAdmin = require('@api3/airnode-admin');
const apis = require('../values/qrngApis.json');

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const QrngExample = await hre.ethers.getContractFactory("QrngExample");
  const qrngExample = await QrngExample.deploy("0xa0AD79D995DdeeB18a14eAef56A549A04e3Aa1Bd");

  await qrngExample.deployed();

  console.log("QrngExample deployed to:", qrngExample.address);

  const apiData = apis['ANU Quantum Random Numbers'];
  const account = (await hre.ethers.getSigners())[0];

  // We are deriving the sponsor wallet address from the QrngExample contract address
  // using the @api3/airnode-admin SDK. You can also do this using the CLI
  // https://docs.api3.org/airnode/latest/reference/packages/admin-cli.html
  // Visit our docs to learn more about sponsors and sponsor wallets
  // https://docs.api3.org/airnode/latest/concepts/sponsor.html
  const sponsorWalletAddress = await airnodeAdmin.deriveSponsorWalletAddress(
    apiData.xpub,
    apiData.airnode,
    account.address
  );

  console.log(sponsorWalletAddress)

  // // Set the parameters that will be used to make Airnode requests
  const receipt = await qrngExample.setRequestParameters(
    apiData.airnode,
    apiData.endpointIdUint256,
    sponsorWalletAddress
  );

  console.log('Setting request parameters...');
  await new Promise((resolve) =>
    hre.ethers.provider.once(receipt.hash, () => {
      resolve();
    })
  );
  console.log('Request parameters set');


}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
