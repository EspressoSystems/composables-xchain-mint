## Set Up

Install the Hyperlane [CLI](https://docs.hyperlane.xyz/docs/reference/cli) using the following command:
`npm install -g @hyperlane-xyz/cli `

Run the following commands from the `anvil` directory unless otherwise stated. 

Set Hyperlane environment variables
```
source .hyperlane_env
```

In a separate terminal, launch the source chain anvil node; note this script automatically sources the environment variables: 
``` 
./anvil/launch_source_chain.sh

```
In a separate terminal, launch the destination chain anvil node: 
``` 
./anvil/launch_destination_chain.sh

```

To confirm Hyperlane has been correctly deployed, run the following commands on the source and destination chains.  Use the `mailbox` address listed in each chain's `adresses.yaml` file. This call should return the chain's Hyperlane domain (which in this case is set to its chain id). 

`cast call <mailbox_addr>> "localDomain()(uint32)" --rpc-url $SOURCE_CHAIN_RPC_URL`


## Deploy Hyperlane
The following instructions are only needed to re-deploy Hyperlane contracts.  The state dumps provided for each node already contain deployed Hyperlane contracts.  

The below uses the HYP_KEY key as the contracts' owner and relayer key. 

```hyperlane registry init``` for the source chain

```hyperlane registry init``` for the destination chain
Note: this command stores config data in the user's home directory.  For convenience, these configs can be found in the `hyperlane` directory here. 

``` hyperlane core init --advanced  ``` The advanced flag allows deploying an IGP.  Set the default hook to the merkleTeeHook and the required hook to the IGP hook.  Currently the ISM is the `trustedRelayer` ISM.  This will change once we switch to the Espresso ISM. 


`hyperlane core deploy --registry hyperlane/ --config hyperlane/chains/source/core-config.yaml    ` Deploys the Hyperlane contracts on the source chain using the config and registry in this repo instead of the defaults.  Run this command again for the destination chain, changing the parameters where appropriate. 

`hyperlane send message --relay --registry hyperlane/` To send a test message.  If successful, then the Hyperlane contracts have been successfully deployed. 



See here for additional docs: https://docs.hyperlane.xyz/docs/deploy-hyperlane


To run the relayer: 
`hyperlane relayer --registry hyperlane`
The relayer will not output any data until it finds a message to relay. Specificying the `--verbosity` flag may help with debugging. 

To send a test message using the relayer: 
`hyperlane send message  --registry hyperlane/ `










