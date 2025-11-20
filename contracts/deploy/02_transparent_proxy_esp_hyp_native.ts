import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployWithCreate3 } from "../utils";
import { EspHypNative__factory } from "../typechain-types";
const SALT_STRING = "EspHypNativeTransparentProxy-salt-v2";

const deployEspHypNativeTransparentProxy: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, network, ethers, deployments } = hre;
  const { deployer } = await getNamedAccounts();
  const contractName = "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy";
  const artifactName = "EspHypNative";
  const proxyAdminAddress = (await deployments.get("ProxyAdmin")).address;
  const espHypNativeImplementationAddress = (await deployments.get("EspHypNative_Implementation")).address;

  const hook = process.env.HOOK!;
  const interchainSecurityModule = process.env.INTERCHAIN_SECURITY_MODULE!;
  const owner = process.env.OWNER!;
  const nftSalePrice = process.env.NFT_SALE_PRICE_WEI!;
  const destinationDomainId = process.env.DESTINATION_DOMAIN_ID!;
  const startSale = process.env.START_SALE!;
  if (!hook || !interchainSecurityModule || !owner || !nftSalePrice || !destinationDomainId || !startSale) {
    throw new Error("Missing required environment variables");
  }

  const espHypNative = EspHypNative__factory.connect(espHypNativeImplementationAddress);

  const initializeDataCallData = espHypNative.interface.encodeFunctionData("initializeV3", [hook, interchainSecurityModule, owner, nftSalePrice, destinationDomainId, startSale]);
  console.log("deployer", deployer);
  console.log("balance", ethers.formatEther(await ethers.provider.getBalance(deployer)));
  console.log("network", network.name, network.config.chainId, network.config);
  const { address } = await deployWithCreate3(hre, {
    artifactName,
    contractName,
    deployer,
    salt: SALT_STRING,
    constructorArgs: [espHypNativeImplementationAddress, proxyAdminAddress, initializeDataCallData],
    confirmations: 5,
    overrides: { gasLimit: 5_000_000 },
  });
  console.log("create3 deployment address", address);
};

deployEspHypNativeTransparentProxy.tags = ["02", "esp_hyp_native_transparent_proxy", "all"];
export default deployEspHypNativeTransparentProxy;