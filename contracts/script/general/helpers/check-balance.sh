# Load .env
export $(grep -v '^#' .env | xargs)

# Get balance in Wei from RPC
BALANCE_WEI=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getBalance\",\"params\":[\"$VALIDATOR_ADDRESS\", \"latest\"],\"id\":1}" \
    $DESTINATION_CHAIN_RPC_URL | jq -r '.result')

BALANCE_DEC=$(printf "%d" $BALANCE_WEI)

BALANCE_ETH=$(echo "scale=18; $BALANCE_DEC / 10^18" | bc -l)

IS_GREATER=$(echo "$BALANCE_ETH > $BALANCE_THRESHOLD" | bc -l)

if [ "$IS_GREATER" -eq 1 ]; then
    echo "OK: balance is greater than $BALANCE_THRESHOLD ETH"
    exit 0
else
    echo "FAIL: balance is below $BALANCE_THRESHOLD ETH"
    exit 1
fi
