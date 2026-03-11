# AegisHook.sol Deep Dive

`AegisHook.sol` is the heart of the Aegis Protocol. It acts as the bridge between the Uniswap v4 PoolManager and our custom insurance/dynamic fee logic.

## 1. Governance & Permissions
The hook is designed to intervene at two critical moments: **Before a swap starts** and **After a swap completes**.

## 2. Imports & Dependencies

| Import | Why we need it |
| :--- | :--- |
| `BaseHook` | Provides the standard wrapper for Uniswap v4 hooks, handling basic setup and ownership. |
| `Hooks` | Contains the bit-flags for permanent hook permissions (beforeSwap, afterSwap, etc.). |
| `IPoolManager` | The core interface for Uniswap v4's central singleton manager. We need this to read pool state (slot0) and liquidity. |
| `PoolKey` | A struct that uniquely identifies a pool (tokens, fee, tickSpacing, hook address). |
| `BalanceDelta` | Represents the net change in token balances after an operation. |
| `BeforeSwapDelta` | Allows the hook to "modify" the swap amount before it hits the pool (not used here but required for interface). |
| `IAegisPolicy` | Our custom "Brain" interface for calculating premiums and fees. |
| `IAegisReserve` | Our custom "Vault" interface for recording claims and depositing premiums. |
| `StateLibrary` | An extension for `IPoolManager` that makes reading state (like `slot0`) more gas-efficient and readable. |

## 3. State Variables

- **`policy`**: Points to the `AegisPolicy` contract. We call this for all mathematical calculations to keep the hook light.
- **`reserve`**: Points to the `AegisReserve` contract where money is stored.
- **`activeQuotes`**: A mapping that stores the "Insurance Quote" generated in `beforeSwap` so we can compare it to the actual result in `afterSwap`.

## 4. Key Functions

### `getHookPermissions()`
- **Logic**: Returns a struct with `beforeSwap: true` and `afterSwap: true`.
- **Purpose**: Tells the `PoolManager` exactly which parts of the swap lifecycle this hook wants to control.

### `_beforeSwap()`
This is where the magic starts. It runs *before* the price moves.
1.  **Market Influx**: Monitors volatility.
2.  **Dynamic Fee**: Calls the policy to decide if the swap fee should be higher (high volatility) or lower.
3.  **Quote Generation**: Reads the current pool price (`sqrtPriceX96`) and asks the policy: "How much premium should this user pay for their chosen tier?"
4.  **Premium Collection**: Notifies the reserve that a premium is being deposited.
5.  **Override**: Returns the new `dynamicFee` to the pool manager.

### `_afterSwap()`
This runs *after* the tokens have moved.
1.  **Verification**: Compares the `actualOut` (from `delta`) with the price we recorded in `beforeSwap`.
2.  **Claim Trigger**: If the user got a bad fill (slippage breached), it tells the `reserve` to record a claim.
3.  **Cleanup**: Deletes the `activeQuote` to save gas and reset state for the next user.

---

> [!TIP]
> **Transient Storage**: In a production environment, `activeQuotes` would use `TSTORE` (EIP-1153) instead of a mapping to save massive amounts of gas, as the data only needs to exist for the duration of one transaction.
