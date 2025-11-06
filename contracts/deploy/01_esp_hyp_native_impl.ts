import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployWithCreate3 } from "../utils";
const SALT_STRING = "EspHypNative-salt-v1";

// TODO: complete via proxy transparent 
const deployEspHypNative: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, network, ethers } = hre;
  const { deployer } = await getNamedAccounts();
  const contractName = "EspHypNative";
  const artifactName = "EspHypNative_Implementation";
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
    constructorArgs: [scale, mailboxAddress],
    confirmations: 5,
    overrides: { gasLimit: 5_000_000 },
  });
  console.log("create3 deployment address", address);
};

deployEspHypNative.tags = ["01", "esp_hyp_native", "all"];
export default deployEspHypNative;