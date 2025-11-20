import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployWithCreate3 } from "../utils";
const SALT_STRING = "EspHypERC20-salt-v1";

const deployEspHypERC20: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, network, ethers } = hre;
  const { deployer } = await getNamedAccounts();
  const contractName = "EspHypERC20";
  const artifactName = "EspHypERC20_Implementation";
  const decimals = process.env.DECIMALS ? parseInt(process.env.DECIMALS) : 18;
  const scale = process.env.SCALE ? parseInt(process.env.SCALE) : 1;
  const mailboxAddress = process.env.MAILBOX_ADDRESS;
  if (!mailboxAddress) {
    throw new Error("MAILBOX_ADDRESS is not set");
  }
  console.log("deployer", deployer);
  console.log("balance", ethers.formatEther(await ethers.provider.getBalance(deployer)));
  console.log("network", network.name, network.config.chainId, network.config);
  const { address } = await deployWithCreate3(hre, {
    artifactName,
    contractName,
    deployer,
    salt: SALT_STRING,
    constructorArgs: [decimals,scale, mailboxAddress],
    confirmations: 5,
    overrides: { gasLimit: 5_000_000 },
  });å
  console.log("create3 deployment address", address);
};

deployEspHypERC20.tags = ["03", "esp_hyp_erc20", "all"];
export default deployEspHypERC20;