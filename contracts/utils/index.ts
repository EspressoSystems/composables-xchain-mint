import type { ContractTransactionReceipt } from "ethers";
import type { HardhatRuntimeEnvironment } from "hardhat/types";

import { ICREATE3Factory__factory } from "../typechain-types";
import type { PayableOverrides } from "../typechain-types/common";

export const CREATE3_FACTORY_ADDRESS = "0x4A6B3E61fE44352f8ae9728e94C560F5493e1BAF";

export interface DeployWithCreate3Options {
  artifactName: string;
  contractName: string;
  deployer: string;
  salt: string;
  constructorArgs?: unknown[];
  confirmations?: number;
  overrides?: PayableOverrides;
}

export interface DeployWithCreate3Result {
  address: string;
  deployed: boolean;
  receipt?: ContractTransactionReceipt;
}

export const deployWithCreate3 = async (
  hre: HardhatRuntimeEnvironment,
  options: DeployWithCreate3Options,
): Promise<DeployWithCreate3Result> => {
  const { ethers, deployments } = hre;
  const signer = await ethers.getSigner(options.deployer);

  const salt = ethers.keccak256(ethers.toUtf8Bytes(options.salt));
  const create3 = ICREATE3Factory__factory.connect(CREATE3_FACTORY_ADDRESS, signer);
  const factory = await ethers.getContractFactory(options.contractName, signer);
  const deployTx = await factory.getDeployTransaction(...(options.constructorArgs ?? []));
  const creationBytecode = deployTx.data;

  if (!creationBytecode) {
    throw new Error("Missing creation bytecode for contract deployment");
  }

  const expectedAddr = await create3.getDeployed(options.deployer, salt);
  const code = await ethers.provider.getCode(expectedAddr);

  const saveDeployment = async (txHash?: string, receipt?: ContractTransactionReceipt) => {
    const extendedArtifact = await deployments.getExtendedArtifact(options.contractName);

    await deployments.save(options.contractName, {
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
      args: options.constructorArgs ?? [],
      libraries: {},
      ...(txHash ? { transactionHash: txHash } : {}),
      ...(receipt
        ? {
            receipt: typeof receipt.toJSON === "function" ? receipt.toJSON() : receipt,
          }
        : {}),
    });
  };

  if (code === "0x") {
    console.log(`deploying ${options.contractName} via CREATE3`);
    const tx = options.overrides
      ? await create3.deploy(salt, creationBytecode, options.overrides)
      : await create3.deploy(salt, creationBytecode);
    const confirmations = options.confirmations ?? 5;
    console.log(`waiting for ${confirmations} confirmation(s)`);
    const receipt = await tx.wait(confirmations);
    if (!receipt) {
      throw new Error("Deployment transaction receipt is null");
    }
    console.log(`${options.contractName} deployed to:`, expectedAddr);
    await saveDeployment(tx.hash, receipt);
    return { address: expectedAddr, deployed: true, receipt };
  }

  console.log(`${options.contractName} already deployed at:`, expectedAddr);
  console.log("Saving deployment to file");

  try {
    await deployments.getDeploymentsFromAddress(expectedAddr);
    console.log("deployment retrieved from address, no need to save");
  } catch {
    console.log("no deployment found, saving new deployment");
    await saveDeployment();
  }

  return { address: expectedAddr, deployed: false };
};