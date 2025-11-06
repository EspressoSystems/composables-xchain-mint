import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployWithCreate3 } from "../utils";
const SALT_STRING = "ProxyAdmin-salt-v1";

const deployProxyAdmin: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, network, ethers } = hre;
  const { deployer } = await getNamedAccounts();
  const contractName = "ProxyAdmin";
  const artifactName = "ProxyAdmin";
  const owner = deployer;
  console.log("deployer", deployer);
  console.log("balance", ethers.formatEther(await ethers.provider.getBalance(deployer)));
  console.log("network", network.name, network.config.chainId, network.config);
  const { address } = await deployWithCreate3(hre, {
    artifactName,
    contractName,
    deployer,
    salt: SALT_STRING,
    constructorArgs: [owner],
    confirmations: 5,
    overrides: { gasLimit: 5_000_000 },
  });
  console.log("create3 deployment address", address);
};

deployProxyAdmin.tags = ["00", "proxy_admin", "all"];
export default deployProxyAdmin;