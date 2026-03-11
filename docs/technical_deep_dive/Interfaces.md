# Aegis Interfaces Deep Dive

Interfaces are the "blueprints" of a smart contract. In Aegis, we use them to ensure modularity and future-proofing.

## 1. Why use Interfaces?
Interfaces allow different parts of the protocol to talk to each other without needing to know exactly how the other part is implemented.
- **Example**: `AegisHook` knows it can call `policy.calculatePremium()`, but it doesn't care *how* the premium is calculated. This allows us to upgrade the math (Policy) without ever touching the core Hook.

## 2. IAegisPolicy.sol
- **`CoverageTier`**: Ensures that the Hook and the Policy are always using the same three options (Basic, Standard, Full).
- **`PolicyParams`**: A standardized way to pass data. If we add a new parameter (like `gasPrice`) in the future, we only update this struct in one place.

## 3. IAegisReserve.sol
- **`recordClaim`**: Standardizes the way a claim is created. This ensures that any version of the `Reserve` (e.g., a multi-chain version) will always accept the same claim request from the `Hook`.
- **`settleClaim`**: Standardizes the user interaction for claiming money, allowing our frontend to work with any Aegis reserve.

---

## 4. Summary of Architecture
By using interfaces, the Aegis Protocol becomes a "Lego" set. You can:
1.  Swap the **Reserve** with a version that stakes tokens in Aave for extra yield.
2.  Swap the **Policy** with an AI-driven pricing model.
3.  **Keep the Hook exactly the same.**

This is how we build long-lasting, upgradeable DeFi protocols.
