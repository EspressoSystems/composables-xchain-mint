# Frontend Web3 NFT Minter

This is a React-based web3 frontend application for minting NFTs across multiple blockchains. It uses Wagmi and RainbowKit for wallet connection and transaction handling.

## Features

- Connect your wallet via RainbowKit.
- Select from predefined chains to mint your NFT.
- Easy to customize chain list, contract addresses, and ABI.
- Theme customization for colors, fonts, and more.

## Requirements

- Node.js v14 or higher
- npm

## Getting Started

1. Install dependencies:

   ```bash
   cd frontend
   npm install
   ```

2. Configure environment variables (optional):

   Copy the example and add your RPC URLs:

   ```bash
   cp .env.example .env
   # Then update .env with your RPC endpoints
   ```

3. Update contract addresses and ABI:

   Open `src/config.js` and replace placeholder contract addresses and ABI for your NFT contract.

4. Run the development server:

   ```bash
   npm run dev
   ```

   The app will be available at http://localhost:5173

## Building for Production

To create an optimized production build:

```bash
npm run build
```

You can preview the production build locally with:

```bash
npm run preview
```

## Customization

- **Chains and Contract**: Modify `src/config.js` to change supported chains, contract addresses, or ABI.
- **Theme**: Edit `src/theme.js` for RainbowKit theme customization, and update CSS variables in `src/index.css` for global styles.