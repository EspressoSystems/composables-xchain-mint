# WIP: this recipe isn't complete
deploy:
    #!/usr/bin/env bash
    set -euo pipefail
    hyperlane core deploy  --config ./anvil/hyperlane/chains/source/core-config.yaml
    hyperlane core deploy  --config ./anvil/hyperlane/chains/destination/core-config.yaml
    cd anvil
    hyperlane warp deploy  --registry hyperlane
    cd ../contracts
    bash -e ./script/escrow/deploy-espresso-escrow-2-chain.sh
    bash -e ./script/token-upgrade/upgrade_tokens.sh

process-compose *args:
    #!/usr/bin/env bash
    # attach to tui if we have a real terminal
    if [ -t 0 ] && [ -t 1 ]; then
        process-compose {{ args }}
    else
        process-compose --tui=false {{ args }}
    fi

launch-chains:
    #!/usr/bin/env bash
    set -euo pipefail
    just kill-chains
    just process-compose up -n chains 

launch:
    #!/usr/bin/env bash
    set -euo pipefail
    just kill-chains

    # Setup hyperlane env
    source anvil/.hyperlane_env
    cd anvil/hyperlane/validator-relayer-setup
    if [ -f .env ]; then
        echo ".env file exists, skipping copy"
    else
        echo ".env file does not exist, copying from env.example"
        cp env.example .env
    fi
    ./scripts/update-agent-config.sh
    cd ../../..

    just process-compose up

kill-chains:
    #!/usr/bin/env bash
    set -euo pipefail
    process-compose down 2>/dev/null || echo "No process-compose services to kill"
    just clean || true

clean:
    #!/usr/bin/env bash
    set -euo pipefail
    cd anvil/hyperlane/validator-relayer-setup
    docker compose down -v
    ./scripts/cleanup.sh


install *args:
    #!/usr/bin/env bash
    set -euo pipefail
    cd contracts
    forge soldeer install {{ args }}

build *args:
    #!/usr/bin/env bash
    set -euo pipefail
    cd contracts
    forge build --via-ir {{ args }}

test *args:
    #!/usr/bin/env bash
    set -eo pipefail
    cd contracts
    set -a; source env.example; set +a
    forge test --via-ir {{ args }}

coverage *args:
    #!/usr/bin/env bash
    set -eo pipefail
    cd contracts
    set -a; source env.example; set +a
    forge coverage --ir-minimum --no-match-coverage "(script|Spec|mocks)" {{ args }}

test-e2e:
    #!/usr/bin/env bash
    set -euo pipefail
    source anvil/.hyperlane_env
    cd contracts
    source script/load-deployment-addresses
    set -a; source env.example; set +a
    bash -e ./script/xchain-full-send-mint/xchain_full_mint_to_destination.sh
    bash -e ./script/xchain-full-send-mint/xchain_full_mint_to_source.sh


# upgrade-tokens:
#     #!/usr/bin/env bash
#     set -euo pipefail
#     source anvil/.hyperlane_env
#     cd contracts
#     source script/load-deployment-addresses
#     source env.example
#     ./script/token-upgrade/upgrade_tokens.sh
