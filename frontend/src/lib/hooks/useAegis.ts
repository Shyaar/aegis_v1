import { useReadContract, useWriteContract, useWatchContractEvent } from 'wagmi'
import {
  AEGIS_POLICY_ABI,
  AEGIS_RESERVE_ABI,
  AEGIS_HOOK_ABI,
  MOCK_ERC20_ABI,
  AEGIS_CONTRACTS,
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
  })
}

export function useExtraBps() {
  return useReadContract({
    abi: AEGIS_POLICY_ABI,
    address: AEGIS_CONTRACTS.POLICY,
    functionName: 'extraBps',
  })
}

// --- Reserve ---

export function useReserveBalance(token: `0x${string}`) {
  return useReadContract({
    abi: AEGIS_RESERVE_ABI,
    address: AEGIS_CONTRACTS.RESERVE,
    functionName: 'getReserveBalance',
    args: [token],
  })
}

export function useNextClaimId() {
  return useReadContract({
    abi: AEGIS_RESERVE_ABI,
    address: AEGIS_CONTRACTS.RESERVE,
    functionName: 'nextClaimId',
  })
}

export function useClaim(claimId: bigint) {
  return useReadContract({
    abi: AEGIS_RESERVE_ABI,
    address: AEGIS_CONTRACTS.RESERVE,
    functionName: 'claims',
    args: [claimId],
  })
}

export function useSettleClaim() {
  const { writeContract, data, error, isPending } = useWriteContract()
  const settle = (claimId: bigint) => writeContract({
    abi: AEGIS_RESERVE_ABI,
    address: AEGIS_CONTRACTS.RESERVE,
    functionName: 'settleClaim',
    args: [claimId],
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
  })
}

export function useMovingAverageGasPrice() {
  return useReadContract({
    abi: AEGIS_HOOK_ABI,
    address: AEGIS_CONTRACTS.HOOK,
    functionName: 'movingAverageGasPrice',
  })
}

export function useWatchClaimPaid(onClaim: (swapper: string, compensation: bigint) => void) {
  useWatchContractEvent({
    abi: AEGIS_HOOK_ABI,
    address: AEGIS_CONTRACTS.HOOK,
    eventName: 'ClaimPaid',
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
  })
}

export function useMintTokens() {
  const { writeContract, data, error, isPending } = useWriteContract()
  const mint = (token: `0x${string}`, to: `0x${string}`, amount: bigint) => writeContract({
    abi: MOCK_ERC20_ABI,
    address: token,
    functionName: 'mint',
    args: [to, amount],
  })
  return { mint, data, error, isPending }
}
