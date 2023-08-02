require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.19",
  networks: {
    ganache:  {
      url: process.env.PROVIDER_URL,
      accounts:[`0x${process.env.PRIVATE_KEY_GANACHE}`]
    },
    sepolia:  {
      url: process.env.API_URL,
      accounts:[`0x${process.env.PRIVATE_KEY_SEPOLIA}`]
    }
  }
};
