import type { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-foundry";
import "hardhat-deploy";

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
      url: "https://ethereum-sepolia-rpc.publicnode.com",
    },
    apechain: {
      url: "https://rpc.apechain.com",
    },
    rari: {
      url: "https://mainnet.rpc.rarichain.org/http",
    },
    apechain_testnet: {
      url: "https://curtis.rpc.caldera.xyz/http",
    },
    rari_testnet: {
      url: "https://testnet.rpc.rarichain.org/http",
    },
  },
};

export default config;
