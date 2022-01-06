const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("Integration Test", function () {

  let owner;
  let addr1;
  let addr2;
  let erc20;

  let cmaster;
  let rmaster;
  let vmaster;
  let ccToken;

  let factoryContract;

  let cClone;
  let rClone;
  let vClone;

  before(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    console.log("Owner is:" + owner.address);

    const ERC20 = await ethers.getContractFactory("ERC20Mock");
    erc20 = await ERC20.deploy("Test token", "TT", owner.address, 1000000000);
    await erc20.transferInternal(owner.address, addr1.address, 6000);
    await erc20.transferInternal(owner.address, addr2.address, 8000);

   
  });

  describe("Deployments", function(){
    it("Should deploy master campaign contract", async function(){
      const CampaignStrategy = await ethers.getContractFactory("StandardCampaignStrategy");
      cmaster = await CampaignStrategy.deploy();
      await cmaster.deployed();
      expect(cmaster.address).to.exist;
    });

    it("Should deploy master reward manager contract", async function(){
      const RewardManager = await ethers.getContractFactory("RewardManager");
      rmaster = await RewardManager.deploy();
      await rmaster.deployed();
      expect(rmaster.address).to.exist;
    });

    it("Should deploy master vesting manager contract", async function(){
      const VestingManager = await ethers.getContractFactory("VestingManager");
      vmaster = await VestingManager.deploy();
      await vmaster.deployed();
      expect(vmaster.address).to.exist;
    });

    it("Should deploy factory contract", async function(){
      const CampaignFactory = await ethers.getContractFactory("CampaignFactory");
      factoryContract = await CampaignFactory.deploy(cmaster.address, rmaster.address, vmaster.address);
      await factoryContract.deployed();
      expect(factoryContract.address).to.exist;
    });

  })

  describe("Cloning", function() {
    it("Should clone campaign without vesting", async function(){
      const res = await factoryContract.createCampaignWithVesting();
      console.log(res);
      // cClone = new ethers.Contract(cRes, cmaster.abi);
      // console.log(cClone.address);
      // rClone = new ethers.Contract(rRes, rmaster.abi);
      // vClone = new ethers.Contract(vRes, vmaster.abi);

      // expect(await cClone.rewardManager.call()).to.equal(rClone.address);
    });
  });

  // describe("Initialization", function() {
  //   it("Should initialize campaign clone and check if admin is owner", async function(){
  //     await CampaignContract.initialize(
  //       erc20.address,
  //       "https://example.com",
  //       1646468207,
  //       1000,
  //       1644049007,
  //       fakeVestingManager,
  //       fakeRewardManager
  //     );
  //     let admin = await CampaignContract.admin.call();
  //     expect(admin).to.equal(owner.address);
  //   });

  //   it("Should initialize reward clone and check if admin is owner", async function(){
  //     await CampaignContract.initialize(
  //       erc20.address,
  //       "https://example.com",
  //       1646468207,
  //       1000,
  //       1644049007,
  //       fakeVestingManager,
  //       fakeRewardManager
  //     );
  //     let admin = await CampaignContract.admin.call();
  //     expect(admin).to.equal(owner.address);
  //   });

  //   it("Should initialize vesting clone and check if admin is owner", async function(){
  //     await CampaignContract.initialize(
  //       erc20.address,
  //       "https://example.com",
  //       1646468207,
  //       1000,
  //       1644049007,
  //       fakeVestingManager,
  //       fakeRewardManager
  //     );
  //     let admin = await CampaignContract.admin.call();
  //     expect(admin).to.equal(owner.address);
  //   });
  // });
  

  // describe("Contract Interaction", function(){
  //   it("Making sure metadata changes correctly", async function () {
  //     await CampaignContract.changeMetadata("test");
  //     expect(await CampaignContract.metadata.call()).to.equal("test");
  //   });
  
  //   it("Make sure supported currency is correct", async function () {
  //     expect(await CampaignContract.supportedCurrency.call()).to.equal(erc20.address);
  //   });
  
  //   it("Should revert when admin pledges", async function () {
  //     await expect(CampaignContract.pledge(500, 100, erc20.address, owner.address)).to.be.revertedWith("Admin cannot pledge");
  //   });

  //   it("Should pass when other user pledges", async function () {
  //     await erc20.connect(addr1).approve(CampaignContract.address, 3000);
  //     await CampaignContract.connect(addr1).pledge(3000, 200, erc20.address, addr1.address);
  //     expect(await erc20.balanceOf(CampaignContract.address)).to.equal(3000);
  //   });
  // });
  
});
