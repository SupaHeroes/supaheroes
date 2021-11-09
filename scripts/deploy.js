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

  // const Headquarter = await ethers.getContractFactory("Headquarter");
  // const hq = await Headquarter.deploy();

  // console.log("Headquarter address:", hq.address);

  const factory = await ethers.getContractFactory("StandardCampaignFactory");
  const fc = await factory.deploy();

  // const station = await ethers.getContractFactory("Station");
  // const st = await station.deploy();

  console.log("Factory address:", fc.address);
  // console.log("Station address:", st.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
