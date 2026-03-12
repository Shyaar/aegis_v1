# Aegis Protocol: Flow and Logic

This document breaks down the end-to-end lifecycle of a swap protected by Aegis Protocol, detailing the interaction between the Uniswap v4 PoolManager and the Aegis suite.

## The Swap Lifecycle

### 1. Pre-Swap Assessment (`beforeSwap`)
When a swapper initiates a transaction through a pool with the Aegis Hook attached, the following occurs:

- **Signal Extraction**: The hook retrieves a "Volatility Signal" (simulated or fetched from an oracle) to assess market risk.
- **Dynamic Fee Adjustment**: The `AegisPolicy` calculates a dynamic swap fee based on the signal, potentially increasing it during high volatility to protect LPs.
- **Price Snapping**: The hook records the current `sqrtPriceX96` of the pool. This is used as the "fair value" reference for the insurance coverage.
- **Premium Collection**: Based on the user's selected `CoverageTier` (None, Basic, Standard, Full), a premium is calculated. If the tier is not "None", the premium is sent to the `AegisReserve`.
- **Quote Storage**: The swap parameters and price snap are stored to be verified in the next phase.

### 2. Execution Phase
Uniswap v4 executes the core swap logic, changing the pool's price and liquidity state based on the trader's input. This happens between the `beforeSwap` and `afterSwap` calls.

### 3. Post-Swap Verification (`afterSwap`)
Once the swap concludes, the hook analyzes the result:

- **Opt-Out Check**: If the user selected the "None" tier, the hook skips further checks and continues normally.
- **Expected vs. Actual**: The hook calculates the `expectedOut` (the amount the user should have received based on the pre-swap price) and compares it to the `actualOut` (the amount Uniswap actually delivered).
- **Insurance Trigger**: If the difference exceeds the threshold of the user's coverage tier:
  - **Basic (1%)**: Claims if slippage > 1%.
  - **Standard (0.5%)**: Claims if slippage > 0.5%.
  - **Full (0.2%)**: Claims if slippage > 0.2%.
- **Claim Recording**: If triggered, the hook calls `AegisReserve.recordClaim()`, creating a deferred compensation record for the swapper in the compensation currency.

### 4. Claim Settlement
Claims are not immediately sent to the user to maintain pool execution efficiency. Instead:
- Users visit the **Aegis Claims Dashboard**.
- They see a list of their recorded claims.
- They trigger `settleClaim(id)` on the `AegisReserve`.
- The Reserve verifies the claim state and transfers the compensation tokens directly to the user.

## Policy Math Logic

### Expected Output
For a swap with Aegis insurance, the expected output is calculated as:
- `zeroForOne`: `amountIn * (sqrtPriceX96 / 2^96)^2`
- `oneForZero`: `amountIn / (sqrtPriceX96 / 2^96)^2`

### Compensation
The compensation is:
`Max(0, ExpectedOut * (1 - Threshold) - ActualOut)`

Where `Threshold` is determined by the `CoverageTier` (skipped if "None").
