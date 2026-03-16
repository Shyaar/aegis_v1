'use client'
import { History, ShieldAlert, CheckCircle2, Search, ExternalLink, Zap } from "lucide-react"
import { useState, useEffect } from "react"

export default function ClaimsDashboard() {
  // Placeholders for Privy integration
  const isConnected = false
  const address = ""

  const isSettling = false
  const isSuccess = false

  // Mock claims for the UI
  const [claims, setClaims] = useState([
    { id: 1, displayId: "CL-8192", date: "2026-03-10", pool: "ETH / USDC", amount: "0.005 ETH", status: "Settled" },
    { id: 2, displayId: "CL-8185", date: "2026-03-09", pool: "USDC / ETH", amount: "12.42 USDC", status: "Ready to Claim" },
  ])

  const handleSettle = async (claimId: number) => {
    alert("Claim settlement initiated (Mock)")
  }

  return (
    <main className="max-w-[1200px] mx-auto px-6 py-16">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6 mb-12">
        <div>
          <h1 className="text-4xl font-black mb-2 tracking-tighter uppercase underline decoration-amber-500 decoration-4 underline-offset-8">Insurance Dashboard</h1>
          <p className="text-aegis-text-dim font-bold text-sm uppercase tracking-widest">Track your protection history and settle deferred claims.</p>
        </div>
        <div className="relative group">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-aegis-text-dim" />
          <input
            type="text"
            placeholder="Search claim ID..."
            className="pl-12 pr-6 py-4 rounded-2xl bg-white/5 border border-aegis-border focus:border-aegis-accent outline-none transition-all w-[300px] text-sm font-bold"
          />
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-10">
        <div className="lg:col-span-2 space-y-8">
          <h2 className="text-xl font-black uppercase tracking-tight flex items-center gap-3">
            <History className="w-5 h-5 text-aegis-accent" />
            Claim History
          </h2>

          <div className="glass-card rounded-[40px] border border-aegis-border/20 overflow-hidden">
            <div className="grid grid-cols-5 p-8 border-b border-aegis-border/30 text-[10px] font-black text-aegis-text-dim uppercase tracking-widest">
              <div className="col-span-2">Insurance Event</div>
              <div className="text-right">Compensation</div>
              <div className="text-right">Status</div>
              <div className="text-right">Action</div>
            </div>
            <div className="divide-y divide-aegis-border/10">
              {claims.map((claim) => (
                <div key={claim.id} className="grid grid-cols-5 p-8 items-center group hover:bg-white/[0.01] transition-all">
                  <div className="col-span-2 flex items-center gap-4">
                    <div className="w-12 h-12 rounded-2xl bg-white/5 flex items-center justify-center border border-aegis-border p-2">
                      <Zap className={`w-6 h-6 ${claim.status === 'Settled' ? 'text-green-400' : 'text-aegis-accent animate-pulse'}`} />
                    </div>
                    <div>
                      <div className="font-black text-lg">{claim.pool}</div>
                      <div className="text-[10px] font-bold text-aegis-text-dim uppercase">{claim.date} • ID: {claim.displayId}</div>
                    </div>
                  </div>
                  <div className="text-right font-black text-lg">{claim.amount}</div>
                  <div className="text-right flex flex-col items-end">
                    <span className={`px-3 py-1 rounded-full text-[9px] font-black uppercase tracking-widest ${claim.status === "Settled" ? "bg-green-500/10 text-green-400" : "bg-aegis-accent/10 text-aegis-accent"
                      }`}>
                      {claim.status}
                    </span>
                  </div>
                  <div className="text-right">
                    {claim.status === "Settled" ? (
                      <button className="text-aegis-text-dim hover:text-white transition-colors">
                        <ExternalLink className="w-5 h-5 ml-auto" />
                      </button>
                    ) : (
                      <button
                        onClick={() => handleSettle(claim.id)}
                        disabled={isSettling}
                        className="px-6 py-2 rounded-xl accent-gradient text-black font-black text-[10px] glow-accent transition-all hover:scale-105 disabled:opacity-50"
                      >
                        {isSettling ? "SETTLING..." : "SETTLE NOW"}
                      </button>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        <div className="space-y-8">
          <h2 className="text-xl font-black uppercase tracking-tight flex items-center gap-3">
            <ShieldAlert className="w-5 h-5 text-amber-500" />
            Policy Alerts
          </h2>

          <div className="glass-card p-8 rounded-[40px] border border-amber-500/20 bg-amber-500/[0.02]">
            <h3 className="font-black text-amber-500 text-sm uppercase mb-4">Market Influx Detected</h3>
            <p className="text-xs font-bold text-aegis-text-dim leading-relaxed mb-6">
              ETH/USDC liquidity is experiencing high volatility. Aegis dynamic fees have been scaled to 0.45% and premiums adjusted (+15%) by the Reactive Network to maintain reserve health.
            </p>
            <div className="flex items-center gap-2 text-[10px] font-black text-amber-500/60 uppercase">
              <Activity className="w-3 h-3" />
              <span>Reactive Protocol Level: 2 (Caution)</span>
            </div>
          </div>

          <div className="glass-card p-8 rounded-[40px] border border-aegis-border/20">
            <h3 className="font-black text-white text-sm uppercase mb-4">Total Compensation Paid</h3>
            <div className="text-4xl font-black text-aegis-accent mb-2">$59.32</div>
            <p className="text-[10px] font-black text-aegis-text-dim uppercase tracking-widest">Across 3 insurance events</p>
            <div className="mt-8 pt-8 border-t border-aegis-border/10 space-y-4">
              <div className="flex justify-between text-[10px] font-bold uppercase">
                <span className="text-aegis-text-dim">Net Protection ROI</span>
                <span className="text-green-400">+42%</span>
              </div>
              <div className="flex justify-between text-[10px] font-bold uppercase">
                <span className="text-aegis-text-dim">Premiums Contributed</span>
                <span className="text-white">$12.18</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
  )
}

function Activity({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
    </svg>
  )
}
