'use client';

import { PrivyProvider } from '@privy-io/react-auth';
import { WagmiProvider } from '@privy-io/wagmi';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { config } from '@/lib/wagmi';
import { Toaster } from 'react-hot-toast';
import { unichainSepolia } from '@/lib/contracts';

const queryClient = new QueryClient();

export default function Providers({ children }: { children: React.ReactNode }) {
  return (
    <PrivyProvider
      appId={process.env.NEXT_PUBLIC_PRIVY_APP_ID!}
      config={{
        loginMethods: ["wallet", "email", "google"],
        appearance: {
          logo: 'aegis_logo.svg',
          landingHeader: 'Welcome to Aegis',
          loginMessage: 'Get Started',
          theme: 'dark',
          accentColor: '#00f2ff',
          showWalletLoginFirst: true,
        },
        embeddedWallets: {
          ethereum: {
            createOnLogin: 'users-without-wallets'
          }
        },
        supportedChains: [unichainSepolia]
      }}
    >
      <QueryClientProvider client={queryClient}>
        <WagmiProvider config={config}>
          {children}
          <Toaster
            position="bottom-right"
            toastOptions={{
              className: '!bg-[#0A0A0A] !text-white !border !border-aegis-border !rounded-2xl !font-bold !text-sm',
              success: { iconTheme: { primary: '#00f2ff', secondary: '#000' } },
            }}
          />
        </WagmiProvider>
      </QueryClientProvider>
    </PrivyProvider>
  );
}