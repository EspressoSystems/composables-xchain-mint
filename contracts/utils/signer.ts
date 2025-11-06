import { HardhatRuntimeEnvironment } from 'hardhat/types';

import { LedgerSigner } from "@anders-t/ethers-ledger";
import { ethers } from "@anders-t/ethers-ledger/node_modules/ethers";
import { Signer } from '@ethersproject/abstract-signer';

const { HARDWARE_DERIVATION } = process.env;

export async function getSigner(hre: HardhatRuntimeEnvironment): Promise<Signer>{
  const { getSigner } = hre.deployments;
  const { deployer } = await hre.getNamedAccounts();
  if (!HARDWARE_DERIVATION) {
    const signer = await getSigner(deployer);
    return signer;
  } else {
    const path = HARDWARE_DERIVATION.split(":")[1].replace("//", "");
    console.log("HARDWARE_DERIVATION", HARDWARE_DERIVATION);
    console.log("HARDWARE_DERIVATION", path);

    const { config } = hre.network;
    if (!('url' in config) || !config.url) {
      throw new Error('Ledger signer requires an HTTP network with a configured url');
    }

    const provider = new ethers.providers.JsonRpcProvider(config.url);
    
    const signer = new LedgerSigner(provider, path);
    return signer;
  }
}