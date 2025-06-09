## Set Up

Install the Hyperlane [CLI](https://docs.hyperlane.xyz/docs/reference/cli) using the following command:
`npm install -g @hyperlane-xyz/cli `

Run all the following commands from the `anvil` directory unless otherwise stated. 

Run the following to set environment variables
```
source .hyperlane_env
```

The following scripts use environment variables defined in `.hyperlane_env`. 
In a separate terminal, launch the source chain anvil node from inside the `anvil` directory: 
``` 
./anvil/launch_source_chain.sh

```
In a separate terminal, launch the destination chain anvil node: 
``` 
./anvil/launch_destination_chain.sh

```

Do the below instructions only if you need to redeploy the Hyperlane contracts from scratch.  These contracts are already deployed on the provided state dumps.  

The below uses the DEPLOYER key as the owner of the Hyperlane contracts. 

```hyperlane registry init``` for the source chain
```hyperlane registry init``` for the destination chain


``` hyperlane core init --advanced  ``` --> writes to the ```configs``` directory.  Need the advanced flag to set IGP. 

`hyperlane core deploy --registry hyperlane/    ` -> Points to this hyperlane directory instead of a local directory, do for each chain separately

`hyperlane send message --relay --registry hyperlane/` to test success

See here for docs: https://docs.hyperlane.xyz/docs/deploy-hyperlane










