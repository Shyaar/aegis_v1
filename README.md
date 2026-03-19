# Aegis Protocol

**On-chain slippage insurance for Uniswap v4, powered by the Reactive Network.**

---

## The Problem

Every swap on a decentralized exchange carries hidden execution risk. Slippage, toxic order flow, and sudden volatility can cause traders to receive significantly less than the quoted price — with no recourse. Existing solutions are either off-chain (requiring trust), manual (requiring the user to file a claim), or non-existent for retail traders.

The result: retail traders absorb losses silently, every single day.

---

## The Solution

Aegis embeds insurance directly into the swap lifecycle as a **Uniswap v4 Hook**. Before a swap executes, the user selects a coverage tier and pays a small premium. After the swap, the hook automatically compares the actual execution price to the quoted price. If slippage exceeds the tier threshold, a compensation claim is instantly recorded on-chain — no forms, no off-chain verification, no waiting.

The **Reactive Network** monitors claim events cross-chain and dynamically adjusts premiums in real time when volatility spikes, keeping the reserve solvent without any manual intervention.

**The result:** traders get guaranteed price protection at swap time, with atomic settlement and zero trust assumptions.

---

## How It Works

```
User selects tier → beforeSwap: premium pulled, quote recorded
                  → swap executes on Uniswap v4
                  → afterSwap: actual price vs quoted price compared
                  → if deviation > threshold: claim recorded in Reserve
                  → user settles claim from Claims Dashboard
```

The Reactive Network monitors `ClaimPaid` events on Unichain Sepolia and calls back into `AegisPolicy` to dynamically raise premiums during high-volatility periods — fully cross-chain, no keeper required.

---

## Coverage Tiers

| Tier     | Trigger Threshold | Premium |
|----------|-------------------|---------|
| None     | —                 | 0 bps   |
| Basic    | > 1% slippage     | 5 bps   |
| Standard | > 0.5% slippage   | 10 bps  |
| Premium  | > 0.2% slippage   | 20 bps  |

Premiums scale with swap size, pool liquidity, and a volatility signal from `AegisOracle`. During high-volatility periods, the Reactive Network automatically raises `extraBps` in `AegisPolicy`.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Unichain Sepolia                      │
│                                                         │
│  ┌──────────┐   beforeSwap   ┌─────────────────────┐   │
│  │  Swapper │ ─────────────► │     AegisHook        │   │
│  │          │ ◄───────────── │  (Uniswap v4 Hook)   │   │
│  └──────────┘   afterSwap    │                     │   │
│                              │  • Dynamic fees      │   │
│                              │  • Premium collection│   │
│                              │  • Claim recording   │   │
│                              └──────┬──────┬────────┘   │
│                                     │      │            │
│                              ┌──────▼──┐ ┌─▼──────────┐ │
│                              │ AegisPolicy│ │AegisReserve│ │
│                              │ (premiums) │ │ (treasury) │ │
│                              └──────┬──┘ └────────────┘ │
│                                     │                   │
│                              ┌──────▼──┐                │
│                              │AegisOracle│               │
│                              │(volatility│               │
│                              │  TWAP)   │               │
│                              └──────────┘               │
└─────────────────────────────────────────────────────────┘
                        │ ClaimPaid event
                        ▼
┌─────────────────────────────────────────────────────────┐
│                   Reactive Lasna                        │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │               AegisReactive                       │  │
│  │  • Listens for ClaimPaid on Unichain Sepolia      │  │
│  │  • Calls updateBasePremium() on AegisPolicy       │  │
│  │  • Resets premium after calm period               │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## Contracts

### Unichain Sepolia (Chain ID: 1301)

| Contract      | Address                                      |
|---------------|----------------------------------------------|
| AegisHook     | `0xDcdcBDe6Ec7209Ad97dB4CbE5e40C16127d820C8` |
| AegisPolicy   | `0x6C66b073Dd38079853a8CC240Fe5CBA3e12fae0f` |
| AegisReserve  | `0x50461BC04ef3B29DD1B38d1eD393abe711cde922` |
| AegisOracle   | `0xA9466873781f9957faa8CCf8C41D49060478FB71` |
| mUSDC (test)  | `0x16A1234F95E6cDeFAaE4d7ECd352AFE4B9946A35` |
| mWETH (test)  | `0x1dE340Ae93AC4896AC5feD63b73306325395f195` |
| PoolManager   | `0x00B036B58a818B1BC34d502D3fE730Db729e62AC` |
| PoolSwapTest  | `0x9140a78c1A137c7fF1c151EC8231272aF78a99A4` |

All contracts verified on [Uniscan](https://sepolia.uniscan.xyz).

### Reactive Lasna (Chain ID: 5318007)

| Contract       | Address                                      |
|----------------|----------------------------------------------|
| AegisReactive  | `0xfbc4D2075ae7889eabb3f3EFf3bC1a0B8Bb0C638` |

### Pool Configuration

```
currency0 = mUSDC  (0x16A1...A35, decimals=6)
currency1 = mWETH  (0x1dE3...195, decimals=18)
fee       = 8388608 (DYNAMIC_FEE_FLAG)
tickSpacing = 60
hooks     = AegisHook
sqrtPriceX96 = 1771595571142957166518320255467520  (1 mWETH = 2000 mUSDC)
liquidity = 44721359549996
```

---

## Contract Details

### AegisHook

The core Uniswap v4 Hook. Implements `beforeSwap` and `afterSwap`.

**`beforeSwap`**
1. Reads volatility signal from `AegisOracle`
2. Computes dynamic fee based on moving average gas price
3. Decodes `hookData` as `(uint8 tier, address sender)` — `sender` is the actual user wallet (not `PoolSwapTest`)
4. Records `SwapQuote` (sqrtPriceX96, tier, premium, direction)
5. Pulls premium via `transferFrom(sender, reserve, premium)`
6. Returns `ZERO_DELTA` + overridden dynamic fee

**`afterSwap`**
1. Reads recorded quote for swapper
2. Computes expected output from quote price vs actual output from `BalanceDelta`
3. Calls `AegisPolicy.calculateCompensation()` — returns non-zero only if deviation exceeds tier threshold
4. If compensation > 0: calls `AegisReserve.recordClaim()` and emits `ClaimPaid`
5. Updates moving average gas price

**Dynamic Fee Logic**
- Gas price > 10% above moving average → fee halved (attract swaps during congestion)
- Gas price < 10% below moving average → fee doubled (capture value in quiet blocks)
- Otherwise → `BASE_FEE = 3000` (0.3%)

### AegisPolicy

Stateless math + Reactive callback receiver.

- `calculatePremium(params)` — `swapSize * tierBps / 10000`, scaled by volatility signal
- `calculateCompensation(expectedOut, actualOut, tier)` — returns `deviation` if it exceeds tier threshold, else 0
- `calculateExactOutputCompensation(expectedIn, actualIn, tier)` — same for exact-output swaps
- `updateBasePremium(rvm, bps)` — called by Reactive Network to raise premiums; restricted to callback proxy
- `clearBasePremium(rvm)` — resets `extraBps` to 0

### AegisReserve

Treasury vault.

- Holds mUSDC and mWETH collected as premiums + initial capital
- `recordClaim(swapper, token, amount)` — stores claim struct, restricted to hook
- `settleClaim(claimId)` — transfers compensation to swapper, callable by anyone (claimant)
- `depositPremium(token, amount)` — called by hook after `transferFrom`

### AegisOracle

Lightweight TWAP tracker.

- `updateObservation(poolId, tick)` — called by hook on every swap
- `getVolatilitySignal(poolId)` — returns tick variance as volatility proxy

### AegisReactive

Deployed on Reactive Lasna. Subscribes to `ClaimPaid` events on Unichain Sepolia.

- On `ClaimPaid`: calls `AegisPolicy.updateBasePremium()` via cross-chain callback to raise premiums
- On `isPremiumRaised`: calls `clearBasePremium()` to reset after calm period

---

## Repository Structure

```
aegis_v1/
├── hook/
│   ├── src/
│   │   ├── AegisHook.sol
│   │   ├── AegisPolicy.sol
│   │   ├── AegisReserve.sol
│   │   ├── AegisOracle.sol
│   │   ├── AegisReactive.sol
│   │   ├── interfaces/
│   │   │   ├── IAegisPolicy.sol
│   │   │   ├── IAegisReserve.sol
│   │   │   └── IAegisOracle.sol
│   │   └── mocks/MockERC20.sol
│   ├── script/
│   │   ├── 01_DeploySepolia.s.sol   # Deploy all contracts to Unichain Sepolia
│   │   ├── 02_DeployReactive.s.sol  # Deploy AegisReactive to Reactive Lasna
│   │   ├── 03_AddLiquidity.s.sol    # Initialize pool + add liquidity
│   │   ├── DemoSwap.s.sol           # CLI demo swap
│   │   └── PoolState.s.sol          # Read pool state
│   └── test/
│       ├── AegisHookFlow.t.sol      # End-to-end swap + claim flow tests
│       └── AegisSlippage.t.sol      # Slippage invariant + compensation math tests
└── frontend/
    ├── src/
    │   ├── app/
    │   │   ├── page.tsx             # Root → redirects to /swap
    │   │   ├── swap/page.tsx        # Swap UI
    │   │   └── claims/page.tsx      # Claims dashboard
    │   ├── components/
    │   │   ├── swap/SwapCard.tsx    # Main swap widget
    │   │   ├── modals/FaucetModal.tsx
    │   │   └── claims/RecentTrades.tsx
    │   └── lib/
    │       ├── contracts.ts         # All addresses + ABIs
    │       ├── hooks/useAegis.ts    # All wagmi hooks
    │       └── wagmi.ts             # Chain config
    └── .env.local                   # NEXT_PUBLIC_PRIVY_APP_ID
```

---

## Running Locally

### Prerequisites

- [Foundry](https://getfoundry.sh/)
- Node.js 18+
- An RPC for Unichain Sepolia: `https://sepolia.unichain.org`

### Smart Contracts

```bash
cd hook
cp .env.example .env   # fill PRIVATE_KEY, API_KEY
forge test             # 41 tests should pass
```

### Deploy (fresh)

```bash
# 1. Deploy to Unichain Sepolia
forge clean
forge script script/01_DeploySepolia.s.sol \
  --rpc-url https://sepolia.unichain.org \
  --private-key $PRIVATE_KEY \
  --broadcast --verify

# 2. Add liquidity
MUSDC_ADDRESS=<addr> MWETH_ADDRESS=<addr> HOOK_ADDRESS=<addr> RESERVE_ADDRESS=<addr> \
forge script script/03_AddLiquidity.s.sol \
  --rpc-url https://sepolia.unichain.org \
  --private-key $PRIVATE_KEY --broadcast

# 3. Deploy Reactive contract
POLICY_ADDRESS=<addr> HOOK_ADDRESS=<addr> \
forge script script/02_DeployReactive.s.sol \
  --rpc-url https://lasna-rpc.rnk.dev/ \
  --private-key $PRIVATE_KEY --broadcast \
  --chain-id 5318007 --legacy --gas-price 500000000000

# 4. Subscribe
cast send <REACTIVE_ADDR> "subscribe()" \
  --private-key $PRIVATE_KEY \
  --rpc-url https://lasna-rpc.rnk.dev/ \
  --legacy --gas-price 500000000000
```

### Frontend

```bash
cd frontend
cp .env.local.example .env.local   # fill NEXT_PUBLIC_PRIVY_APP_ID
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

---

## Demo Flow

1. **Connect wallet** — Privy embedded wallet or MetaMask on Unichain Sepolia
2. **Get test tokens** — click "GET TEST TOKENS" → mint 10 mWETH + 1000 mUSDC
3. **Swap** — go to Swap, select a coverage tier (Basic / Standard / Premium), click "PROTECTED SWAP"
   - Approves mWETH to PoolSwapTest and AegisHook
   - Hook collects premium, records quote
   - Swap executes; if slippage > threshold, claim is recorded
4. **Claims** — go to Claims Dashboard, click "SETTLE NOW" to receive compensation

---

## Key Design Decisions

**Why `(uint8 tier, address sender)` in hookData?**
`PoolSwapTest` is the `msg.sender` to the hook, not the user. The hook needs the actual user address to pull premium via `transferFrom`. The frontend encodes both tier and wallet address into hookData.

**Why side-channel `transferFrom` instead of PoolManager accounting?**
Premium collection happens before the swap settles. Using `transferFrom` directly (outside PoolManager's flash accounting) avoids `CurrencyNotSettled` errors and keeps the hook's `BeforeSwapDelta` at zero.

**Why Reactive Network?**
The Reactive Network enables trustless cross-chain callbacks. When a `ClaimPaid` event fires on Unichain Sepolia, `AegisReactive` on Reactive Lasna automatically calls back into `AegisPolicy` to raise premiums — no keeper, no cron job, no multisig.

---

## Partner Integrations

### Uniswap v4
Aegis is built entirely on the Uniswap v4 Hook architecture. The `AegisHook` contract implements `beforeSwap` and `afterSwap` callbacks, giving it atomic access to the swap lifecycle — price before, execution after — without any external calls or off-chain coordination. The dynamic fee override (`DYNAMIC_FEE_FLAG` + `OVERRIDE_FEE_FLAG`) lets the hook adjust LP fees in real time based on network congestion, making Aegis pools more capital-efficient than standard v4 pools. LPs in an Aegis pool earn both swap fees and insurance premiums.

### Reactive Network
The Reactive Network enables trustless cross-chain automation without keepers or cron jobs. `AegisReactive` is deployed on Reactive Lasna and subscribes to `ClaimPaid` events emitted by `AegisHook` on Unichain Sepolia. When a claim fires — signalling a high-slippage event — the Reactive contract automatically calls back into `AegisPolicy` to raise `extraBps`, increasing premiums for subsequent swaps. Once conditions normalize, it resets premiums. This feedback loop keeps the reserve solvent during volatile periods with zero manual intervention and no trusted intermediary.

### Unichain Sepolia
Aegis is deployed on Unichain Sepolia, Uniswap's own L2 testnet. Unichain's fast block times and low fees make it ideal for a hook-based protocol where every swap triggers multiple contract calls (hook + reserve + oracle).

### Privy
The frontend uses Privy for wallet management. Privy's embedded wallets allow users without a browser extension to connect instantly via email or social login, lowering the barrier to entry for the demo. The `walletClient` from Privy's wagmi integration is used for both transaction signing and `wallet_watchAsset` calls to auto-add test tokens.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Smart Contracts | Solidity 0.8.30, Foundry, Uniswap v4 |
| Cross-chain | Reactive Network (Lasna) |
| Frontend | Next.js 16, Privy, wagmi, viem |
| Chain | Unichain Sepolia (Chain ID: 1301) |
| Wallet | Privy embedded wallets + injected |

---

*Built for the Uniswap v4 Hookathon.*
