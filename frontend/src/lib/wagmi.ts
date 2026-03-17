import { http } from 'viem';
import { sepolia, mainnet } from 'viem/chains';
import { createConfig } from '@privy-io/wagmi';

export const config = createConfig({
  chains: [sepolia, mainnet],
  transports: {
    [sepolia.id]: http(),
    [mainnet.id]: http(),
  },
});
