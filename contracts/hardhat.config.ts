import type { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-foundry";
import "hardhat-deploy";

import dotenv from "dotenv";
dotenv.config();

const FRAME_URL = "http://127.0.0.1:1248";
const TIMEOUT = 120000;

const config: HardhatUserConfig = {
  solidity: "0.8.30",
  networks: {
    hardhat: {
      chainId: 31337,
    },
    mainnet: {
      url: FRAME_URL,
      chainId: 1,
      timeout: TIMEOUT,
    },
    sepolia: {
      url: FRAME_URL,
      chainId: 11155111,
      timeout: TIMEOUT,
    },
    apechain: {
      url: FRAME_URL,
      chainId: 33139,
      timeout: TIMEOUT,
    },
    rari: {
      url: FRAME_URL,
      chainId: 1380012617,
      timeout: TIMEOUT,
    },
    apechain_testnet: {
      url: FRAME_URL,
      chainId: 33111,
      timeout: TIMEOUT,
    },
    rari_testnet: {
      url: FRAME_URL,
      chainId: 1918988905,
      timeout: TIMEOUT,
    },
  },
  namedAccounts: {
    // Fallback to the first local account if the env-vars are missing
    deployer: 0,
  },
  verify: {
    etherscan: {
      apiKey: "xyz",
    },
  },
  etherscan: {
    apiKey: {
      apechain_testnet: "xyz",
      rari: "xyz",
      rari_testnet: "xyz",
      mainnet: "xyz",
      apechain: "xyz",
      sepolia: "xyz",
    },
    customChains: [
      {
        network: "apechain_testnet",
        chainId: 33111,
        urls: {
          apiURL: "https://curtis.explorer.caldera.xyz/api",
          browserURL: "https://curtis.explorer.caldera.xyz/"
        }
      },
      {
        network: "apechain",
        chainId: 33139,
        urls: {
          apiURL: "https://api.apescan.io/api",
          browserURL: "https://explorer.apechain.com/"
        }
      },
      {
        network: "rari",
        chainId: 1380012617,
        urls: {
          apiURL: "https://mainnet.explorer.rarichain.org/api",
          browserURL: "https://mainnet.explorer.rarichain.org/"
        }
      },
      {
        network: "rari_testnet",
        chainId: 1918988905,
        urls: {
          apiURL: "https://testnet.explorer.rarichain.org/api",
          browserURL: "https://testnet.explorer.rarichain.org/"
        }
      },
      {
        network: "sepolia",
        chainId: 11155111,
        urls: {
          apiURL: "https://eth-sepolia.blockscout.com/api",
          browserURL: "https://eth-sepolia.blockscout.com/"
        }
      },
      {
        network: "mainnet",
        chainId: 1,
        urls: {
          apiURL: "https://eth.blockscout.com/api",
          browserURL: "https://eth.blockscout.com/"
        }
      },
    ],
  },
};

export default config;