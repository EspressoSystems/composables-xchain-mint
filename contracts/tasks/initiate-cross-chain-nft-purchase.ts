import { task } from "hardhat/config";
import { getAddress, isAddress, isHexString, parseUnits, zeroPadValue } from "ethers";



type SupportedUnit = "wei" | "gwei" | "ether";

const SUPPORTED_UNITS: SupportedUnit[] = ["wei", "gwei", "ether"];

function normalizeRecipient(recipient: string): string {
  const trimmed = recipient.trim();

  if (isHexString(trimmed, 32)) {
    return trimmed;
  }

  if (isAddress(trimmed)) {
    return zeroPadValue(getAddress(trimmed), 32);
  }

  throw new Error(
    `Invalid recipient provided. Expected a 20-byte address or 32-byte hex string, received: ${recipient}`
  );
}

function normalizeUnit(unit: string | undefined): SupportedUnit {
  const normalized = (unit ?? "wei").toLowerCase();

  if (SUPPORTED_UNITS.includes(normalized as SupportedUnit)) {
    return normalized as SupportedUnit;
  }

  throw new Error(
    `Unsupported unit "${unit}". Supported units: ${SUPPORTED_UNITS.join(", ")}`
  );
}

task(
  "initiate-cross-chain-nft-purchase",
  "Calls EspHypNative.initiateCrossChainNftPurchase with the provided signer"
)
  .addParam("contract", "EspHypNative (proxy) contract address")
  .addParam(
    "recipient",
    "Destination chain recipient. Accepts an EVM address or 32-byte hex string"
  )
  .addOptionalParam(
    "value",
    "Total msg.value to forward to the contract. Parsed using valueUnit when provided"
  )
  .addOptionalParam(
    "valueUnit",
    "Unit for the optional value parameter. Supported: wei, gwei, ether",
    "wei"
  )
  .addOptionalParam(
    "hookPaymentWei",
    "Additional wei to fund the Hyperlane hook payment when value is omitted",
    "0"
  )
  .setAction(
    async ({ contract, recipient, value, valueUnit, hookPaymentWei }, hre) => {
      const { ethers } = hre;

      const signer = (await ethers.getSigners())[0];
      if (!signer) {
        throw new Error(
          "No signer available. Configure an account for the selected network."
        );
      }
      const { EspHypNative__factory } = await import("../typechain-types");

      const contractAddress = getAddress(contract);
      const espHypNative = EspHypNative__factory.connect(contractAddress, signer);

      const hookPayment = BigInt(hookPaymentWei);
      let msgValue: bigint;

      if (value !== undefined) {
        const unit = normalizeUnit(valueUnit);
        msgValue = parseUnits(value, unit);
      } else {
        const salePrice = await espHypNative.nftSalePriceWei();
        msgValue = salePrice + hookPayment;
      }

      const recipientBytes32 = normalizeRecipient(recipient);

      const messageId =
        await espHypNative.initiateCrossChainNftPurchase.staticCall(
          recipientBytes32,
          { value: msgValue }
        );

      const tx = await espHypNative.initiateCrossChainNftPurchase(
        recipientBytes32,
        { value: msgValue }
      );

      const receipt = await tx.wait();

      console.log("Cross-chain NFT purchase initiated:");
      console.log(`  messageId: ${messageId}`);
      console.log(`  txHash: ${receipt?.hash ?? tx.hash}`);
      console.log(`  blockNumber: ${receipt?.blockNumber}`);
      console.log(`  gasUsed: ${receipt?.gasUsed?.toString() ?? "unknown"}`);
    }
  );
