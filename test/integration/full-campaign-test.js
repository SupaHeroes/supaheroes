const { ethers } = require("hardhat");
const { expect } = require("chai");
const campaignABI = require("../../data/abi/StandardCampaignStrategy.json");
const rewardABI = require("../../data/abi/RewardManager.json");
const vestingABI = require("../../data/abi/VestingManager.json");

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
    

    const ERC20 = await ethers.getContractFactory("ERC20Mock");
    erc20 = await ERC20.deploy("Test token", "TT", owner.address, 1000000000);
   
    await erc20.transfer( addr1.address, 6000);
    await erc20.transfer( addr2.address, 8000);
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

    it("Should deploy contribution token contract", async function(){
      const CC = await ethers.getContractFactory("ContributionCertificate");
      ccToken = await CC.deploy(factoryContract.address);
      await ccToken.deployed();
      expect(ccToken.address).to.exist;
    });

  })

  describe("Cloning", function() {
    it("Should clone campaign with vesting", async function(){

    const tx = await factoryContract.createCampaignWithVesting();

    const rc = await tx.wait();

    const event = rc.events.find(event => event.event === 'NewCampaign');

    // console.log(event.args);
    // console.log(event.args[0].toString());
    cClone = new ethers.Contract(event.args[0], campaignABI, owner);
    rClone = new ethers.Contract(event.args[2], rewardABI, owner);
    vClone = new ethers.Contract(event.args[3], vestingABI, owner);

    expect(cClone.address).to.exist;
    expect(rClone.address).to.exist;
    expect(vClone.address).to.exist;
    });
  });

  describe("Initialization", function() {
    it("Should initialize campaign clone", async function(){
      await cClone.initialize(
        erc20.address,
        "https://example.com",
        1646468207,
        1000,
        1644049007,
        vClone.address,
        rClone.address
      );
      
      expect(await cClone.rewardManager.call()).to.exist;
      expect(await cClone.metadata.call()).to.exist;
    });

    it("Should initialize reward manager clone", async function(){
      await rClone.initialize(
        cClone.address,
        "https://example.com",
        [1000, 500, 50],
        [5, 500, 1000],
        ccToken.address
      );
    });

    it("Should initialize vesting manager clone", async function(){
      await vClone.initialize(
        [1641487894, 1644141094],
        [200, 200],
        cClone.address
      );
      
      expect(await vClone.campaign.call()).to.exist;
    });

    it("Should have the correct reward manager", async function(){
      const res = await cClone.rewardManager.call();
      expect(res).to.equal(rClone.address);
    });


    it("Should have the correct vesting manager", async function(){
      const res = await cClone.vestingManager.call();
      expect(res).to.equal(vClone.address);
    });

    it("Should have the owner as admin", async function(){
      const admin = await cClone.admin.call();
      expect(admin).to.equal(owner.address);
    });    
  });
  

  describe("Reward Manager Interaction", function(){
    it("Should revert when wrong receipt id specified", async function () {
      await expect(rClone.connect(addr1).pledgeForReward(300, 1, erc20.address)).to.be.reverted;
    });

    it("Should revert if amount paid for the specified tier is not enough", async function () {
      await expect(rClone.connect(addr1).pledgeForReward(300, 1, erc20.address)).to.be.revertedWith("Not enough amount");
    });

    it("Should receive receipt NFT on pledge", async function () {
      await erc20.connect(addr1).approve(cClone.address, 550);
      console.log(await erc20.allowance(addr1.address, cClone.address));
      await rClone.connect(addr1).pledgeForReward(520, 1, erc20.address);

      expect(await erc20.balanceOf(cClone.address)).to.equal(520);
      expect(await rClone.userPledgedAmount(addr1.address)).to.equal(520);
      expect(await rClone.balanceOf(addr1.address, 1)).to.equal(1);
    });

    it("Should be able to vote", async function () {
      await rClone.connect(addr1).vote(1);
      expect(await rClone.votedAmount(addr1.address)).to.equal(1);
      expect(await rClone.balanceOf(addr1.address, 1)).to.equal(0);
    });
  });
  
});
