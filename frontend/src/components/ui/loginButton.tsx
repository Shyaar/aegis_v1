import { useLogin, usePrivy } from '@privy-io/react-auth';
import toast from 'react-hot-toast';

function LoginButton() {
    const { ready, authenticated, user, logout } = usePrivy();
    const { login } = useLogin({
        onComplete: ({ wasAlreadyAuthenticated }) => {
            if (!wasAlreadyAuthenticated) {
                toast.success('Wallet connected successfully!', { icon: '🔗' });
            }
        }
    });

    const disableLogin = !ready || (ready && authenticated);

    const shortenAddress = (address?: string) => {
        if (!address) return '';
        return `${address.slice(0, 6)}...${address.slice(-4)}`;
    };

    const walletAddress = user?.wallet?.address;

    return (
        <button
            className="flex items-center gap-2 px-6 py-2.5 rounded-2xl accent-gradient hover:opacity-90 transition-all text-sm font-black text-white glow-accent"
            disabled={!ready}
            onClick={authenticated ? logout : login}
        >
            {authenticated && walletAddress
                ? shortenAddress(walletAddress)
                : "Connect Wallet"}
        </button>
    );
}

export default LoginButton;