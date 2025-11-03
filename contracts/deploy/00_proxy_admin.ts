import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { ICREATE3Factory__factory, ProxyAdmin__factory } from "../typechain-types";
import { ethers } from "ethers";

import { CREATE3_FACTORY_ADDRESS } from "../utils"
const SALT_STRING = "ProxyAdmin-v1";

const deployRariOFT: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, network, ethers } = hre;
  const { deployer, getSigner } = await getNamedAccounts();
  const signer = await  ethers.getSigner(deployer);

  const create3 = ICREATE3Factory__factory.connect(CREATE3_FACTORY_ADDRESS);
  const factory = await ethers.getContractFactory("ProxyAdmin", signer) as ProxyAdmin__factory;
  const creationBytecode = (await factory.getDeployTransaction(deployer)).data as string;
  const salt = ethers.keccak256(ethers.toUtf8Bytes(SALT_STRING));
  const expectedAddr = await create3.getDeployed(deployer, salt);
  const code = await ethers.provider.getCode(expectedAddr);
  if (code === "0x") {
    const tx = await create3.deploy(salt, creationBytecode, { gasLimit: 5000000 });
    await tx.wait();
    console.log("RariOFT deployed to:", expectedAddr);
  } else {
    console.log("RariOFT already deployed at:", expectedAddr);
  }
};

deployRariOFT.tags = ["00", "proxy_admin", "all"];
export default deployRariOFT;