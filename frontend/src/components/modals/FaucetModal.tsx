"use client"

import Modal from "../ui/Modal"
import { Zap, Wallet, Info, Copy, CheckCircle2 } from "lucide-react"
import { useState } from "react"
// import { useWriteContract, useWaitForTransactionReceipt } from "wagmi"
// import { parseEther } from "viem"

interface FaucetModalProps {
  isOpen: boolean
  onClose: () => void
}

export default function FaucetModal({ isOpen, onClose }: FaucetModalProps) {
  const [isMinting, setIsMinting] = useState(false)
  const [copiedAddress, setCopiedAddress] = useState<string | null>(null)

  // Mock addresses for now
  const MOCK_ETH_ADDRESS = "0xMockETHAddress___"
  const MOCK_USDC_ADDRESS = "0xMockUSDCAddress___"

  const handleMint = async () => {
    setIsMinting(true)
    try {
      // Mock minting delay
      await new Promise(resolve => setTimeout(resolve, 2000))
      
      // Attempt auto-add to wallet (mocked logic)
      if (window.ethereum) {
        try {
          await window.ethereum.request({
            method: 'wallet_watchAsset',
            params: {
              type: 'ERC20',
              options: {
                address: MOCK_ETH_ADDRESS,
                symbol: 'mETH',
                decimals: 18,
              },
            },
          })
          
          await window.ethereum.request({
            method: 'wallet_watchAsset',
            params: {
              type: 'ERC20',
              options: {
                address: MOCK_USDC_ADDRESS,
                symbol: 'mUSDC',
                decimals: 6,
              },
            },
          })
        } catch (error) {
          console.error("Auto-add failed or cancelled", error)
        }
      }
      
    } catch (error) {
      console.error("Minting failed", error)
    } finally {
      setIsMinting(false)
    }
  }

  const copyToClipboard = (text: string, type: 'eth' | 'usdc') => {
    navigator.clipboard.writeText(text)
    setCopiedAddress(type)
    setTimeout(() => setCopiedAddress(null), 2000)
  }

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Get Test Tokens">
      <div className="space-y-6">
        
        {/* Token Info Section */}
        <div className="flex flex-col items-center text-center p-6 bg-aegis-accent/5 rounded-[32px] border border-aegis-accent/20 relative overflow-hidden">
          <div className="absolute top-0 right-0 w-32 h-32 bg-aegis-accent/10 blur-[40px] -z-10" />
          <div className="w-16 h-16 rounded-2xl bg-aegis-accent/20 flex items-center justify-center text-aegis-accent mb-4">
            <Zap className="w-8 h-8 fill-current" />
          </div>
          <div className="text-2xl font-black mb-1">10 mETH & 1000 mUSDC</div>
          <div className="text-[10px] font-black uppercase text-aegis-accent tracking-widest">Received per request</div>
        </div>

        {/* Auto-add Info */}
        <div className="p-5 bg-white/5 rounded-3xl border border-aegis-border/30 flex gap-4 items-start">
          <Wallet className="w-6 h-6 text-blue-400 shrink-0 mt-1" />
          <div>
            <p className="text-[11px] font-bold text-white leading-relaxed tracking-wider mb-1">
              Auto-add to Wallet
            </p>
            <p className="text-[10px] text-aegis-text-dim leading-relaxed tracking-wide">
              We'll attempt to automatically add these tokens to your wallet. If it doesn't work, you can add them manually using the addresses below.
            </p>
          </div>
        </div>

        {/* Manual Add Section */}
        <div className="space-y-3">
          <div className="flex justify-between items-center px-4 py-3 rounded-2xl bg-white/5 border border-aegis-border hover:bg-white/10 transition-colors">
            <div className="flex flex-col">
              <span className="text-[10px] font-black text-aegis-text-dim uppercase">Mock ETH</span>
              <span className="text-sm font-mono tracking-tight">{MOCK_ETH_ADDRESS.slice(0,10)}...</span>
            </div>
            <button 
              onClick={() => copyToClipboard(MOCK_ETH_ADDRESS, 'eth')}
              className="p-2 rounded-xl hover:bg-white/10 text-aegis-accent transition-all"
            >
              {copiedAddress === 'eth' ? <CheckCircle2 className="w-4 h-4 text-green-400" /> : <Copy className="w-4 h-4" />}
            </button>
          </div>

          <div className="flex justify-between items-center px-4 py-3 rounded-2xl bg-white/5 border border-aegis-border hover:bg-white/10 transition-colors">
            <div className="flex flex-col">
              <span className="text-[10px] font-black text-aegis-text-dim uppercase">Mock USDC</span>
              <span className="text-sm font-mono tracking-tight">{MOCK_USDC_ADDRESS.slice(0,10)}...</span>
            </div>
            <button 
              onClick={() => copyToClipboard(MOCK_USDC_ADDRESS, 'usdc')}
              className="p-2 rounded-xl hover:bg-white/10 text-aegis-accent transition-all"
            >
              {copiedAddress === 'usdc' ? <CheckCircle2 className="w-4 h-4 text-green-400" /> : <Copy className="w-4 h-4" />}
            </button>
          </div>
        </div>

        {/* Action Button */}
        <button
          onClick={handleMint}
          disabled={isMinting}
          className="w-full py-5 rounded-2xl accent-gradient text-black font-black text-[12px] uppercase glow-accent hover:opacity-90 transition-all flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isMinting ? "MINTING TOKENS..." : "MINT TOKENS & ADD TO WALLET"}
          {!isMinting && <Zap className="w-4 h-4 fill-current" />}
        </button>

      </div>
    </Modal>
  )
}
