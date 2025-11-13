import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployWithCreate3 } from "../utils";
import { EspHypERC20__factory } from "../typechain-types";
const SALT_STRING = "EspHypERC20TransparentProxy-salt-v1";

const deployEspHypERC20TransparentProxy: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, network, ethers, deployments } = hre;
  const { deployer } = await getNamedAccounts();
  const contractName = "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy";
  const artifactName = "EspHypERC20";
  const proxyAdminAddress = (await deployments.get("ProxyAdmin")).address;
  const espHypERC20ImplementationAddress = (await deployments.get("EspHypERC20_Implementation")).address;

  const rariMarketplace = process.env.RARI_MARKETPLACE;
  const destinationDomainId = process.env.DESTINATION_DOMAIN_ID;
  const hookPaymentWei = process.env.HOOK_PAYMENT_WEI;
  const treasuryEspresso = process.env.TREASURY_ESPRESSO;
  const treasuryPartner = process.env.TREASURY_PARTNER;
  const treasuryPercentageEspresso = process.env.TREASURY_PERCENTAGE_ESPRESSO;

  if (
    !rariMarketplace ||
    !destinationDomainId ||
    !hookPaymentWei ||
    !treasuryEspresso ||
    !treasuryPartner ||
    !treasuryPercentageEspresso
  ) {
    throw new Error("Missing required environment variables");
  }

  const destinationDomainIdValue = Number(destinationDomainId);
  if (!Number.isInteger(destinationDomainIdValue)) {
    throw new Error("DESTINATION_DOMAIN_ID must be an integer");
  }

  const treasuryPercentageEspressoValue = BigInt(treasuryPercentageEspresso);
  const hookPaymentValue = ethers.getBigInt(hookPaymentWei);

  const espHypERC20 = EspHypERC20__factory.connect(espHypERC20ImplementationAddress);

  const initializeDataCallData = espHypERC20.interface.encodeFunctionData("initializeV2", [
    rariMarketplace,
    destinationDomainIdValue,
    hookPaymentValue,
    {
      espresso: treasuryEspresso,
      partner: treasuryPartner,
      percentageEspresso: treasuryPercentageEspressoValue,
    },
  ]);
  console.log("deployer", deployer);
  console.log("balance", ethers.formatEther(await ethers.provider.getBalance(deployer)));
  console.log("network", network.name, network.config.chainId, network.config);
  const { address } = await deployWithCreate3(hre, {
    artifactName,
    contractName,
    deployer,
    salt: SALT_STRING,
    constructorArgs: [espHypERC20ImplementationAddress, proxyAdminAddress, initializeDataCallData],
    confirmations: 5,
    overrides: { gasLimit: 5_000_000 },
  });
  console.log("create3 deployment address", address);
};

deployEspHypERC20TransparentProxy.tags = ["04", "esp_hyp_erc20_transparent_proxy", "all"];
export default deployEspHypERC20TransparentProxy;