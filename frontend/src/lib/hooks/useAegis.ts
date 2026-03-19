import { useReadContract, useWriteContract, useWatchContractEvent, usePublicClient, useWalletClient } from 'wagmi'
import { encodeAbiParameters, parseAbiParameters } from 'viem'
import { useState, useEffect } from 'react'
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
  const client = usePublicClient()
  const { data: walletClient } = useWalletClient()
  const settle = async (claimId: bigint) => {
    const nonce = await freshNonce(client, walletClient)
    return writeContractAsync({
      abi: AEGIS_RESERVE_ABI,
      address: AEGIS_CONTRACTS.RESERVE,
      functionName: 'settleClaim',
      args: [claimId],
      chain: unichainSepolia,
      nonce,
    })
  }
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

export function useRecentTrades() {
  const client = usePublicClient()
  const [trades, setTrades] = useState<Array<{
    txHash: string
    amount: bigint
    premium: bigint
    blockNumber: bigint
    timestamp: number
  }>>([])

  useEffect(() => {
    if (!client) return
    client.getLogs({
      address: AEGIS_CONTRACTS.HOOK,
      event: {
        type: 'event',
        name: 'SwapCovered',
        inputs: [
          { name: 'swapper', type: 'address', indexed: true },
          { name: 'premium', type: 'uint256', indexed: false },
          { name: 'amount', type: 'uint256', indexed: false },
        ],
      },
      fromBlock: -2000n,
      toBlock: 'latest',
    }).then(async (logs) => {
      const withTimestamps = await Promise.all(
        logs.slice(-20).reverse().map(async (log) => {
          const block = await client.getBlock({ blockNumber: log.blockNumber! })
          return {
            txHash: log.transactionHash!,
            amount: (log.args as any).amount as bigint,
            premium: (log.args as any).premium as bigint,
            blockNumber: log.blockNumber!,
            timestamp: Number(block.timestamp),
          }
        })
      )
      setTrades(withTimestamps)
    }).catch(() => {})
  }, [client])

  useWatchContractEvent({
    abi: AEGIS_HOOK_ABI,
    address: AEGIS_CONTRACTS.HOOK,
    eventName: 'SwapCovered',
    chainId: unichainSepolia.id,
    onLogs(logs) {
      const newTrades = logs.map((log) => ({
        txHash: log.transactionHash!,
        amount: (log.args as any).amount as bigint,
        premium: (log.args as any).premium as bigint,
        blockNumber: log.blockNumber!,
        timestamp: Math.floor(Date.now() / 1000),
      }))
      setTrades(prev => [...newTrades, ...prev].slice(0, 20))
    },
  })

  return trades
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
  const client = usePublicClient()
  const { data: walletClient } = useWalletClient()
  const mint = async (token: `0x${string}`, to: `0x${string}`, amount: bigint) => {
    const nonce = await freshNonce(client, walletClient)
    return writeContractAsync({
      abi: MOCK_ERC20_ABI,
      address: token,
      functionName: 'mint',
      args: [to, amount],
      chain: unichainSepolia,
      nonce,
    })
  }
  return { mint, data, error, isPending }
}

// --- Swap ---

// MIN_SQRT_PRICE + 1 and MAX_SQRT_PRICE - 1 (Uniswap v4 price limits)
const MIN_SQRT_PRICE = BigInt("4295128740")
const MAX_SQRT_PRICE = BigInt("1461446703485210103287273052203988822378723970341")

async function freshNonce(
  client: ReturnType<typeof usePublicClient>,
  walletClient: { account?: { address?: `0x${string}` } } | null | undefined
) {
  const address = walletClient?.account?.address
  if (!address || !client) return undefined
  return client.getTransactionCount({ address, blockTag: 'pending' })
}

export function useApproveToken() {
  const { writeContractAsync, isPending } = useWriteContract()
  const client = usePublicClient()
  const { data: walletClient } = useWalletClient()
  const approve = async (token: `0x${string}`, spender: `0x${string}`, amount: bigint) => {
    const nonce = await freshNonce(client, walletClient)
    return writeContractAsync({
      abi: MOCK_ERC20_ABI,
      address: token,
      functionName: 'approve',
      args: [spender, amount],
      chain: unichainSepolia,
      nonce,
    })
  }
  return { approve, isPending }
}

export function useProtectedSwap() {
  const { writeContractAsync, data, error, isPending } = useWriteContract()
  const client = usePublicClient()
  const { data: walletClient } = useWalletClient()

  // currency0=mWETH, currency1=mUSDC
  // zeroForOne=true  → selling mWETH (currency0) for mUSDC (currency1)
  // zeroForOne=false → selling mUSDC (currency1) for mWETH (currency0)
  const swap = async (amountSpecified: bigint, zeroForOne: boolean, tier: number) => {
    const nonce = await freshNonce(client, walletClient)
    return writeContractAsync({
      abi: POOL_SWAP_TEST_ABI,
      address: AEGIS_CONTRACTS.POOL_SWAP_TEST,
      functionName: 'swap',
      args: [
        AEGIS_POOL_KEY,
        {
          zeroForOne,
          amountSpecified: -amountSpecified,
          sqrtPriceLimitX96: zeroForOne ? MIN_SQRT_PRICE : MAX_SQRT_PRICE,
        },
        { takeClaims: false, settleUsingBurn: false },
        encodeAbiParameters(parseAbiParameters('uint8, address'), [tier, walletClient?.account?.address ?? '0x0000000000000000000000000000000000000000']),
      ],
      chain: unichainSepolia,
      nonce,
    })
  }

  return { swap, data, error, isPending }
}
