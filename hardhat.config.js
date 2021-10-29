require("@nomiclabs/hardhat-waffle");


const KOVAN_PRIVATE_KEY = "b5511412491540cd9886f9f9626d7e529535fc511252afc15a3c8de22eea5822";
// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.6",
  networks: {
    kovan: {
      url: `https://eth-kovan.alchemyapi.io/v2/FvcgeGbfGA98giQK0-k3f23tt_L_Os8s`,
      accounts: [`0x${KOVAN_PRIVATE_KEY}`]
    }
  }
};
