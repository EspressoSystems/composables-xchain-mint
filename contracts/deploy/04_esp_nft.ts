import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployWithCreate3 } from "../utils";
const SALT_STRING = "EspNFT-salt-v1";

// TODO: complete via proxy transparent 
const deployEspNFT: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, network, ethers } = hre;
  const { deployer } = await getNamedAccounts();
  const contractName = "EspNFT";
  const artifactName = "EspNFT";
  const name = process.env.NAME;
  const symbol = process.env.SYMBOL;
  const baseImageURI = process.env.BASE_IMAGE_URI;
  const chainName = process.env.CHAIN_NAME;
  const espHypErc20 = process.env.HYPERLANE_TOKEN_ADDRESS;
  const treasury = process.env.TREASURY_ADDRESS;
  const nftSalePrice = process.env.NFT_SALE_PRICE_WEI ? parseInt(process.env.NFT_SALE_PRICE_WEI) : 1;
  if (!name || !symbol || !baseImageURI || !chainName || !espHypErc20 || !treasury || !nftSalePrice) {
    throw new Error("Missing required environment variables");
  }
  console.log("deployer", deployer);
  console.log("balance", ethers.formatEther(await ethers.provider.getBalance(deployer)));
  console.log("network", network.name, network.config.chainId, network.config);
  const { address } = await deployWithCreate3(hre, {
    artifactName,
    contractName,
    deployer,
    salt: SALT_STRING,
    constructorArgs: [name, symbol, baseImageURI, chainName, espHypErc20, treasury, nftSalePrice],
    confirmations: 5,
    overrides: { gasLimit: 5_000_000 },
  });
  console.log("create3 deployment address", address);
};

deployEspNFT.tags = ["03", "esp_nft", "all"];
export default deployEspNFT;