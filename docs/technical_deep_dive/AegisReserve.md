# AegisReserve.sol Deep Dive

`AegisReserve.sol` is the protocol's treasury. It handles the financial state and the "Deferred Payout" (IOU) mechanism.

## 1. Goal
To safely store insurance premiums, manage protocol funds, and ensure that users can collect their compensation even if the reserve is temporarily low.

## 2. Shared Types (from `IAegisReserve.sol`)

- **`Claim`**: A struct that records who is owed, how much, whether it's been paid (`settled`), and when the event happened.

## 3. State Variables e& Why We Need Them

- **`claims`**: A mapping of `claimId` to the `Claim` struct. This acts as the "ledger" for all insurance IOUs.
- **`nextClaimId`**: A simple counter to ensure every claim gets a unique ID.
- **`totalReserve`**: The balance of tokens available to pay out claims right now.
- **`hook`**: The address of the `AegisHook`. We restrict critical functions (like recording claims) to *only* be callable by the hook for security.

## 4. Key Functions

### `recordClaim()`
- **When it's called**: In `afterSwap` if a user's slippage is too high.
- **Why we need it**: Instead of forcing a payout immediately (which might fail if the reserve is empty), we record the debt. This prevents the user's primary swap from reverting.
- **Access Control**: Protected by `onlyHook`.

### `depositPremium()`
- **When it's called**: In `beforeSwap`.
- **Why we need it**: It moves the insurance premium from the swapper into the treasury.
- **Math**: `totalReserve += amount`.

### `settleClaim()`
- **When it's called**: Manually by the user (or a bot) after the reserve has been replenished.
- **Why we need it**: It allows the user to actually receive their compensation tokens.
- **Logic**: It verifies the claim exists, marks it as `settled`, and deducts the amount from the `totalReserve`.

---

## 5. Security & Ownership
- **`Ownable`**: Inherits from OpenZeppelin's `Ownable`. This allows an admin (or eventually a DAO) to update the `hook` address or manage emergency parameters.
- **`onlyHook` Modifier**: A critical security guard to ensure that random users cannot "invent" fake claims for themselves.
