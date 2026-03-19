#!/usr/bin/env bash
set -e

# ─────────────────────────────────────────────────────────────
# Aegis Protocol — Script-Based Demo
# Uses cast for reads, forge script for swaps (PoolManager
# requires flash accounting — can't be done with cast alone)
# ─────────────────────────────────────────────────────────────

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../hook" && pwd)"
source "$HOOK_DIR/.env"

RPC="$SEPOLIA_RPC_URL"
PK="$PRIVATE_KEY"
TRADER=$(cast wallet address --private-key $PK)

mUSDC="0x28fc8245697Fb0a2B4B8e8836E7C02A76C823126"
mWETH="0x46527B7dF29d1B858F76e17BefA8dFe87606F182"
RESERVE="0x0d672Bd97e0Ee0B37544013E63db0F287A76f8E6"

sep() { echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║         AEGIS PROTOCOL — DEMO RUNNER         ║"
echo "╚══════════════════════════════════════════════╝"
echo "Trader : $TRADER"
echo "RPC    : $RPC"
echo ""

# ── helpers ──────────────────────────────────────────────────
usdc_balance() {
  cast call $mUSDC "balanceOf(address)(uint256)" $TRADER --rpc-url $RPC
}
next_claim_id() {
  cast call $RESERVE "nextClaimId()(uint256)" --rpc-url $RPC
}
get_claim() {
  cast call $RESERVE "claims(uint256)(address,address,uint256,bool,uint256)" $1 --rpc-url $RPC
}
reserve_balance() {
  cast call $RESERVE "getReserveBalance(address)(uint256)" $mUSDC --rpc-url $RPC
}

do_swap() {
  (cd "$HOOK_DIR" && SWAP_AMOUNT=$1 forge script script/DemoSwap.s.sol \
    --rpc-url $RPC \
    --private-key $PK \
    --broadcast \
    --via-ir \
    -q)
}

# ─────────────────────────────────────────────────────────────
# SCENARIO 1 — Small swap (0.01 mWETH)
# ─────────────────────────────────────────────────────────────
sep
echo "SCENARIO 1: Small swap — 0.01 mWETH, Premium coverage"
echo "Expected : slippage within 0.2% threshold, no claim"
sep

CLAIM_ID_BEFORE=$(next_claim_id)
USDC_BEFORE=$(usdc_balance)
echo "mUSDC balance before : $USDC_BEFORE"
echo "Next claim ID before : $CLAIM_ID_BEFORE"
echo ""
echo ">> Executing swap..."
do_swap 10000000000000000   # 0.01e18

CLAIM_ID_AFTER=$(next_claim_id)
USDC_AFTER=$(usdc_balance)
echo "mUSDC balance after  : $USDC_AFTER"
echo "Next claim ID after  : $CLAIM_ID_AFTER"

if [ "$CLAIM_ID_AFTER" -gt "$CLAIM_ID_BEFORE" ]; then
  echo "Claim triggered (ID: $CLAIM_ID_BEFORE):"
  get_claim $CLAIM_ID_BEFORE
else
  echo "No claim triggered - slippage was within threshold (as expected)"
fi

echo ""

# ─────────────────────────────────────────────────────────────
# SCENARIO 2 — Large swap (50 mWETH) to force slippage
# ─────────────────────────────────────────────────────────────
sep
echo "SCENARIO 2: Large swap — 50 mWETH, Premium coverage"
echo "Expected : slippage > 0.2%, claim triggered and settled"
sep

CLAIM_ID_BEFORE=$(next_claim_id)
USDC_BEFORE=$(usdc_balance)
echo "Reserve mUSDC balance: $(reserve_balance)"
echo "mUSDC balance before : $USDC_BEFORE"
echo "Next claim ID before : $CLAIM_ID_BEFORE"
echo ""
echo ">> Executing swap..."
do_swap 50000000000000000000  # 50e18

CLAIM_ID_AFTER=$(next_claim_id)
USDC_AFTER_SWAP=$(usdc_balance)
echo "mUSDC balance after swap : $USDC_AFTER_SWAP"
echo "Next claim ID after      : $CLAIM_ID_AFTER"

if [ "$CLAIM_ID_AFTER" -gt "$CLAIM_ID_BEFORE" ]; then
  CLAIM_ID=$CLAIM_ID_BEFORE
  echo ""
  echo ">> Claim recorded (ID: $CLAIM_ID):"
  get_claim $CLAIM_ID
  echo ""
  echo ">> Settling claim $CLAIM_ID..."
  cast send $RESERVE "settleClaim(uint256)" $CLAIM_ID \
    --rpc-url $RPC \
    --private-key $PK \
    --quiet

  USDC_AFTER_SETTLE=$(usdc_balance)
  echo "mUSDC balance after settle : $USDC_AFTER_SETTLE"
  echo ""
  echo ">> Claim state after settlement:"
  get_claim $CLAIM_ID
else
  echo "No claim triggered - pool may need more liquidity or swap size needs to be larger"
fi

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║              DEMO COMPLETE                   ║"
echo "╚══════════════════════════════════════════════╝"
