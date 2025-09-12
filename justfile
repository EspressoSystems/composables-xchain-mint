launch-chains:
    #!/usr/bin/env bash
    set -euo pipefail
    set -x
    tmux kill-session -t chains 2>/dev/null || true
    tmux new-session -d -s chains -n chains "cd anvil && ./launch_destination_chain.sh"
    tmux split-window -t chains:chains -v "cd anvil && ./launch_source_chain.sh"
    tmux attach -t chains

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
    # tmux split-window -t chains:chains -v "docker compose up"
    docker compose up


kill-chains:
    #!/usr/bin/env bash
    set -euo pipefail
    tmux kill-session -t chains 2>/dev/null || echo "No chains session to kill"

upgrade-tokens:
    #!/usr/bin/env bash
    set -euo pipefail
    source anvil/.hyperlane_env
    cd contracts
    source script/load-deployment-addresses
    source env.example
    ./script/token-upgrade/upgrade_tokens.sh

test-e2e:
    #!/usr/bin/env bash
    set -euo pipefail
    source anvil/.hyperlane_env
    cd contracts
    source script/load-deployment-addresses
    source env.example
    ./script/xchain-full-send-mint/xchain_full_mint.sh

xchain-send:
    #!/usr/bin/env bash
    set -euo pipefail
    source anvil/.hyperlane_env
    cd contracts
    source script/load-deployment-addresses
    source env.example
    ./script/xchain-send/xchain_send.sh
