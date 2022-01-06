const chai = require("chai");
const BN = require("bn.js");
const { ethers } = require("hardhat");
const { expect } = require("chai");

// Enable and inject BN dependency
chai.use(require("chai-bn")(BN));

describe("Standard Campaign Strategy Unit Test", function () {

  let owner;
  let addr1;
  let addr2;
  let erc20;
  let CampaignContract;

  before(async function () {
    // CampaignFactory = await ethers.getContractFactory("StandardCampaignFactory")
    // CampaignFactorySC = await CampaignFactory.deploy()
    fakeRewardManager = "0x57319d41F71E81F3c65F2a47CA4e001EbAFd4F33";
    fakeVestingManager = "0x57319d41F71E81F3c65F2a47CA4e001EbAFd4F33";

    [owner, addr1, addr2] = await ethers.getSigners();
    console.log("Owner is:" + owner.address)

    console.log("Creating Mock Token");
    const ERC20 = await ethers.getContractFactory("ERC20Mock");
    erc20 = await ERC20.deploy("Test token", "TT", owner.address, 1000000000);
    await erc20.transferInternal(owner.address, addr1.address, 6000);
    await erc20.transferInternal(owner.address, addr2.address, 8000);

    const CampaignStrategy = await ethers.getContractFactory("StandardCampaignStrategy");
    CampaignContract = await CampaignStrategy.deploy();
    await CampaignContract.deployed();
    console.log("Campaign deployed on: " + CampaignContract.address);
    console.log("Begin testing....")
  });

  describe("Initialization", function() {
    it("Initialize clone and check if admin is owner", async function(){
      await CampaignContract.initialize(
        erc20.address,
        "https://example.com",
        1646468207,
        1000,
        1644049007,
        fakeVestingManager,
        fakeRewardManager
      );
      let admin = await CampaignContract.admin.call();
      expect(admin).to.equal(owner.address);
    });
  });
  

  describe("Contract Interaction", function(){
    it("Should change metadata correctly", async function () {
      await CampaignContract.changeMetadata("test");
      expect(await CampaignContract.metadata.call()).to.equal("test");
    });
  
    it("Should have the correct currency", async function () {
      expect(await CampaignContract.supportedCurrency.call()).to.equal(erc20.address);
    });
  
    it("Should revert when admin pledges", async function () {
      await expect(CampaignContract.pledge(500, 100, erc20.address, owner.address)).to.be.revertedWith("Admin cannot pledge");
    });

    it("Should pass when other user pledges", async function () {
      await erc20.connect(addr1).approve(CampaignContract.address, 3000);
      await CampaignContract.connect(addr1).pledge(3000, 200, erc20.address, addr1.address);
      expect(await erc20.balanceOf(CampaignContract.address)).to.equal(3000);
    });
  });
  
});
