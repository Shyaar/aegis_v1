# Aegis Protocol: Smart Insurance for Uniswap v4

Aegis Protocol is a decentralized insurance layer built as a Uniswap v4 Hook. It protects traders from high slippage and volatility by offering tiered coverage that automatically records compensation claims if price execution deviates beyond expected thresholds.

## Summary

In modern decentralized finance, traders often suffer from "hidden costs" due to slippage, toxic flow, and extreme volatility. Aegis provides a safety net by integrating insurance directly into the swap lifecycle. By selecting a coverage tier (Basic, Standard, or Full), swappers pay a small premium in exchange for guaranteed compensation if their actual output falls short of the fair market price recorded at the start of the transaction.

## The Problem

- **Execution Uncertainty**: High volatility or low liquidity leads to significant price impact (slippage), often exceeding a trader's risk tolerance.
- **Toxic Flow Protection**: Standard automated market makers (AMMs) don't distinguish between informed traders and retail users, often leaving the latter exposed to worse prices.
- **Manual Claims**: Traditional insurance models are slow, requiring manual filing and verification, which is incompatible with the speed of DeFi.

## The Solution

Aegis Protocol automates the entire insurance lifecycle using the **Uniswap v4 Hook** architecture:
1.  **Selection**: Users opt-in to insurance via the frontend during a swap.
2.  **Embedded Premiums**: A small dynamic premium is collected within the `beforeSwap` hook.
3.  **Automated Verification**: The `afterSwap` hook compares the execution price to the initial quote.
4.  **Instant Claims**: If slippage exceeds the tier threshold (e.g., >0.2% for Full Coverage), a compensation claim is automatically recorded in the Reserve.
5.  **Self-Custodial Settlement**: Users can settle their claims at any time through the Aegis Claims Dashboard.

## Implementation Details

The protocol consists of three primary components:

### 1. AegisHook (Smart Contract)
The core logic triggered during the Uniswap v4 swap lifecycle. It uses `beforeSwap` to record the initial `sqrtPriceX96` and `afterSwap` to calculate the price delta and trigger claims.

### 2. AegisPolicy (Policy Engine)
A modular contract that defines the mathematical logic for:
- **Dynamic Fees**: Adjusting swap fees based on volatility signals.
- **Premium Calculation**: Scaling costs based on swap size and risk tier.
- **Compensation Math**: Determining the exact amount of "deferred compensation" owed to a swapper.

### 3. AegisReserve (Treasury)
A dedicated vault that holds collected premiums and initial capital. It manages the lifecycle of claims, ensuring that compensations are funded and verifiable.

---

*Built with ❤️ for the Uniswap v4 Hookathon.*
