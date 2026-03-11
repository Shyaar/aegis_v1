"use client"

import Modal from "../ui/Modal"
import { Shield, ShieldCheck, ShieldAlert, Check } from "lucide-react"

interface ProtectionModalProps {
  isOpen: boolean
  onClose: () => void
  selectedTier: string
  onSelectTier: (tier: string) => void
}

export default function ProtectionModal({ isOpen, onClose, selectedTier, onSelectTier }: ProtectionModalProps) {
  const tiers = [
    { name: "Basic", threshold: "1.0%", premium: "0.05%", icon: <Shield className="w-5 h-5" />, desc: "Covers major volatility spikes." },
    { name: "Standard", threshold: "0.5%", premium: "0.12%", icon: <ShieldCheck className="w-5 h-5" />, desc: "The balanced choice for most traders." },
    { name: "Full", threshold: "0.2%", premium: "0.25%", icon: <ShieldAlert className="w-5 h-5" />, desc: "Maximum protection for large capital." },
  ]

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Protection Settings">
      <div className="space-y-4">
        {tiers.map((tier) => (
          <div 
            key={tier.name}
            className={`p-6 rounded-3xl border transition-all cursor-pointer flex items-center justify-between group ${
              selectedTier === tier.name 
                ? "bg-aegis-accent/10 border-aegis-accent" 
                : "bg-white/5 border-aegis-border hover:bg-white/10"
            }`}
            onClick={() => onSelectTier(tier.name)}
          >
            <div className="flex items-center gap-4">
              <div className={`w-10 h-10 rounded-xl flex items-center justify-center transition-colors ${
                selectedTier === tier.name ? "bg-aegis-accent/20 text-aegis-accent" : "bg-white/5 text-aegis-text-dim"
              }`}>
                {tier.icon}
              </div>
              <div>
                <div className="font-black text-sm uppercase tracking-tight flex items-center gap-2">
                  {tier.name}
                  <span className="text-[10px] font-bold text-aegis-text-dim lowercase tracking-normal">at {tier.premium} premium</span>
                </div>
                <div className="text-[10px] font-black uppercase tracking-widest text-aegis-accent mt-0.5">
                  Slippage {tier.threshold} guaranteed
                </div>
              </div>
            </div>
            {selectedTier === tier.name && (
              <div className="w-6 h-6 rounded-full bg-aegis-accent flex items-center justify-center">
                <Check className="w-4 h-4 text-black" />
              </div>
            )}
          </div>
        ))}
        
        <div className="mt-8 p-6 bg-white/5 rounded-3xl border border-aegis-border/30">
          <p className="text-[11px] font-bold text-aegis-text-dim leading-relaxed uppercase tracking-wider">
            Slippage protection is atomic. If the execution price exceeds your threshold, the difference is paid out directly into your wallet by the Aegis Reserve.
          </p>
        </div>

        <button 
          onClick={onClose}
          className="w-full py-5 rounded-2xl accent-gradient text-black font-black text-sm mt-4 glow-accent hover:opacity-90 transition-all"
        >
          CONFIRM SELECTION
        </button>
      </div>
    </Modal>
  )
}
