// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  const rewardMaster = await ethers.getContractFactory("RewardManager");
  const rM = await rewardMaster.deploy();

  const CC = await ethers.getContractFactory("ContributionCertificate");
  const cc = await CC.deploy("0xe81eAffA679B00279f664877C57e895606dB55Cf");

  console.log("Reward Master address:", rM.address);

  console.log("CC address:", cc.address);

  await hre.run("verify:verify", {
    address: rM.address,
  });

  await hre.run("verify:verify", {
    address: cc.address,
    constructorArguments: ["0xe81eAffA679B00279f664877C57e895606dB55Cf"],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
