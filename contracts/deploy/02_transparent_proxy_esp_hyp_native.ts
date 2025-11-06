import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployWithCreate3 } from "../utils";
import { EspHypNative__factory } from "../typechain-types";
const SALT_STRING = "EspHypNativeTransparentProxy-salt-v1";

// TODO: complete via proxy transparent 
const deployEspHypNativeTransparentProxy: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, network, ethers, deployments } = hre;
  const { deployer } = await getNamedAccounts();
  const contractName = "TransparentUpgradeableProxy";
  const artifactName = "EspHypNative";
  const proxyAdminAddress = (await deployments.get("ProxyAdmin")).address;
  const espHypNativeImplementationAddress = (await deployments.get("EspHypNative_Implementation")).address;
  const mailboxAddress = process.env.MAILBOX_ADDRESS;
  const nftSalePrice = process.env.NFT_SALE_PRICE_WEI ? parseInt(process.env.NFT_SALE_PRICE_WEI) : 1;
  const destinationDomainId = process.env.DESTINATION_DOMAIN_ID ? parseInt(process.env.DESTINATION_DOMAIN_ID) : 1;
  if (!mailboxAddress) {
    throw new Error("MAILBOX_ADDRESS is not set");
  }
  const espHypNative = EspHypNative__factory.connect(espHypNativeImplementationAddress);
  const initializeV2DataCallData = espHypNative.interface.encodeFunctionData("initializeV2", [nftSalePrice, destinationDomainId]);
  console.log("deployer", deployer);
  console.log("balance", ethers.formatEther(await ethers.provider.getBalance(deployer)));
  console.log("network", network.name, network.config.chainId, network.config);
  const { address } = await deployWithCreate3(hre, {
    artifactName,
    contractName,
    deployer,
    salt: SALT_STRING,
    constructorArgs: [proxyAdminAddress, espHypNativeImplementationAddress, initializeV2DataCallData],
    confirmations: 5,
    overrides: { gasLimit: 5_000_000 },
  });
  console.log("create3 deployment address", address);
};

deployEspHypNativeTransparentProxy.tags = ["02", "esp_hyp_native_transparent_proxy", "all"];
export default deployEspHypNativeTransparentProxy;