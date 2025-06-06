import React from 'react'
import ReactDOM from 'react-dom/client'
import { WagmiConfig, createClient, configureChains } from 'wagmi'
import { RainbowKitProvider, getDefaultWallets } from '@rainbow-me/rainbowkit'
import '@rainbow-me/rainbowkit/styles.css'
import './index.css'
import App from './App.jsx'
import { CHAINS, RPC_URLS } from './config'
import { customTheme } from './theme'

// Configure supported chains and providers, using custom RPC URLs or defaults
const { chains, provider } = configureChains(CHAINS, [
  ({ chain }) => ({
    http: RPC_URLS[chain.id] || chain.rpcUrls.default.http[0],
  }),
])

// Set up connectors for RainbowKit
const { connectors } = getDefaultWallets({
  appName: 'NFT Minter',
  chains,
})

// Create Wagmi client
const wagmiClient = createClient({
  autoConnect: true,
  connectors,
  provider,
})

// Render application with providers
ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <WagmiConfig client={wagmiClient}>
      <RainbowKitProvider chains={chains} theme={customTheme}>
        <App />
      </RainbowKitProvider>
    </WagmiConfig>
  </React.StrictMode>,
)
