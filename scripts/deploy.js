// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const campaignMaster = await ethers.getContractFactory("StandardCampaignStrategy");
  const cM = await campaignMaster.deploy();
  const rewardMaster = await ethers.getContractFactory("RewardManager");
  const rM = await rewardMaster.deploy();
  const vestingMaster = await ethers.getContractFactory("VestingManager");
  const vM = await vestingMaster.deploy();

  const Token = await ethers.getContractFactory("SupaToken");
  const Tk = await Token.deploy();

  const factory = await ethers.getContractFactory("CampaignFactory");
  const fc = await factory.deploy(cM.address, rM.address, vM.address);

  const CC = await ethers.getContractFactory("ContributionCertificate");
  const cc = await CC.deploy(fc.address);
  
  console.log("Campaign Master address:", cM.address);
  console.log("Reward Master address:", rM.address);
  console.log("Vesting Master address:", vM.address);
  console.log("Factory address:", fc.address);
  console.log("CC address:", cc.address);
  console.log("Token address:", Tk.address);

  await hre.run("verify:verify", {
    address: fc.address,
    constructorArguments: [
      cM.address, rM.address, vM.address
    ],
  });

  await hre.run("verify:verify", {
    address: cM.address
  });

  await hre.run("verify:verify", {
    address: rM.address
  });

  await hre.run("verify:verify", {
    address: vM.address
  });

  await hre.run("verify:verify", {
    address: Tk.address,
  });
  
  await hre.run("verify:verify", {
    address: cc.address,
    constructorArguments: [
      fc.address
    ],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
