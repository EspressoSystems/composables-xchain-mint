import React, { useState, useEffect } from 'react'
import { ConnectButton } from '@rainbow-me/rainbowkit'
import {
  useAccount,
  useChainId,
  useSwitchChain,
  usePrepareTransactionRequest,
  useSendTransaction,
  useWaitForTransactionReceipt,
} from 'wagmi'
import { encodeFunctionData } from 'viem'
import { NFT_CONTRACT_ADDRESSES, NFT_ABI, CHAINS } from './config'

/**
 * Main application component for NFT minting.
 */
function App() {
  const { address, isConnected } = useAccount()
  const chainId = useChainId()
  const { switchChain } = useSwitchChain()

  // State to control dropdown visibility and selected chain for minting
  const [showDropdown, setShowDropdown] = useState(false)
  const [selectedChainId, setSelectedChainId] = useState()

  // Prepare the mint transaction
  const { config } = usePrepareTransactionRequest({
    request: {
      to: NFT_CONTRACT_ADDRESSES[chainId],
      data: encodeFunctionData({
        abi: NFT_ABI,
        functionName: 'mint',
        args: [],
      }),
      value: 0n, // Update mint price in config.js if needed
    },
  })

  const { data, sendTransaction } = useSendTransaction(config)
  const { isLoading, isSuccess, error } = useWaitForTransactionReceipt({
    hash: data?.hash,
  })

  // Toggle dropdown when clicking the mint button
  const handleMintClick = () => {
    if (!isConnected) return
    setShowDropdown((prev) => !prev)
  }

  // Handle the chain selection and initiate transaction
  const handleChainSelect = (e) => {
    const newChainId = Number(e.target.value)
    setSelectedChainId(newChainId)

    if (newChainId !== chainId && switchChain) {
      switchChain(newChainId)
    } else {
      sendTransaction?.()
    }
    setShowDropdown(false)
  }

  // If network was switched, call sendTransaction after switch completes
  useEffect(() => {
    if (selectedChainId === chainId) {
      sendTransaction?.()
    }
  }, [chainId, selectedChainId, sendTransaction])

  return (
    <div className="app">
      <h1>NFT Minter</h1>
      <ConnectButton />
      {isConnected ? (
        <>
          <button onClick={handleMintClick}>Mint</button>
          {showDropdown && (
            <select onChange={handleChainSelect} defaultValue="">
              <option value="" disabled>
                Select Chain
              </option>
              {CHAINS.map((chain) => (
                <option key={chain.id} value={chain.id}>
                  {chain.name}
                </option>
              ))}
            </select>
          )}
          {isLoading && <p>Minting in progress...</p>}
          {isSuccess && <p>Mint successful! Transaction: {data?.hash}</p>}
          {error && <p>Error: {error.message}</p>}
        </>
      ) : (
        <p>Please connect your wallet to mint an NFT.</p>
      )}
    </div>
  )
}

export default App
