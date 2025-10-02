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

launch-chains:
    #!/usr/bin/env bash
    set -euo pipefail
    set -x
    just kill-chains
    tmux new-session -d -s chains -n chains "cd anvil && ./launch_destination_chain.sh 2>&1 | tee /tmp/xchain-anvil-destination.log"
    tmux select-pane -t chains:chains.0 -T "anvil: destination chain"
    tmux split-window -t chains:chains -v "cd anvil && ./launch_source_chain.sh 2>&1 | tee /tmp/xchain-anvil-source.log"
    tmux select-pane -t chains:chains.1 -T "anvil: source chain"
    tmux set -t chains:chains pane-border-status top
    tmux set -t chains:chains pane-border-format "#{pane_index}: #{pane_title}"

launch-hyperlane-services:
    #!/usr/bin/env bash
    set -euo pipefail
    source anvil/.hyperlane_env

    cd anvil/hyperlane/validator-relayer-setup
    if [ -f .env ]; then
        echo ".env file exists, skipping copy"
    else
        echo ".env file does not exist, copying from env.example"
        cp env.example .env
    fi
    ./scripts/update-agent-config.sh

    tmux split-window -t chains:chains -v "docker compose up source-validator"
    tmux select-pane -t chains:chains.2 -T "hyperlane: validator"
    tmux split-window -t chains:chains -v "docker compose up relayer"
    tmux select-pane -t chains:chains.3 -T "hyperlane: source-relayer"

    # # Arrange panes in equal tiles
    tmux select-layout -t chains:chains even-vertical
    tmux set -t chains:chains pane-border-status top
    tmux set -t chains:chains pane-border-format "#{pane_index}: #{pane_title}"

launch:
    #!/usr/bin/env bash
    set -euo pipefail
    just launch-chains
    just launch-hyperlane-services
    # attach only if we have a real terminal
    if [ -t 0 ] && [ -t 1 ]; then
        tmux attach -t chains
    fi

kill-chains:
    #!/usr/bin/env bash
    set -euo pipefail
    tmux kill-session -t chains 2>/dev/null || echo "No chains session to kill"
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

# xchain-send:
#     #!/usr/bin/env bash
#     set -euo pipefail
#     source anvil/.hyperlane_env
#     cd contracts
#     source script/load-deployment-addresses
#     # source env.example
#     # WIP: this currently fails
#     ./script/xchain-send/xchain_send.sh

# upgrade-tokens:
#     #!/usr/bin/env bash
#     set -euo pipefail
#     source anvil/.hyperlane_env
#     cd contracts
#     source script/load-deployment-addresses
#     source env.example
#     ./script/token-upgrade/upgrade_tokens.sh
