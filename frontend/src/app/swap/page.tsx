"use client"

import { useState } from "react"
import SwapCard from "@/components/swap/SwapCard"

export default function SwapPage() {
  const [activeTab, setActiveTab] = useState("Swap")

  return (
    <main className="max-w-[1400px] mx-auto px-6 py-16 flex flex-col items-center">
      <div className="flex bg-white/5 p-1.5 rounded-2xl mb-12 border border-aegis-border">
        {["Swap", "Limit", "Buy", "Sell"].map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`px-8 py-2 rounded-xl text-[13px] font-bold transition-all ${activeTab === tab
                ? "bg-white/10 text-white shadow-lg shadow-black/20"
                : "text-aegis-text-dim hover:text-white"
              }`}
          >
            {tab}
          </button>
        ))}
      </div>

      <SwapCard activeTab={activeTab} />

      {/* Info Boxes */}
      <div className="mt-20 w-full max-w-4xl grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="glass-card p-6 rounded-3xl border border-aegis-border/20">
          <h4 className="text-xs font-black text-aegis-accent uppercase tracking-widest mb-3">Live Execution Analytics</h4>
          <p className="text-xs font-bold text-aegis-text-dim leading-relaxed">
            Every insured swap is validated against UNICHAIN-1 TWAP to ensure your execution price remains within the coverage threshold.
          </p>
        </div>
        <div className="glass-card p-6 rounded-3xl border border-aegis-border/20">
          <h4 className="text-xs font-black text-amber-500 uppercase tracking-widest mb-3">Slippage Protection Policy</h4>
          <p className="text-xs font-bold text-aegis-text-dim leading-relaxed">
            Protection is atomic. If your execution price exceeds 0.5% deviation, the insurance payout covers the delta immediately.
          </p>
        </div>
      </div>
    </main>
  )
}
