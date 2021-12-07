const chai = require("chai");
const BN = require("bn.js");
const { ethers } = require("hardhat");
const { expect } = require("chai");

// Enable and inject BN dependency
chai.use(require("chai-bn")(BN));

describe("Deployment Test", function () {

    let owner;
  let addr1;
  let addr2;
  let erc20;
  let ERC20;
  let CampaignStrategy;
  let CampaignContract;
  before(async function () {
    // CampaignFactory = await ethers.getContractFactory("StandardCampaignFactory")
    // CampaignFactorySC = await CampaignFactory.deploy()
    const [owner, addr1, addr2] = await ethers.getSigners();

    ERC20 = await ethers.getContractFactory("ERC20Mock");
    erc20 = await ERC20.deploy("Test token", "TT", owner.address, 1000000000);
    await erc20.transferInternal(owner.address, addr1.address, 6000);
    await erc20.transferInternal(owner.address, addr2.address, 8000);

    CampaignStrategy = await ethers.getContractFactory("StandardCampaignMock");
    CampaignContract = await CampaignStrategy.deploy(
      owner.address,
      erc20.address,
      "https://google.com",
      owner.address,
      1000,
      1639296232,
      1640505832,
      [
        { claimDate: 1640851432, amount: 500, currency: erc20.address },
        { claimDate: 1640937832, amount: 500, currency: erc20.address },
      ]
    );
    await CampaignContract.deployed();
  });

  it("Making sure metadata changes correctly", async function () {
    await CampaignContract.changeMetadata("test");
    expect(await CampaignContract.metadata.call()).to.equal("test");
  });

  it("Make sure supported currency is correct", async function () {
    expect(await CampaignContract.supportedCurrency.call()).to.equal(erc20.address);
  });

  it("Should revert when admin pledges", async function () {
    expect(await CampaignContract.pledge(500, erc20.address)).to.be.revertedWith('Admin cannot pledge');
  });

  it("Should pass when other user pledges", async function () {
    await CampaignContract.connect(addr1).pledge(200, erc20.address)
    expect(await CampaignContract.connect(addr1).userDeposit(addr1.address).toString()).to.equal("200");
  });
});
