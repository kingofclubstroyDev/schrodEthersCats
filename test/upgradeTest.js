const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("Greeter", function () {

  let sec;
  let owner, addr1, addr2, addr3;


  beforeEach(async function() {


    [owner, addr1, addr2, addr2, addr3] = await ethers.getSigners();

    let schrodEthersCat = await ethers.getContractFactory("UpgradeableCats");

    let shares = [500, 500];

    let payees = [owner.address, addr1.address];

    //let yugen = await YUGEN.deploy(payees, shares);

    sec = await upgrades.deployProxy(schrodEthersCat, [], {kind: "uups"});

    //sec = await schrodEthersCat.deploy();

    await sec.deployed();

})


  

  it("should return a chance of death", async function () {

    // for(let i = 1; i < 8; i++) {

    //   console.log(i);

    //   let rawr_mod = await sec.collapseWavefunction2(i);

    //   console.log("rawr mawd = ");

    //   console.log(rawr_mod);

    // }

  })

});
