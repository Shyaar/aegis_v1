# Aegis Protocol Demo Video Script

**Target Length:** 2-3 minutes
**Tone:** Professional, engaging, technical but accessible.

## Scene 1: The Problem (0:00 - 0:30)
*Visuals:* Show the Aegis Landing Page with a sleek animation. Maybe cut to a generic DEX showing high slippage or a "price impact too high" warning.
*Audio:* "In decentralized finance, execution uncertainty is the silent killer of returns. Whether it's sudden volatility, low liquidity, or toxic flow... traders constantly face the risk of receiving far less than they bargained for. Standard Automated Market Makers don't offer a safety net. Until now."

## Scene 2: The Solution - Aegis Protocol (0:30 - 1:00)
*Visuals:* Show the Aegis 'Swap' interface. Highlight the "Coverage Tier" selector (None, Basic, Standard, Full).
*Audio:* "Meet Aegis Protocol. Built as a Uniswap v4 Hook, Aegis embeds transparent, on-chain insurance directly into the swap lifecycle. Traders can opt-in to tiered coverage. By paying a small premium, they guarantee their execution price. If slippage exceeds their chosen threshold, they are automatically compensated."

## Scene 3: How it Works Under the Hood (1:00 - 1:45)
*Visuals:* Show a diagram of the Hook interaction (from `FLOW_AND_LOGIC.md`) or quickly flash the `AegisHook.sol` code, specifically the `beforeSwap` and `afterSwap` functions.
*Audio:* "Aegis harnesses the power of Uniswap v4. In the `beforeSwap` hook, we snap the exact pool price and collect the premium into the Aegis Reserve. Uniswap executes the trade. Then, in the `afterSwap` hook, we rigorously compare the actual output to the expected output. If the slippage triggers the policy, a compensation claim is instantly recorded—no manual filing required."

## Scene 4: Claim Settlement and Conclusion (1:45 - 2:30)
*Visuals:* Navigate to the "Claims" dashboard. Show a recorded claim. Click "Settle Claim" and show the transaction success.
*Audio:* "The user experience is seamless. If a trade suffers bad execution, the user simply navigates to the Claims Dashboard and clicks 'Settle' to withdraw their compensation directly from the Reserve. Aegis Protocol bridges the gap between risk and DeFi, providing the peace of mind traders need in volatile markets. Thank you for watching."

## Preparation Checklist for the Recording:
- [ ] Ensure local node (Anvil) is running and seeded.
- [ ] Have the frontend running locally (`npm run dev`).
- [ ] Prepare a wallet with enough test tokens to demonstrate a swap and a claim.
- [ ] Have the `FLOW_AND_LOGIC.md` diagram ready to display.
