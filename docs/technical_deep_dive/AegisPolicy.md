# AegisPolicy.sol Deep Dive

`AegisPolicy.sol` is the actuarial engine of the protocol. It is stateless (no variables like balance or ownership) which makes it gas-efficient and easy to audit.

## 1. Goal
To provide mathematically sound pricing for both insurance premiums and swap fees based on real-time market volatility.

## 2. Shared Types (from `IAegisPolicy.sol`)

- **`CoverageTier`**: An enum (Basic, Standard, Full) that defines how aggressive the insurance is.
- **`PolicyParams`**: A struct that wraps all inputs needed for the math (Size, Liquidity, Fee, Volatility). Wrapping these in a struct avoids "Stack Too Deep" errors in Solidity.

## 3. Key Functions

### `calculatePremium()`
Determines how many tokens a user must pay for protection.
- **Base Rate**: Sets a baseline cost (e.g., 0.05% for Basic).
- **Volatility Surcharge**: If the `volatilitySignal` is high, it adds a 50% surcharge. This protects the protocol during market crashes.
- **Math**: `(Size * Bps) / 10000`.

### `calculateDynamicFee()`
Decides the pool's swap fee for LPs.
- **Logic**: 
    - If volatility is > 5%, it sets the fee to 0.3%. 
    - If volatility is < 0.5%, it sets the fee to a tiny 0.01% to attract volume.
- **Impact**: It helps LPs earn more when the risk of Impermanent Loss is high.

### `calculateCompensation()`
Decides if the protocol owes the user money after a swap.
- **Thresholds**: 
    - Basic: 1.0% deviation.
    - Standard: 0.5% deviation.
    - Full: 0.2% deviation.
- **Logic**: If `actualOut` is worse than `expectedOut` by more than the threshold, the protocol pays for the *entire* deviation.

---

## 4. Why We Need It
By separating this logic from the `AegisHook`, we can:
1.  **Iterate Faster**: We can deploy a new `AegisPolicyV2` with better math and simply update the pointer in the hook.
2.  **Save Gas**: The hook doesn't have to carry the code-weight of these calculations.
3.  **Auditing**: Security researchers can verify the math in isolation without worrying about pool-manager state.
