/**
 * Configuration file for chains, contract addresses, and ABI.
 * Update the contract addresses and ABI as needed for your NFT contract.
 */
import { mainnet, polygon, optimism, arbitrum } from 'wagmi/chains'

/**
 * List of supported chains for minting.
 * You can add or remove chains from this array as needed.
 */
export const CHAINS = [mainnet, polygon, optimism, arbitrum]

/**
 * Mapping from chain ID to NFT contract address.
 * Replace the placeholder addresses with your deployed contract addresses.
 */
export const NFT_CONTRACT_ADDRESSES = {
  [mainnet.id]: '0xYourMainnetContractAddress',
  [polygon.id]: '0xYourPolygonContractAddress',
  [optimism.id]: '0xYourOptimismContractAddress',
  [arbitrum.id]: '0xYourArbitrumContractAddress',
}

/**
 * Minimal ABI for the mint function of your NFT contract.
 * Update this ABI if your contract has a different signature or parameters.
 */
export const NFT_ABI = [
  {
    inputs: [],
    name: 'mint',
    outputs: [],
    stateMutability: 'payable',
    type: 'function',
  },
]

/**
 * Optional custom RPC URLs for each chain.
 * Provide these in a .env file (see .env.example) for private or faster RPC endpoints.
 */
export const RPC_URLS = {
  [mainnet.id]: import.meta.env.VITE_RPC_URL_MAINNET,
  [polygon.id]: import.meta.env.VITE_RPC_URL_POLYGON,
  [optimism.id]: import.meta.env.VITE_RPC_URL_OPTIMISM,
  [arbitrum.id]: import.meta.env.VITE_RPC_URL_ARBITRUM,
}