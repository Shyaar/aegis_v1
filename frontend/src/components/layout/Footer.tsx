"use client"

export default function Footer() {
  return (
    <div className="fixed bottom-0 left-0 right-0 h-10 bg-white/[0.03] backdrop-blur-md border-t border-aegis-border flex items-center justify-center gap-8 overflow-hidden z-50">
      <div className="flex items-center gap-2 whitespace-nowrap animate-pulse">
        <div className="w-1.5 h-1.5 rounded-full bg-green-500" />
        <span className="text-[10px] font-black text-aegis-text-dim uppercase tracking-widest">LIVE FEED</span>
      </div>
      <div className="flex gap-12 text-[10px] font-bold text-aegis-text-dim/60 whitespace-nowrap overflow-hidden">
        <span>User 0x42...f23 saved <span className="text-aegis-accent">$12.42</span> in slippage</span>
        <span>User 0x1a...de9 saved <span className="text-aegis-accent">$4.10</span> in slippage</span>
        <span>User 0xde...9b2 protected swap execution on ETH/USDC</span>
      </div>
    </div>
  )
}
