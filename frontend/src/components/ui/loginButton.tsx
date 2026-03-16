import { useLogin, usePrivy } from '@privy-io/react-auth';

function LoginButton() {
    const { ready, authenticated} = usePrivy();
    const { login } = useLogin();
    
    const disableLogin = !ready || (ready && authenticated);

    return (
        <button  
            className="flex items-center gap-2 px-6 py-2.5 rounded-2xl accent-gradient hover:opacity-90 transition-all text-sm font-black text-white glow-accent"
            disabled={disableLogin} 
            onClick={login}
        >
            Connect Wallet
        </button>
    );
}

export default LoginButton;