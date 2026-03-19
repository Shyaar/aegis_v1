import { defineChain } from 'viem'

export const unichainSepolia = defineChain({
  id: 1301,
  name: 'Unichain Sepolia',
  nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
  rpcUrls: { default: { http: ['https://sepolia.unichain.org'] } },
  blockExplorers: { default: { name: 'Uniscan', url: 'https://sepolia.uniscan.xyz' } },
  testnet: true,
})

export const AEGIS_CONTRACTS = {
  POLICY:         '0xC42c18EE275a172569D28809745Aa97F1A022b7F' as `0x${string}`,
  RESERVE:        '0x7Dd287eDeC07099F5EF1F1d2883150617DF74A2E' as `0x${string}`,
  HOOK:           '0x1b1e38436421512DE424B666F3aaC28c8c99e0C8' as `0x${string}`,
  ORACLE:         '0x0649F336C2350A6BDfEc655B06DD9BDC4b4b7b2d' as `0x${string}`,
  mUSDC:          '0xE55C5Ace3b0645AeAD6d685D29DFEC35245619Bc' as `0x${string}`,
  mWETH:          '0x83190Ed6aBa775d7910EF2f5F94845Ca79ccC29E' as `0x${string}`,
  POOL_SWAP_TEST: '0x9140a78c1A137c7fF1c151EC8231272aF78a99A4' as `0x${string}`,
} as const

// PoolKey for the Aegis pool (fixed at deployment)
// NOTE: mWETH < mUSDC by address, so currency0=mWETH, currency1=mUSDC
export const AEGIS_POOL_KEY = {
  currency0: '0x83190Ed6aBa775d7910EF2f5F94845Ca79ccC29E' as `0x${string}`, // mWETH (decimals=18)
  currency1: '0xE55C5Ace3b0645AeAD6d685D29DFEC35245619Bc' as `0x${string}`, // mUSDC (decimals=6)
  fee: 8388608, // DYNAMIC_FEE_FLAG
  tickSpacing: 60,
  hooks: '0x1b1e38436421512DE424B666F3aaC28c8c99e0C8' as `0x${string}`,
} as const

export const AEGIS_POLICY_ABI = [
  { type: "function", name: "BPS", inputs: [], outputs: [{ name: "", type: "uint256" }], stateMutability: "view" },
  { type: "function", name: "extraBps", inputs: [], outputs: [{ name: "", type: "uint16" }], stateMutability: "view" },
  { type: "function", name: "calculatePremium", inputs: [{ name: "params", type: "tuple", components: [
    { name: "swapSize", type: "uint256" },
    { name: "poolLiquidity", type: "uint128" },
    { name: "baseFee", type: "uint24" },
    { name: "volatilitySignal", type: "uint256" },
    { name: "tier", type: "uint8" }
  ]}], outputs: [{ name: "", type: "uint256" }], stateMutability: "view" },
  { type: "function", name: "calculateCompensation", inputs: [
    { name: "expectedOut", type: "uint256" },
    { name: "actualOut", type: "uint256" },
    { name: "tier", type: "uint8" }
  ], outputs: [{ name: "", type: "uint256" }], stateMutability: "pure" },
] as const

export const AEGIS_RESERVE_ABI = [
  { type: "function", name: "getReserveBalance", inputs: [{ name: "token", type: "address" }], outputs: [{ name: "", type: "uint256" }], stateMutability: "view" },
  { type: "function", name: "nextClaimId", inputs: [], outputs: [{ name: "", type: "uint256" }], stateMutability: "view" },
  { type: "function", name: "claims", inputs: [{ name: "", type: "uint256" }], outputs: [
    { name: "swapper", type: "address" },
    { name: "token", type: "address" },
    { name: "amount", type: "uint256" },
    { name: "settled", type: "bool" },
    { name: "timestamp", type: "uint256" }
  ], stateMutability: "view" },
  { type: "function", name: "settleClaim", inputs: [{ name: "claimId", type: "uint256" }], outputs: [], stateMutability: "nonpayable" },
  { type: "function", name: "depositPremium", inputs: [{ name: "token", type: "address" }, { name: "amount", type: "uint256" }], outputs: [], stateMutability: "nonpayable" },
  { type: "event", name: "ClaimRecorded", inputs: [
    { name: "claimId", type: "uint256", indexed: true },
    { name: "swapper", type: "address", indexed: false },
    { name: "amount", type: "uint256", indexed: false }
  ], anonymous: false },
  { type: "event", name: "ClaimSettled", inputs: [
    { name: "claimId", type: "uint256", indexed: true },
    { name: "swapper", type: "address", indexed: false },
    { name: "amount", type: "uint256", indexed: false }
  ], anonymous: false },
] as const

export const AEGIS_HOOK_ABI = [
  { type: "function", name: "activeQuotes", inputs: [{ name: "", type: "address" }], outputs: [
    { name: "sqrtPriceX96", type: "uint160" },
    { name: "tier", type: "uint8" },
    { name: "premium", type: "uint256" },
    { name: "zeroForOne", type: "bool" },
    { name: "fee", type: "uint24" }
  ], stateMutability: "view" },
  { type: "function", name: "movingAverageGasPrice", inputs: [], outputs: [{ name: "", type: "uint128" }], stateMutability: "view" },
  { type: "event", name: "ClaimPaid", inputs: [
    { name: "swapper", type: "address", indexed: true },
    { name: "compensation", type: "uint256", indexed: false }
  ], anonymous: false },
  { type: "event", name: "InsuranceQuoted", inputs: [
    { name: "swapper", type: "address", indexed: true },
    { name: "price", type: "uint160", indexed: false },
    { name: "tier", type: "uint8", indexed: false }
  ], anonymous: false },
  { type: "event", name: "SwapCovered", inputs: [
    { name: "swapper", type: "address", indexed: true },
    { name: "premium", type: "uint256", indexed: false },
    { name: "amount", type: "uint256", indexed: false }
  ], anonymous: false },
] as const

export const MOCK_ERC20_ABI = [
  { type: "function", name: "mint", inputs: [{ name: "to", type: "address" }, { name: "value", type: "uint256" }], outputs: [], stateMutability: "nonpayable" },
  { type: "function", name: "approve", inputs: [{ name: "spender", type: "address" }, { name: "amount", type: "uint256" }], outputs: [{ name: "", type: "bool" }], stateMutability: "nonpayable" },
  { type: "function", name: "balanceOf", inputs: [{ name: "", type: "address" }], outputs: [{ name: "", type: "uint256" }], stateMutability: "view" },
  { type: "function", name: "allowance", inputs: [{ name: "", type: "address" }, { name: "", type: "address" }], outputs: [{ name: "", type: "uint256" }], stateMutability: "view" },
  { type: "function", name: "decimals", inputs: [], outputs: [{ name: "", type: "uint8" }], stateMutability: "view" },
  { type: "function", name: "symbol", inputs: [], outputs: [{ name: "", type: "string" }], stateMutability: "view" },
] as const

export const POOL_SWAP_TEST_ABI = [
  {
    type: "function",
    name: "swap",
    inputs: [
      { name: "key", type: "tuple", components: [
        { name: "currency0", type: "address" },
        { name: "currency1", type: "address" },
        { name: "fee", type: "uint24" },
        { name: "tickSpacing", type: "int24" },
        { name: "hooks", type: "address" },
      ]},
      { name: "params", type: "tuple", components: [
        { name: "zeroForOne", type: "bool" },
        { name: "amountSpecified", type: "int256" },
        { name: "sqrtPriceLimitX96", type: "uint160" },
      ]},
      { name: "testSettings", type: "tuple", components: [
        { name: "takeClaims", type: "bool" },
        { name: "settleUsingBurn", type: "bool" },
      ]},
      { name: "hookData", type: "bytes" },
    ],
    outputs: [{ name: "delta", type: "int256" }],
    stateMutability: "payable",
  },
] as const
