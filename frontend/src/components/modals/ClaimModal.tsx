"use client"

import Modal from "../ui/Modal"
import { Zap, ShieldCheck, History, ExternalLink } from "lucide-react"

interface ClaimModalProps {
  isOpen: boolean
  onClose: () => void
  claim: {
    id: string
    pool: string
    amount: string
    date: string
  } | null
}

export default function ClaimModal({ isOpen, onClose, claim }: ClaimModalProps) {
  if (!claim) return null

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Settle Insurance Claim">
      <div className="space-y-6">
        <div className="flex flex-col items-center text-center p-8 bg-aegis-accent/5 rounded-[32px] border border-aegis-accent/20 relative overflow-hidden">
          <div className="absolute top-0 right-0 w-32 h-32 bg-aegis-accent/10 blur-[40px] -z-10" />
          <div className="w-16 h-16 rounded-2xl bg-aegis-accent/20 flex items-center justify-center text-aegis-accent mb-4">
             <Zap className="w-8 h-8 fill-current" />
          </div>
          <div className="text-4xl font-black mb-1">{claim.amount}</div>
          <div className="text-[10px] font-black uppercase text-aegis-accent tracking-widest">Compensation Value</div>
        </div>

        <div className="space-y-4">
           <div className="flex justify-between items-center px-4 py-3 rounded-2xl bg-white/5 border border-aegis-border">
              <span className="text-[10px] font-black text-aegis-text-dim uppercase">Liquidity Pool</span>
              <span className="text-sm font-black">{claim.pool}</span>
           </div>
           <div className="flex justify-between items-center px-4 py-3 rounded-2xl bg-white/5 border border-aegis-border">
              <span className="text-[10px] font-black text-aegis-text-dim uppercase">Event Date</span>
              <span className="text-sm font-black">{claim.date}</span>
           </div>
           <div className="flex justify-between items-center px-4 py-3 rounded-2xl bg-white/5 border border-aegis-border">
              <span className="text-[10px] font-black text-aegis-text-dim uppercase">Claim ID</span>
              <span className="text-sm font-black font-mono">{claim.id}</span>
           </div>
        </div>

        <div className="p-6 bg-white/5 rounded-3xl border border-aegis-border/30 flex gap-4">
           <ShieldCheck className="w-6 h-6 text-green-400 shrink-0" />
           <p className="text-[10px] font-bold text-aegis-text-dim leading-relaxed uppercase tracking-wider">
             Your claim has been verified by the Reactive Network monitor. Funds are reserved and ready for atomic transfer.
           </p>
        </div>

        <div className="grid grid-cols-2 gap-4">
           <button 
             onClick={onClose}
             className="py-5 rounded-2xl bg-white/5 border border-aegis-border text-[10px] font-black uppercase hover:bg-white/10 transition-all"
           >
             CANCEL
           </button>
           <button 
             className="py-5 rounded-2xl accent-gradient text-black font-black text-[10px] uppercase glow-accent hover:opacity-90 transition-all flex items-center justify-center gap-2"
           >
             CONFIRM CLAIM
             <Zap className="w-3 h-3 fill-current" />
           </button>
        </div>

        <div className="flex justify-center">
           <button className="text-[10px] font-black text-aegis-text-dim hover:text-white transition-all uppercase tracking-widest flex items-center gap-2">
              <ExternalLink className="w-3 h-3" />
              View Transaction Proof
           </button>
        </div>
      </div>
    </Modal>
  )
}
