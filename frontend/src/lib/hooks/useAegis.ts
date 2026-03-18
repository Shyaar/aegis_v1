import { useReadContract, useWriteContract, useWatchContractEvent, usePublicClient } from 'wagmi'
import { encodeAbiParameters, parseAbiParameters } from 'viem'
import {
  AEGIS_POLICY_ABI,
  AEGIS_RESERVE_ABI,
  AEGIS_HOOK_ABI,
  MOCK_ERC20_ABI,
  POOL_SWAP_TEST_ABI,
  AEGIS_CONTRACTS,
  AEGIS_POOL_KEY,
  unichainSepolia,
} from '@/lib/contracts'

// --- Policy ---

export function useAegisPremium(params: {
  swapSize: bigint
  poolLiquidity: bigint
  baseFee: number
  volatilitySignal: bigint
  tier: number
}) {
  return useReadContract({
    abi: AEGIS_POLICY_ABI,
    address: AEGIS_CONTRACTS.POLICY,
    functionName: 'calculatePremium',
    args: [params],
    chainId: unichainSepolia.id,
  })
}

export function useExtraBps() {
  return useReadContract({
    abi: AEGIS_POLICY_ABI,
    address: AEGIS_CONTRACTS.POLICY,
    functionName: 'extraBps',
    chainId: unichainSepolia.id,
  })
}

// --- Reserve ---

export function useReserveBalance(token: `0x${string}`) {
  return useReadContract({
    abi: AEGIS_RESERVE_ABI,
    address: AEGIS_CONTRACTS.RESERVE,
    functionName: 'getReserveBalance',
    args: [token],
    chainId: unichainSepolia.id,
  })
}

export function useNextClaimId() {
  return useReadContract({
    abi: AEGIS_RESERVE_ABI,
    address: AEGIS_CONTRACTS.RESERVE,
    functionName: 'nextClaimId',
    chainId: unichainSepolia.id,
  })
}

export function useClaim(claimId: bigint) {
  return useReadContract({
    abi: AEGIS_RESERVE_ABI,
    address: AEGIS_CONTRACTS.RESERVE,
    functionName: 'claims',
    args: [claimId],
    chainId: unichainSepolia.id,
  })
}

export function useSettleClaim() {
  const { writeContractAsync, data, error, isPending } = useWriteContract()
  const settle = async (claimId: bigint) => writeContractAsync({
    abi: AEGIS_RESERVE_ABI,
    address: AEGIS_CONTRACTS.RESERVE,
    functionName: 'settleClaim',
    args: [claimId],
    chainId: unichainSepolia.id,
  })
  return { settle, data, error, isPending }
}

// --- Hook ---

export function useActiveQuote(address: `0x${string}`) {
  return useReadContract({
    abi: AEGIS_HOOK_ABI,
    address: AEGIS_CONTRACTS.HOOK,
    functionName: 'activeQuotes',
    args: [address],
    chainId: unichainSepolia.id,
  })
}

export function useMovingAverageGasPrice() {
  return useReadContract({
    abi: AEGIS_HOOK_ABI,
    address: AEGIS_CONTRACTS.HOOK,
    functionName: 'movingAverageGasPrice',
    chainId: unichainSepolia.id,
  })
}

export function useWatchClaimPaid(onClaim: (swapper: string, compensation: bigint) => void) {
  useWatchContractEvent({
    abi: AEGIS_HOOK_ABI,
    address: AEGIS_CONTRACTS.HOOK,
    eventName: 'ClaimPaid',
    chainId: unichainSepolia.id,
    onLogs(logs) {
      for (const log of logs) {
        const { swapper, compensation } = log.args as { swapper: string; compensation: bigint }
        onClaim(swapper, compensation)
      }
    },
  })
}

// --- Tokens ---

export function useTokenBalance(token: `0x${string}`, account: `0x${string}` | undefined) {
  return useReadContract({
    abi: MOCK_ERC20_ABI,
    address: token,
    functionName: 'balanceOf',
    args: account ? [account] : undefined,
    query: { enabled: !!account },
    chainId: unichainSepolia.id,
  })
}

export function useMintTokens() {
  const { writeContractAsync, data, error, isPending } = useWriteContract()
  const mint = async (token: `0x${string}`, to: `0x${string}`, amount: bigint) => writeContractAsync({
    abi: MOCK_ERC20_ABI,
    address: token,
    functionName: 'mint',
    args: [to, amount],
    chainId: unichainSepolia.id,
  })
  return { mint, data, error, isPending }
}

// --- Swap ---

// MIN_SQRT_PRICE + 1 and MAX_SQRT_PRICE - 1 (Uniswap v4 price limits)
const MIN_SQRT_PRICE = BigInt("4295128740")
const MAX_SQRT_PRICE = BigInt("1461446703485210103287273052203988822378723970341")

export function useApproveToken() {
  const { writeContractAsync, isPending } = useWriteContract()
  const approve = (token: `0x${string}`, spender: `0x${string}`, amount: bigint) =>
    writeContractAsync({
      abi: MOCK_ERC20_ABI,
      address: token,
      functionName: 'approve',
      args: [spender, amount],
      chainId: unichainSepolia.id,
    })
  return { approve, isPending }
}

export function useProtectedSwap() {
  const { writeContractAsync, data, error, isPending } = useWriteContract()

  // zeroForOne = true  → selling mUSDC (currency0) for mWETH (currency1)
  // zeroForOne = false → selling mWETH (currency1) for mUSDC (currency0)
  const swap = (amountSpecified: bigint, zeroForOne: boolean, tier: number) =>
    writeContractAsync({
      abi: POOL_SWAP_TEST_ABI,
      address: AEGIS_CONTRACTS.POOL_SWAP_TEST,
      functionName: 'swap',
      args: [
        AEGIS_POOL_KEY,
        {
          zeroForOne,
          amountSpecified: -amountSpecified, // negative = exact-input
          sqrtPriceLimitX96: zeroForOne ? MIN_SQRT_PRICE : MAX_SQRT_PRICE,
        },
        { takeClaims: false, settleUsingBurn: false },
        encodeAbiParameters(parseAbiParameters('uint8'), [tier]), // CoverageTier enum as uint8
      ],
      chainId: unichainSepolia.id,
    })

  return { swap, data, error, isPending }
}
