import { http } from 'viem'
import { createConfig } from '@privy-io/wagmi'
import { unichainSepolia } from '@/lib/contracts'

export const config = createConfig({
  chains: [unichainSepolia],
  transports: {
    [unichainSepolia.id]: http('https://sepolia.unichain.org'),
  },
})
