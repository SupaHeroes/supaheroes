const chai = require("chai");
const BN = require("bn.js");
const { ethers } = require("hardhat");
const { expect } = require("chai");

// Enable and inject BN dependency
chai.use(require("chai-bn")(BN));

describe("Campaign Factory Unit Test", function () {

  let owner;
  let addr1;

  let cmaster;
  let rmaster;
  let vmaster;
  let ccToken;

  let factoryContract;

  before(async function () {
    [owner, addr1] = await ethers.getSigners();
   
    const CampaignStrategy = await ethers.getContractFactory("StandardCampaignStrategy");
    cmaster = await CampaignStrategy.deploy();
    const RewardManager = await ethers.getContractFactory("RewardManager");
    rmaster = await RewardManager.deploy();
    const VestingManager = await ethers.getContractFactory("VestingManager");
    vmaster = await VestingManager.deploy();

    const CampaignFactory = await ethers.getContractFactory("CampaignFactory");
    factoryContract = await CampaignFactory.deploy(cmaster.address, rmaster.address, vmaster.address);
    await factoryContract.deployed();
  });
  
  describe("Deployment", function(){
    it("Should have the correct owner", async function () {
      const addr = await factoryContract.owner();
      expect(addr).to.equal(owner.address);
    });
  });

  describe("Administration", function(){
    it("Should pass when admin changes contract", async function () {
      await expect(await factoryContract.changeMasters(cmaster.address, rmaster.address, vmaster.address)).to.emit(factoryContract, "ContractLog");
    });
    it("Reverts if masters changed by non-admin", async function () {
      await expect(factoryContract.connect(addr1).changeMasters(cmaster.address, rmaster.address, vmaster.address)).to.be.revertedWith("Ownable: caller is not the owner");
    });
    it("Reverts if cc set by non-admin", async function () {
      const CC = await ethers.getContractFactory("ContributionCertificate");
      ccToken = await CC.deploy(factoryContract.address);

      await expect(factoryContract.connect(addr1).changeCC(ccToken.address)).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("Cloning", function(){
    it("Should clone campaign without vesting", async function () {
      await expect(await factoryContract.createCampaign()).to.emit(factoryContract, "NewCampaign");
    });
    it("Should clone campaign with vesting", async function () {
      await expect(await factoryContract.createCampaignWithVesting()).to.emit(factoryContract, "NewCampaign");
    });
  });
  
});
