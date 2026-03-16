
export const AEGIS_POLICY_ABI = [
  {
    "type": "function",
    "name": "BPS",
    "inputs": [],
    "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "calculateCompensation",
    "inputs": [
      { "name": "expectedOut", "type": "uint256", "internalType": "uint256" },
      { "name": "actualOut", "type": "uint256", "internalType": "uint256" },
      { "name": "tier", "type": "uint8", "internalType": "enum IAegisPolicy.CoverageTier" }
    ],
    "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
    "stateMutability": "pure"
  },
  {
    "type": "function",
    "name": "calculateExactOutputCompensation",
    "inputs": [
      { "name": "expectedIn", "type": "uint256", "internalType": "uint256" },
      { "name": "actualIn", "type": "uint256", "internalType": "uint256" },
      { "name": "tier", "type": "uint8", "internalType": "enum IAegisPolicy.CoverageTier" }
    ],
    "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
    "stateMutability": "pure"
  },
  {
    "type": "function",
    "name": "calculatePremium",
    "inputs": [
      {
        "name": "params",
        "type": "tuple",
        "internalType": "struct IAegisPolicy.PolicyParams",
        "components": [
          { "name": "swapSize", "type": "uint256", "internalType": "uint256" },
          { "name": "poolLiquidity", "type": "uint128", "internalType": "uint128" },
          { "name": "baseFee", "type": "uint24", "internalType": "uint24" },
          { "name": "volatilitySignal", "type": "uint256", "internalType": "uint256" },
          { "name": "tier", "type": "uint8", "internalType": "enum IAegisPolicy.CoverageTier" }
        ]
      }
    ],
    "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
    "stateMutability": "pure"
  }
] as const;

export const AEGIS_RESERVE_ABI = [
  {
    "type": "function",
    "name": "claims",
    "inputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
    "outputs": [
      { "name": "swapper", "type": "address", "internalType": "address" },
      { "name": "token", "type": "address", "internalType": "address" },
      { "name": "amount", "type": "uint256", "internalType": "uint256" },
      { "name": "settled", "type": "bool", "internalType": "bool" },
      { "name": "timestamp", "type": "uint256", "internalType": "uint256" }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getReserveBalance",
    "inputs": [{ "name": "token", "type": "address", "internalType": "address" }],
    "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "nextClaimId",
    "inputs": [],
    "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "settleClaim",
    "inputs": [{ "name": "claimId", "type": "uint256", "internalType": "uint256" }],
    "outputs": [],
    "stateMutability": "nonpayable"
  }
] as const;

export const AEGIS_HOOK_ABI = [
  {
    "type": "function",
    "name": "activeQuotes",
    "inputs": [{ "name": "", "type": "address", "internalType": "address" }],
    "outputs": [
      { "name": "sqrtPriceX96", "type": "uint160", "internalType": "uint160" },
      { "name": "tier", "type": "uint8", "internalType": "enum IAegisPolicy.CoverageTier" },
      { "name": "premium", "type": "uint256", "internalType": "uint256" },
      { "name": "zeroForOne", "type": "bool", "internalType": "bool" },
      { "name": "fee", "type": "uint24", "internalType": "uint24" }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "movingAverageGasPrice",
    "inputs": [],
    "outputs": [{ "name": "", "type": "uint128", "internalType": "uint128" }],
    "stateMutability": "view"
  }
] as const;

export const AEGIS_ORACLE_ABI = [
  {
    "type": "function",
    "name": "getVolatilitySignal",
    "inputs": [{ "name": "id", "type": "bytes32", "internalType": "PoolId" }],
    "outputs": [{ "name": "volatilityBps", "type": "uint256", "internalType": "uint256" }],
    "stateMutability": "view"
  }
] as const;

// PLACEHOLDER ADDRESSES - Update after deployment
export const AEGIS_CONTRACTS = {
  POLICY: "0x0000000000000000000000000000000000000000",
  RESERVE: "0x0000000000000000000000000000000000000000",
  HOOK: "0x0000000000000000000000000000000000000000",
  ORACLE: "0x0000000000000000000000000000000000000000",
};
