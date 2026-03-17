import { useReadContract, useWriteContract, useWatchContractEvent } from 'wagmi';
import { 
  AEGIS_POLICY_ABI, 
  AEGIS_RESERVE_ABI, 
  AEGIS_HOOK_ABI, 
  AEGIS_CONTRACTS 
} from '@/lib/contracts';

// --- Policy Hooks ---

export function useAegisPremium(params: {
  swapSize: bigint;
  poolLiquidity: bigint;
  baseFee: number;
  volatilitySignal: bigint;
  tier: number;
}) {
  return useReadContract({
    abi: AEGIS_POLICY_ABI,
    address: AEGIS_CONTRACTS.POLICY as `0x${string}`,
    functionName: 'calculatePremium',
    args: [params],
  });
}

// --- Reserve Hooks ---

export function useAegisClaims(claimId: bigint) {
  return useReadContract({
    abi: AEGIS_RESERVE_ABI,
    address: AEGIS_CONTRACTS.RESERVE as `0x${string}`,
    functionName: 'claims',
    args: [claimId],
  });
}

export function useSettleClaim() {
  const { writeContract, data, error, isPending } = useWriteContract();

  const settle = (claimId: bigint) => {
    writeContract({
      abi: AEGIS_RESERVE_ABI,
      address: AEGIS_CONTRACTS.RESERVE as `0x${string}`,
      functionName: 'settleClaim',
      args: [claimId],
    });
  };

  return { settle, data, error, isPending };
}

// --- Hook State Hooks ---

export function useActiveQuote(address: `0x${string}`) {
  return useReadContract({
    abi: AEGIS_HOOK_ABI,
    address: AEGIS_CONTRACTS.HOOK as `0x${string}`,
    functionName: 'activeQuotes',
    args: [address],
  });
}
