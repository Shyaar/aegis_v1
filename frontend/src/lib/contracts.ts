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
  POLICY:  '0xD8a6735b847CAe677A355cb61FFB4932A4eD4B3c' as `0x${string}`,
  RESERVE: '0x594c9194A98F51747b17ee7a7B0CEBB5A77A6b1d' as `0x${string}`,
  HOOK:    '0x4F25B3a510158A8C1917087E0679A82D473620C8' as `0x${string}`,
  ORACLE:  '0x463426aF713Ddafe7Fd142859C0F1Ec8d7888833' as `0x${string}`,
  mUSDC:   '0x25dfb92B22c873518e28a26B0FEbF681b7f99872' as `0x${string}`,
  mWETH:   '0xfcAEDD04AcD307405d2E1Ff40fC89948701421a0' as `0x${string}`,
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
] as const

export const MOCK_ERC20_ABI = [
  { type: "function", name: "mint", inputs: [{ name: "to", type: "address" }, { name: "value", type: "uint256" }], outputs: [], stateMutability: "nonpayable" },
  { type: "function", name: "approve", inputs: [{ name: "spender", type: "address" }, { name: "amount", type: "uint256" }], outputs: [{ name: "", type: "bool" }], stateMutability: "nonpayable" },
  { type: "function", name: "balanceOf", inputs: [{ name: "", type: "address" }], outputs: [{ name: "", type: "uint256" }], stateMutability: "view" },
  { type: "function", name: "allowance", inputs: [{ name: "", type: "address" }, { name: "", type: "address" }], outputs: [{ name: "", type: "uint256" }], stateMutability: "view" },
  { type: "function", name: "decimals", inputs: [], outputs: [{ name: "", type: "uint8" }], stateMutability: "view" },
  { type: "function", name: "symbol", inputs: [], outputs: [{ name: "", type: "string" }], stateMutability: "view" },
] as const
