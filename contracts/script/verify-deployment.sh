#!/usr/bin/env bash
set -eo pipefail

RARI_RPC=${RARI_RPC:-https://rari.mainnet.on.espresso.network}
APE_RPC=${APE_RPC:-https://apechain.mainnet.on.espresso.network}

echo "=========================================="
echo "RPC Endpoints"
echo "=========================================="
echo "Rari: $RARI_RPC"
echo "Ape:  $APE_RPC"
echo ""

# Warp route: Rari -> Ape (same address on both chains)
RARI_TO_APE_TOKEN=0x3e08Ad7C3fD70D08CdD2a11247dae18Eb06434FD

# Warp route: Ape -> Rari (same address on both chains)
APE_TO_RARI_TOKEN=0x29b0a57Cb774f513653a90d3a185eb12D4AAc3ad

strip_suffix() {
    echo "$1" | awk '{print $1}'
}

decode_storage_string() {
    local contract=$1
    local slot=$2
    local rpc=$3

    local slot_hex=$(printf "0x%064x" $slot)
    local raw=$(cast storage $contract $slot --rpc-url $rpc 2>/dev/null)

    if [ -z "$raw" ] || [ "$raw" == "0x0000000000000000000000000000000000000000000000000000000000000000" ]; then
        echo "(empty)"
        return
    fi

    local val=$(cast to-dec $raw)
    local last_bit=$((val & 1))

    if [ $last_bit -eq 0 ]; then
        # Short string: value is length*2, data in same slot (right-padded)
        local len=$((val / 2))
        if [ $len -gt 0 ] && [ $len -lt 32 ]; then
            echo ${raw:2:$((len * 2))} | xxd -r -p 2>/dev/null
        else
            echo "(empty)"
        fi
    else
        # Long string: value is length*2+1, data at keccak256(slot)
        local len=$(((val - 1) / 2))
        local data_slot=$(cast keccak "$slot_hex")
        local result=""
        local slots_needed=$(( (len + 31) / 32 ))

        for ((i=0; i<slots_needed; i++)); do
            local current_slot=$(python3 -c "print(hex(int('$data_slot', 16) + $i))")
            local chunk=$(cast storage $contract $current_slot --rpc-url $rpc 2>/dev/null)
            result="${result}${chunk:2}"
        done

        echo "${result:0:$((len * 2))}" | xxd -r -p 2>/dev/null
    fi
}

print_hyp_native() {
    local addr=$1
    local rpc=$2
    local currency=$3

    echo "  VERSION: $(strip_suffix "$(cast call $addr 'VERSION()(uint256)' --rpc-url $rpc)")"
    echo "  destinationDomainId: $(strip_suffix "$(cast call $addr 'destinationDomainId()(uint32)' --rpc-url $rpc)")"

    local price=$(strip_suffix "$(cast call $addr 'nftSalePriceWei()(uint256)' --rpc-url $rpc)")
    echo "  nftSalePriceWei: $price ($(cast from-wei $price) $currency)"

    local start=$(strip_suffix "$(cast call $addr 'startSale()(uint256)' --rpc-url $rpc)")
    echo "  startSale: $start ($(date -d @$start 2>/dev/null || echo 'invalid'))"

    local end=$(strip_suffix "$(cast call $addr 'endSale()(uint256)' --rpc-url $rpc)")
    echo "  endSale: $end ($(date -d @$end 2>/dev/null || echo 'invalid'))"

    echo "  isSaleOpen: $(cast call $addr 'isSaleOpen()(bool)' --rpc-url $rpc)"
    echo "  owner: $(cast call $addr 'owner()(address)' --rpc-url $rpc)"
    echo "  mailbox: $(cast call $addr 'mailbox()(address)' --rpc-url $rpc)"
    local ism=$(cast call $addr 'interchainSecurityModule()(address)' --rpc-url $rpc)
    echo "  ISM: $ism"
    local relayer=$(cast call $ism 'trustedRelayer()(address)' --rpc-url $rpc 2>/dev/null || echo "(not trusted relayer ISM)")
    echo "  ISM.trustedRelayer: $relayer"
}

print_hyp_erc20() {
    local addr=$1
    local rpc=$2
    local currency=$3

    echo "  VERSION: $(strip_suffix "$(cast call $addr 'VERSION()(uint256)' --rpc-url $rpc)")"
    echo "  rariMarketplace (NFT): $(cast call $addr 'rariMarketplace()(address)' --rpc-url $rpc)"
    echo "  destinationDomainId: $(strip_suffix "$(cast call $addr 'destinationDomainId()(uint32)' --rpc-url $rpc)")"

    local hook=$(strip_suffix "$(cast call $addr 'hookPayment()(uint256)' --rpc-url $rpc)")
    echo "  hookPayment: $hook ($(cast from-wei $hook) $currency)"

    local treasury_raw=$(cast call $addr 'getTreasury()(address,address,uint256)' --rpc-url $rpc)
    local espresso=$(echo "$treasury_raw" | head -1)
    local partner=$(echo "$treasury_raw" | sed -n '2p')
    local pct=$(echo "$treasury_raw" | tail -1 | awk '{print $1}')
    echo "  treasury.espresso: $espresso ($((pct / 100))%)"
    echo "  treasury.partner: $partner ($((100 - pct / 100))%)"

    local bal=$(cast balance $addr --rpc-url $rpc)
    echo "  contract balance: $bal ($(cast from-wei $bal) $currency)"

    echo "  mailbox: $(cast call $addr 'mailbox()(address)' --rpc-url $rpc)"
    local ism=$(cast call $addr 'interchainSecurityModule()(address)' --rpc-url $rpc)
    echo "  ISM: $ism"
    local relayer=$(cast call $ism 'trustedRelayer()(address)' --rpc-url $rpc 2>/dev/null || echo "(not trusted relayer ISM)")
    echo "  ISM.trustedRelayer: $relayer"
}

print_nft() {
    local addr=$1
    local rpc=$2
    local currency=$3

    echo "  name: $(cast call $addr 'name()(string)' --rpc-url $rpc)"
    echo "  symbol: $(cast call $addr 'symbol()(string)' --rpc-url $rpc)"
    echo "  espHypErc20: $(cast call $addr 'espHypErc20()(address)' --rpc-url $rpc)"
    echo "  royaltyReceiver: $(cast call $addr 'royaltyReceiver()(address)' --rpc-url $rpc)"

    local fee=$(strip_suffix "$(cast call $addr 'royaltyFeeNumerator()(uint96)' --rpc-url $rpc)")
    echo "  royaltyFeeNumerator: $fee ($((fee / 100)).$((fee % 100))%)"

    local last=$(strip_suffix "$(cast call $addr 'lastTokenId()(uint256)' --rpc-url $rpc)")
    echo "  lastTokenId: $last"

    local price=$(strip_suffix "$(cast call $addr 'nftSalePriceWei()(uint256)' --rpc-url $rpc)")
    echo "  nftSalePriceWei: $price ($(cast from-wei $price) $currency)"

    local start=$(strip_suffix "$(cast call $addr 'startSale()(uint256)' --rpc-url $rpc)")
    echo "  startSale: $start ($(date -d @$start 2>/dev/null || echo 'invalid'))"

    local end=$(strip_suffix "$(cast call $addr 'endSale()(uint256)' --rpc-url $rpc)")
    echo "  endSale: $end ($(date -d @$end 2>/dev/null || echo 'invalid'))"

    echo "  isSaleOpen: $(cast call $addr 'isSaleOpen()(bool)' --rpc-url $rpc)"

    local treasury_raw=$(cast call $addr 'getTreasury()(address,address,uint256)' --rpc-url $rpc)
    local espresso=$(echo "$treasury_raw" | head -1)
    local partner=$(echo "$treasury_raw" | sed -n '2p')
    local pct=$(echo "$treasury_raw" | tail -1 | awk '{print $1}')
    echo "  treasury.espresso: $espresso ($((pct / 100))%)"
    echo "  treasury.partner: $partner ($((100 - pct / 100))%)"

    echo "  baseImageURI: $(decode_storage_string $addr 16 $rpc)"
    echo "  chainName: $(decode_storage_string $addr 17 $rpc)"

    if [ "$last" != "0" ]; then
        echo "  tokenURI(1): $(cast call $addr 'tokenURI(uint256)(string)' 1 --rpc-url $rpc 2>/dev/null || echo '(error)')"
    fi
}

echo "=========================================="
echo "WARP ROUTE: Rari -> Ape"
echo "Token: $RARI_TO_APE_TOKEN"
echo "=========================================="
echo ""
echo "EspHypNative on Rari: $RARI_TO_APE_TOKEN (pay ETH to mint NFT on Ape)"
print_hyp_native $RARI_TO_APE_TOKEN $RARI_RPC "ETH"

echo ""
echo "EspHypERC20 on Ape: $RARI_TO_APE_TOKEN"
print_hyp_erc20 $RARI_TO_APE_TOKEN $APE_RPC "APE"

APE_NFT=$(cast call $RARI_TO_APE_TOKEN "rariMarketplace()(address)" --rpc-url $APE_RPC)
echo ""
echo "EspNFT on Ape: $APE_NFT"
print_nft $APE_NFT $APE_RPC "APE"

echo ""
echo "=========================================="
echo "WARP ROUTE: Ape -> Rari"
echo "Token: $APE_TO_RARI_TOKEN"
echo "=========================================="
echo ""
echo "EspHypNative on Ape: $APE_TO_RARI_TOKEN (pay APE to mint NFT on Rari)"
print_hyp_native $APE_TO_RARI_TOKEN $APE_RPC "APE"

echo ""
echo "EspHypERC20 on Rari: $APE_TO_RARI_TOKEN"
print_hyp_erc20 $APE_TO_RARI_TOKEN $RARI_RPC "ETH"

RARI_NFT=$(cast call $APE_TO_RARI_TOKEN "rariMarketplace()(address)" --rpc-url $RARI_RPC)
echo ""
echo "EspNFT on Rari: $RARI_NFT"
print_nft $RARI_NFT $RARI_RPC "ETH"

echo ""
echo "=========================================="
echo "OPERATIONAL BALANCES"
echo "=========================================="
echo ""

# Relayer (from ISM)
RARI_ISM=$(cast call $RARI_TO_APE_TOKEN 'interchainSecurityModule()(address)' --rpc-url $RARI_RPC)
RELAYER=$(cast call $RARI_ISM 'trustedRelayer()(address)' --rpc-url $RARI_RPC 2>/dev/null || echo "")
if [ -n "$RELAYER" ] && [ "$RELAYER" != "" ]; then
    echo "Relayer: $RELAYER"
    echo "  Rari: $(cast from-wei $(cast balance $RELAYER --rpc-url $RARI_RPC)) ETH"
    echo "  Ape:  $(cast from-wei $(cast balance $RELAYER --rpc-url $APE_RPC)) APE"
fi

# Treasury (from EspHypERC20)
echo ""
treasury_raw=$(cast call $RARI_TO_APE_TOKEN 'getTreasury()(address,address,uint256)' --rpc-url $APE_RPC)
ESPRESSO_TREASURY=$(echo "$treasury_raw" | head -1)
PARTNER_TREASURY=$(echo "$treasury_raw" | sed -n '2p')

echo "Espresso Treasury: $ESPRESSO_TREASURY"
echo "  Rari: $(cast from-wei $(cast balance $ESPRESSO_TREASURY --rpc-url $RARI_RPC)) ETH"
echo "  Ape:  $(cast from-wei $(cast balance $ESPRESSO_TREASURY --rpc-url $APE_RPC)) APE"

echo ""
echo "Partner Treasury: $PARTNER_TREASURY"
echo "  Rari: $(cast from-wei $(cast balance $PARTNER_TREASURY --rpc-url $RARI_RPC)) ETH"
echo "  Ape:  $(cast from-wei $(cast balance $PARTNER_TREASURY --rpc-url $APE_RPC)) APE"

# IGP (from mailbox default hook)
echo ""
echo "=========================================="
echo "IGP CLAIMABLE FUNDS"
echo "=========================================="
echo ""

MAILBOX=$(cast call $RARI_TO_APE_TOKEN 'mailbox()(address)' --rpc-url $RARI_RPC)
RARI_IGP=$(cast call $MAILBOX 'defaultHook()(address)' --rpc-url $RARI_RPC)
APE_IGP=$(cast call $MAILBOX 'defaultHook()(address)' --rpc-url $APE_RPC)

echo "Rari IGP: $RARI_IGP"
echo "  claimable: $(cast from-wei $(cast balance $RARI_IGP --rpc-url $RARI_RPC)) ETH"
echo "  beneficiary: $(cast call $RARI_IGP 'beneficiary()(address)' --rpc-url $RARI_RPC)"

echo ""
echo "Ape IGP: $APE_IGP"
echo "  claimable: $(cast from-wei $(cast balance $APE_IGP --rpc-url $APE_RPC)) APE"
echo "  beneficiary: $(cast call $APE_IGP 'beneficiary()(address)' --rpc-url $APE_RPC)"

echo ""
echo "=========================================="
echo "VERIFICATION COMPLETE"
echo "=========================================="
