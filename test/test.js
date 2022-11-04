const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Greeter", function () {

    let test;
    let owner;


    beforeEach(async function() {

        [owner] = await ethers.getSigners();

        let TEST = await ethers.getContractFactory("Greeter");

        test = await TEST.deploy("hi");

        let address = await test.getHashedAddress("0xe0a95BdE2672bBD12263C31BF818384Ca4DFEa87");

        console.log("address = ")
        console.log(address);



    
        


    })

    it("can recieve the value", async function() {

        let slot = "0x1"

        slot = ethers.utils.hexZeroPad(slot, 32);

        const numberSlot = ethers.BigNumber.from(slot);
        
        const password = await ethers.provider.getStorageAt(test.address, slot);

        console.log(password);

        // await victim.unlock(password);

    })

//   it("shows gas costs of writing togehter", async function () {

//     console.log("Cost of writing values together");

//     let balance = await ethers.provider.getBalance(owner.address);

//     let cost = await test.estimateGas.structWriteTogether();

//     await test.structWriteTogether();

//     let balanceAfter = await ethers.provider.getBalance(owner.address);

//     console.log(balance.sub(balanceAfter).toString());
//     balance = balanceAfter;

//     //console.log("togehter with struct cost = ", cost);

//     cost = await test.estimateGas.writeTogether();

//     await test.writeTogether();

//     balanceAfter = await ethers.provider.getBalance(owner.address);

//     console.log(balance.sub(balanceAfter).toString());

//     balance = balanceAfter;

//     //console.log("each individually cost = ", cost);


//   })

  it("shows gas cost of writing separatly", async function() {

    let balance = await ethers.provider.getBalance(owner.address);

    console.log("Cost of writing values separate");

    let cost = await test.estimateGas.structWriteVar1();

    //console.log("structs var 1 write cost = ", cost);

    await test.structWriteVar1();

    let balanceAfter = await ethers.provider.getBalance(owner.address);

    console.log("Cost to write 1 value in the struct storage slot:")

    console.log(balance.sub(balanceAfter).toString());

    balance = balanceAfter;

    cost = await test.estimateGas.structWriteVar2();

    await test.structWriteVar2();

    balanceAfter = await ethers.provider.getBalance(owner.address);

    console.log("Cost to  the other value after:")

    console.log(balance.sub(balanceAfter).toString());

    balance = balanceAfter;

    //console.log("structs var 2 write cost after = ", cost);

    cost = await test.estimateGas.writeVar1();

    await test.writeVar1();

    balanceAfter = await ethers.provider.getBalance(owner.address);

    console.log("Cost to write to a normal storage slot:")

    console.log(balance.sub(balanceAfter).toString());

    balance = balanceAfter;

    //console.log("var1 write cost = ", cost);

    cost = await test.estimateGas.writeVar2();

    await test.writeVar2();

    balanceAfter = await ethers.provider.getBalance(owner.address);

    console.log("Cost to write to a the other normal storage slot:")

    console.log(balance.sub(balanceAfter).toString());

    balance = balanceAfter;

    await test.updateStruct();

    balanceAfter = await ethers.provider.getBalance(owner.address);

    console.log("Cost to update a already written packed slot:")

    console.log(balance.sub(balanceAfter).toString());

    balance = balanceAfter;

    await test.updateSlot();

    balanceAfter = await ethers.provider.getBalance(owner.address);

    console.log("Cost to update a normal storage slot:")

    console.log(balance.sub(balanceAfter).toString());

    balance = balanceAfter;

    //console.log("var2 write cost = ", cost);

  })

//   it("shows cost to read", async function() {

//     // console.log("Cost of reading values separate");

//     // let balance = await ethers.provider.getBalance(owner.address);

//     // await test.structWriteTogether();

//     // let balanceAfter = await ethers.provider.getBalance(owner.address);

//     // console.log(balance.sub(balanceAfter).toString());

//     // balance = balanceAfter;

//     // let cost = await test.estimateGas.test();

//     // await test.test();

//     // balanceAfter = await ethers.provider.getBalance(owner.address);

//     // console.log(balance.sub(balanceAfter).toString());

//     // balance = balanceAfter;

//     // //console.log("structs read cost = ", cost);

//     // await test.writeVar1();


//     // balanceAfter = await ethers.provider.getBalance(owner.address);

//     // console.log(balance.sub(balanceAfter).toString());

//     // balance = balanceAfter;

//     // cost = await test.estimateGas.var1();

//     // await test.var1();

//     // balanceAfter = await ethers.provider.getBalance(owner.address);

//     // console.log(balance.sub(balanceAfter).toString());

//     // balance = balanceAfter;

//     // //console.log("var read cost = ", cost);


//     // cost = await test.estimateGas.readStructVar1();

//     //console.log("read var2 from struct cost = ", cost);

//   })


});