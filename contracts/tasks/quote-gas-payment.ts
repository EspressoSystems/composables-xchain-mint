import { task, types } from "hardhat/config";
import { formatUnits, getAddress } from "ethers";
import { HYPERLANE_DOMAINS } from "../utils/hyperlane";

type SupportedUnit = "wei" | "gwei" | "ether";

const SUPPORTED_UNITS: SupportedUnit[] = ["wei", "gwei", "ether"];

function normalizeUnit(unit: string | undefined): SupportedUnit {
  const normalized = (unit ?? "wei").toLowerCase();

  if (SUPPORTED_UNITS.includes(normalized as SupportedUnit)) {
    return normalized as SupportedUnit;
  }

  throw new Error(
    `Unsupported unit "${unit}". Supported units: ${SUPPORTED_UNITS.join(", ")}`
  );
}

function parseBigInt(value: string, field: string): bigint {
  try {
    return BigInt(value);
  } catch (error) {
    throw new Error(`Invalid ${field} "${value}". Expected an integer string.`);
  }
}


task(
  "quote-gas-payment",
  "Calls InterchainGasPaymaster.quoteGasPayment and prints the required payment"
)
  .addParam("contract", "InterchainGasPaymaster contract address")
  .addOptionalParam("destinationDomain", "Hyperlane domain ID for the destination chain", undefined, types.int)
  .addParam(
    "gasLimit",
    "Destination chain gas amount to prepay (integer)",
    undefined,
    types.string
  )
  .addOptionalParam(
    "outputUnit",
    "Unit to format the quote. Supported: wei, gwei, ether",
    "wei"
  )
  .setAction(async ({ contract, destinationDomain, gasLimit, outputUnit }, hre) => {
    const { ethers } = hre;
    const runner = (await ethers.getSigners())[0] ?? ethers.provider;
    const { InterchainGasPaymaster__factory } = await import("../typechain-types");

    const contractAddress = getAddress(contract);
    const interchainGasPaymaster = InterchainGasPaymaster__factory.connect(
      contractAddress,
      runner
    );
    
    if(!destinationDomain) {
        if(hre.network.name === "apechain") {
        destinationDomain = HYPERLANE_DOMAINS.RARIChain;
        } else if(hre.network.name === "rari") {
        destinationDomain = HYPERLANE_DOMAINS.ApeChain;
        } else {
        throw new Error(`Unsupported network: ${hre.network.name}`);
        }
    }

    if (!Number.isInteger(destinationDomain) || destinationDomain < 0) {
      throw new Error(
        `destinationDomain must be a non-negative integer. Received: ${destinationDomain}`
      );
    }

    const gasAmount = parseBigInt(gasLimit, "gasLimit");
    const quoteWei = await interchainGasPaymaster.quoteGasPayment(
      destinationDomain,
      gasAmount
    );

    const unit = normalizeUnit(outputUnit);
    const formatted = formatUnits(quoteWei, unit);

    console.log("Interchain gas payment quote:");
    console.log(`  contract: ${interchainGasPaymaster.target}`);
    console.log(`  destinationDomain: ${destinationDomain}`);
    console.log(`  gasLimit: ${gasAmount}`);
    console.log(`  quoteWei: ${quoteWei.toString()}`);
    if (unit !== "wei") {
      console.log(`  quote${unit}: ${formatted}`);
    } else {
      console.log(`  quote: ${formatted} ${unit}`);
    }
  });
