import type { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-foundry";
import "hardhat-deploy";

import dotenv from "dotenv";
dotenv.config();

const DEPLOYER_PRIVATE_KEY = process.env.DEPLOYER_PRIVATE_KEY!;

const config: HardhatUserConfig = {
  solidity: "0.8.30",
  networks: {
    hardhat: {
      chainId: 31337,
    },
    mainnet: {
      url: "https://ethereum-rpc.publicnode.com",
    },
    sepolia: {
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
      url: "https://ethereum-sepolia-rpc.publicnode.com",
    },
    apechain: {
      url: "https://rpc.apechain.com",
    },
    rari: {
      url: "https://mainnet.rpc.rarichain.org/http",
    },
    apechain_testnet: {
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
      url: "https://curtis.rpc.caldera.xyz/http",
    },
    rari_testnet: {
      url: "https://testnet.rpc.rarichain.org/http",
    },
  },
  namedAccounts: {
    // Fallback to the first local account if the env-vars are missing
    deployer: 0,
  },
  verify: {
    etherscan: {
      apiKey: process.env.ETHERSCAN_API_KEY,
    },
  },
};

export default config;
