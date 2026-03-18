"use client"

import Modal from "../ui/Modal"
import { Zap, Wallet, Copy, CheckCircle2 } from "lucide-react"
import { useState } from "react"
import { usePrivy } from "@privy-io/react-auth"
import { parseUnits } from "viem"
import { useMintTokens } from "@/lib/hooks/useAegis"
import { AEGIS_CONTRACTS } from "@/lib/contracts"
import toast from "react-hot-toast"

interface FaucetModalProps {
  isOpen: boolean
  onClose: () => void
}

export default function FaucetModal({ isOpen, onClose }: FaucetModalProps) {
  const { user } = usePrivy()
  const address = user?.wallet?.address as `0x${string}` | undefined
  const { mint, isPending } = useMintTokens()
  const [copiedAddress, setCopiedAddress] = useState<string | null>(null)
  const [done, setDone] = useState(false)

  const handleMint = async () => {
    if (!address) return
    const toastId = toast.loading("Minting test tokens...");
    try {
      // mint 10 mWETH and 1000 mUSDC
      await mint(AEGIS_CONTRACTS.mWETH, address, parseUnits("10", 18))
      await mint(AEGIS_CONTRACTS.mUSDC, address, parseUnits("1000", 6))

      // prompt wallet to track tokens
      if (window.ethereum) {
        for (const [addr, symbol, decimals] of [
          [AEGIS_CONTRACTS.mWETH, 'mWETH', 18],
          [AEGIS_CONTRACTS.mUSDC, 'mUSDC', 6],
        ] as const) {
          await window.ethereum.request({
            method: 'wallet_watchAsset',
            params: { type: 'ERC20', options: { address: addr, symbol, decimals } },
          }).catch(() => {})
        }
      }
      setDone(true)
      toast.success("Tokens successfully minted!", { id: toastId })
    } catch (error: any) {
      console.error("Failed to mint tokens:", error)
      toast.error(error?.shortMessage || error?.message || "Failed to mint tokens", { id: toastId })
    }
  }

  const copy = (text: string, key: string) => {
    navigator.clipboard.writeText(text)
    setCopiedAddress(key)
    toast.success(`${key} address copied!`, { icon: '📋' })
    setTimeout(() => setCopiedAddress(null), 2000)
  }

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Get Test Tokens">
      <div className="space-y-6">
        <div className="flex flex-col items-center text-center p-6 bg-aegis-accent/5 rounded-[32px] border border-aegis-accent/20">
          <div className="w-16 h-16 rounded-2xl bg-aegis-accent/20 flex items-center justify-center text-aegis-accent mb-4">
            <Zap className="w-8 h-8 fill-current" />
          </div>
          <div className="text-2xl font-black mb-1">10 mWETH & 1000 mUSDC</div>
          <div className="text-[10px] font-black uppercase text-aegis-accent tracking-widest">Received per request</div>
        </div>

        <div className="p-5 bg-white/5 rounded-3xl border border-aegis-border/30 flex gap-4 items-start">
          <Wallet className="w-6 h-6 text-blue-400 shrink-0 mt-1" />
          <p className="text-[10px] text-aegis-text-dim leading-relaxed tracking-wide">
            Tokens are minted on Unichain Sepolia. Add them manually if they don't appear automatically.
          </p>
        </div>

        <div className="space-y-3">
          {([['mWETH', AEGIS_CONTRACTS.mWETH], ['mUSDC', AEGIS_CONTRACTS.mUSDC]] as const).map(([label, addr]) => (
            <div key={label} className="flex justify-between items-center px-4 py-3 rounded-2xl bg-white/5 border border-aegis-border">
              <div className="flex flex-col">
                <span className="text-[10px] font-black text-aegis-text-dim uppercase">{label}</span>
                <span className="text-sm font-mono">{addr.slice(0, 10)}...{addr.slice(-6)}</span>
              </div>
              <button onClick={() => copy(addr, label)} className="p-2 rounded-xl hover:bg-white/10 text-aegis-accent">
                {copiedAddress === label ? <CheckCircle2 className="w-4 h-4 text-green-400" /> : <Copy className="w-4 h-4" />}
              </button>
            </div>
          ))}
        </div>

        <button
          onClick={handleMint}
          disabled={isPending || !address || done}
          className="w-full py-5 rounded-2xl accent-gradient text-black font-black text-[12px] uppercase glow-accent hover:opacity-90 transition-all flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {done ? "TOKENS MINTED ✓" : isPending ? "MINTING..." : "MINT TOKENS & ADD TO WALLET"}
          {!isPending && !done && <Zap className="w-4 h-4 fill-current" />}
        </button>
      </div>
    </Modal>
  )
}
