<!-- Returns the Composables NFT name() on RARI mainnet -->
cast call 0x955210590d6de2181844c3f38a3325859a382d55 "name()" --rpc-url http://127.0.0.1:8545 | cast --to-ascii

Hyperlane Rari deployment addr: 0x65dCf8F6b3f6a0ECEdf3d0bdCB036AEa47A1d615

<!-- Returns the local domain for Hyperlane from HL's mailbox on RARI -->
cast call 0x65dCf8F6b3f6a0ECEdf3d0bdCB036AEa47A1d615 "localDomain()" --rpc-url http://127.0.0.1:8545 | cast --to-dec
1000012617

<!-- Must use the --registry flag to point to local rari config instead of mainnet rari config.  Otherwise there is a collision with the offical registry -->
hyperlane core init --registry ~/.hyperlane

<!-- Just following the HL docs steps do twice for each chain
TODO figure out how to set RARI's HL addresses that already exist. -->
hyperlane core deploy --registry ~/.hyperlane

"totalSupply()(uint256)"
0xE6E340D132b5f46d1e472DebcD681B2aBc16e57E

cast balance --erc20 0xE6E340D132b5f46d1e472DebcD681B2aBc16e572 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

<!-- To get to execute on Rari chain -->
contracts % forge test --rpc-url http://127.0.0.1:8545 --match-contract AnvilTest

do a dry run of hyperlane contract deployments

need to do --advanced when core init to get gas paymaster

