import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { ICREATE3Factory__factory, ProxyAdmin__factory } from "../typechain-types";

import { CREATE3_FACTORY_ADDRESS } from "../utils"
const SALT_STRING = "ProxyAdmin-testnet-v4";

const deployRariOFT: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, network, ethers, deployments } = hre;
  const { deployer } = await getNamedAccounts();
  const contractName = "ProxyAdmin";
  console.log("deployer", deployer);
  console.log("balance", ethers.formatEther(await ethers.provider.getBalance(deployer)));
  console.log("network", network.name, network.config.chainId, network.config);
  const signer = await  ethers.getSigner(deployer);

  const create3 = ICREATE3Factory__factory.connect(CREATE3_FACTORY_ADDRESS, signer);
  const factory = await ethers.getContractFactory(contractName, signer) as ProxyAdmin__factory;

//   console.log("deploying ProxyAdmin via standard deploy");
//   const transferProxyReceipt = await deployments.deploy(contractName, {
//     from: deployer,
//     args: [deployer],
//     log: true,
//     autoMine: true,
//   });
//   console.log("transferProxyReceipt", transferProxyReceipt.transactionHash);

  const creationBytecode = (await factory.getDeployTransaction(deployer)).data as string;
  const salt = ethers.keccak256(ethers.toUtf8Bytes(SALT_STRING));
  console.log("getting deployed address");
  const expectedAddr = await create3.getDeployed(deployer, salt);
  console.log("expectedAddr", expectedAddr);
  const code = await ethers.provider.getCode(expectedAddr);
  if (code === "0x") {
    console.log("deploying ProxyAdmin via create3");
    const tx = await create3.deploy(salt, creationBytecode, { gasLimit: 5000000 });
    const receipt = await tx.wait(5);
    if (!receipt) {
      throw new Error("Transaction receipt is null");
    }
    console.log("ProxyAdmin deployed to:", expectedAddr);
    // const deployment = await deployments.getDeploymentsFromAddress(expectedAddr);
    // await hre.deployments.save("ProxyAdmin.json", deployment[0]);

    const extendedArtifact = await deployments.getExtendedArtifact("ProxyAdmin");
    console.log("extendedArtifact", JSON.stringify(extendedArtifact, null, 2));

    await deployments.save("ProxyAdmin4", {
        abi: extendedArtifact.abi,
        address: expectedAddr,
        bytecode: extendedArtifact.bytecode,
        deployedBytecode: extendedArtifact.deployedBytecode,
        metadata: extendedArtifact.metadata,
        solcInput: extendedArtifact.solcInput,
        solcInputHash: extendedArtifact.solcInputHash,
        userdoc: extendedArtifact.userdoc,
        devdoc: extendedArtifact.devdoc,
        methodIdentifiers: extendedArtifact.methodIdentifiers,
        args: [deployer],
        libraries: {},
        transactionHash: tx.hash,
        receipt: receipt.toJSON(),
    });
  } else {
    console.log("ProxyAdmin already deployed at:", expectedAddr);
    console.log("Saving deployment to file");

    try {
        const deployment = await deployments.getDeploymentsFromAddress(expectedAddr);
        console.log("deployment", deployment);
    } catch {
        const extendedArtifact = await deployments.getExtendedArtifact("ProxyAdmin4");
        console.log("extendedArtifact", JSON.stringify(extendedArtifact, null, 2));
    
        await deployments.save("ProxyAdmin4", {
            abi: extendedArtifact.abi,
            address: expectedAddr,
            bytecode: extendedArtifact.bytecode,
            deployedBytecode: extendedArtifact.deployedBytecode,
            metadata: extendedArtifact.metadata,
            solcInput: extendedArtifact.solcInput,
            solcInputHash: extendedArtifact.solcInputHash,
            userdoc: extendedArtifact.userdoc,
            devdoc: extendedArtifact.devdoc,
            methodIdentifiers: extendedArtifact.methodIdentifiers,
            args: [deployer],
            libraries: {},
        });
    }
  }
};

deployRariOFT.tags = ["00", "proxy_admin", "all"];
export default deployRariOFT;