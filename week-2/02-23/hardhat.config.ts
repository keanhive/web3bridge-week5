import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.20",
  networks: {
    liskSepolia: {
      url: "https://rpc.sepolia-api.lisk.com",
      accounts: process.env.PRIVATE_KEY
          ? [process.env.PRIVATE_KEY]
          : [],
      chainId: 4202,
    },
  },
};

export default config;
