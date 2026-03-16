'use client';

import { PrivyProvider } from '@privy-io/react-auth';


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
        }
      }}
    >
      {children}
    </PrivyProvider>
  );
}