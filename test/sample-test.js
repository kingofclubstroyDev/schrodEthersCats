const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("Greeter", function () {

  let sec;
  let owner, addr1, addr2, addr3;


  beforeEach(async function() {


    [owner, addr1, addr2, addr2, addr3] = await ethers.getSigners();

    let schrodEthersCat = await ethers.getContractFactory("SchrodEthersCat");

    let shares = [500, 500];

    let payees = [owner.address, addr1.address];

    //let yugen = await YUGEN.deploy(payees, shares);

    sec = await upgrades.deployProxy(schrodEthersCat, [payees, shares, owner.address], {kind: "uups"});

    //sec = await schrodEthersCat.deploy();

    //await sec.deployed();

})


  

  it("should return a chance of death", async function () {

    for(let i = 1; i < 8; i++) {

      console.log(i);

      let rawr_mod = await sec.collapseWavefunction2(i);

      console.log("rawr mawd = ");

      console.log(rawr_mod);

    }

  })


  it("should give proper isIpfs values", async function () {

    let isIpfs = [33, 5]

    await sec.setIsIpfs(isIpfs)

    let value = await sec.getIsIpfs(0)

    value = await sec.getIsIpfs(5)

    expect(value).to.be.true;

    value = await sec.getIsIpfs(258);

    expect(value).to.be.true;

    value = await sec.getIsIpfs(1);

    expect(value).to.be.false;

    value = await sec.getIsIpfs(256);

    expect(value).to.be.true;

  })

});
