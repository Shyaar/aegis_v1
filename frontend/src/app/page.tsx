"use client"

import { useState, useEffect } from "react"
import {
  Settings,
  ChevronDown,
  ArrowDownUp,
  ShieldCheck,
  ShieldAlert,
  Info,
  Zap,
  BarChart3,
  LayoutDashboard,
  History,
  ExternalLink,
  Lock
} from "lucide-react"

export default function AegisSwap() {
  const [activeTab, setActiveTab] = useState("Swap")
  const [isInsured, setIsInsured] = useState(true)
  const [amount, setAmount] = useState("1.0")
  const [isMounted, setIsMounted] = useState(false)

  // Avoid hydration mismatch for animations
  useEffect(() => setIsMounted(true), [])

  if (!isMounted) return <div className="min-h-screen bg-[#030305]" />

  return (
    <div className="min-h-screen bg-aegis-bg text-aegis-text selection:bg-aegis-accent/30 font-sans tracking-tight">
      {/* Header */}
      <nav className="flex items-center justify-between px-8 py-4 border-b border-aegis-border bg-aegis-bg/60 backdrop-blur-xl sticky top-0 z-50">
        <div className="flex items-center gap-10">
          <div className="flex items-center gap-2 group cursor-pointer">
            <div className="w-10 h-10 accent-gradient rounded-xl flex items-center justify-center glow-accent transition-transform group-hover:scale-105">
              <ShieldCheck className="text-white w-6 h-6" />
            </div>
            <span className="text-2xl font-black tracking-tighter glow-text">AEGIS</span>
          </div>

          <div className="hidden lg:flex items-center gap-8 text-[13px] font-bold uppercase tracking-widest text-aegis-text-dim">
            {["Swap", "Vaults", "Insurance", "Analytics"].map((item) => (
              <button
                key={item}
                className={`transition-all hover:text-aegis-accent relative py-2 ${activeTab === item ? "text-aegis-accent" : ""
                  }`}
                onClick={() => setActiveTab(item)}
              >
                {item}
                {activeTab === item && (
                  <div className="absolute -bottom-1 left-0 right-0 h-0.5 bg-aegis-accent glow-accent rounded-full" />
                )}
              </button>
            ))}
          </div>
        </div>

        <div className="flex items-center gap-4">
          <div className="hidden sm:flex items-center gap-2 px-3 py-1.5 rounded-full bg-white/5 border border-aegis-border text-[11px] font-bold">
            <span className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
            UNICHAIN MAINNET
          </div>
          <button className="flex items-center gap-2 px-6 py-2.5 rounded-2xl accent-gradient hover:opacity-90 transition-all text-sm font-black text-black glow-accent">
            CONNECT WALLET
          </button>
        </div>
      </nav>

      <main className="max-w-[1400px] mx-auto px-6 py-16 flex flex-col items-center">
        {/* Navigation Selector */}
        <div className="flex bg-white/5 p-1.5 rounded-2xl mb-12 border border-aegis-border">
          {["Swap", "Limit", "DCA", "Bridge"].map((tab) => (
            <button
              key={tab}
              className={`px-8 py-2 rounded-xl text-[13px] font-bold transition-all ${tab === "Swap"
                  ? "bg-white/10 text-white shadow-lg shadow-black/20"
                  : "text-aegis-text-dim hover:text-white"
                }`}
            >
              {tab}
            </button>
          ))}
        </div>

        <div className="w-full max-w-[520px] relative">
          {/* Background Glows */}
          <div className="absolute -top-20 -left-20 w-64 h-64 bg-aegis-accent/10 blur-[100px] rounded-full" />
          <div className="absolute -bottom-20 -right-20 w-64 h-64 bg-blue-600/10 blur-[100px] rounded-full" />

          {/* Main Swap Card */}
          <div className="glass-card rounded-[40px] p-8 space-y-6 relative overflow-hidden">
            <div className="flex justify-between items-center px-1">
              <h2 className="text-xl font-bold">SafeSwap</h2>
              <div className="flex gap-4">
                <BarChart3 className="w-5 h-5 text-aegis-text-dim cursor-pointer hover:text-white transition-colors" />
                <Settings className="w-5 h-5 text-aegis-text-dim cursor-pointer hover:text-white transition-colors" />
              </div>
            </div>

            {/* Input Token */}
            <div className="bg-black/50 rounded-3xl p-6 border border-aegis-border group hover:border-white/10 transition-all active:scale-[0.98]">
              <div className="flex justify-between items-center mb-4">
                <span className="text-xs font-black text-aegis-text-dim uppercase tracking-widest">You Sell</span>
                <span className="text-xs font-bold text-aegis-text-dim">Balance: 2.14 ETH</span>
              </div>
              <div className="flex justify-between items-center gap-4">
                <input
                  type="number"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  className="w-full bg-transparent text-4xl font-black outline-none placeholder:text-white/10"
                  placeholder="0.0"
                />
                <div className="flex items-center gap-2 bg-white/5 hover:bg-white/10 px-4 py-2.5 rounded-2xl cursor-pointer border border-aegis-border transition-all whitespace-nowrap">
                  <div className="w-7 h-7 bg-[#627EEA] rounded-full flex items-center justify-center italic font-black text-[10px]">ETH</div>
                  <span className="font-black text-lg">ETH</span>
                  <ChevronDown className="w-5 h-5 text-aegis-text-dim" />
                </div>
              </div>
            </div>

            {/* Switch Divider */}
            <div className="relative h-2 flex items-center justify-center -my-2 z-10">
              <div className="absolute w-full h-px bg-aegis-border" />
              <button className="w-12 h-12 glass-card rounded-2xl flex items-center justify-center border border-aegis-border hover:scale-110 transition-transform bg-aegis-bg">
                <ArrowDownUp className="w-6 h-6 text-aegis-accent" />
              </button>
            </div>

            {/* Output Token */}
            <div className="bg-black/50 rounded-3xl p-6 border border-aegis-border group hover:border-white/10 transition-all pt-10">
              <div className="flex justify-between items-center mb-4">
                <span className="text-xs font-black text-aegis-text-dim uppercase tracking-widest">You Buy</span>
              </div>
              <div className="flex justify-between items-center gap-4">
                <div className="text-4xl font-black text-white/40">2,410.50</div>
                <div className="flex items-center gap-2 bg-white/5 hover:bg-white/10 px-4 py-2.5 rounded-2xl cursor-pointer border border-aegis-border transition-all whitespace-nowrap">
                  <div className="w-7 h-7 bg-[#26A17B] rounded-full flex items-center justify-center font-black text-[10px]">USDT</div>
                  <span className="font-black text-lg">USDT</span>
                  <ChevronDown className="w-5 h-5 text-aegis-text-dim" />
                </div>
              </div>
            </div>

            {/* Aegis Protection Tooltip/Toggle */}
            <div
              className={`p-6 rounded-[28px] border transition-all cursor-pointer relative group ${isInsured
                  ? "bg-aegis-accent/5 border-aegis-accent/20"
                  : "bg-white/[0.02] border-aegis-border hover:bg-white/[0.04]"
                }`}
              onClick={() => setIsInsured(!isInsured)}
            >
              <div className="flex items-start justify-between">
                <div className="flex gap-4">
                  <div className={`mt-1 p-2 rounded-xl ${isInsured ? "bg-aegis-accent/20 text-aegis-accent" : "bg-white/5 text-aegis-text-dim"}`}>
                    {isInsured ? <ShieldCheck className="w-6 h-6" /> : <ShieldAlert className="w-6 h-6" />}
                  </div>
                  <div>
                    <h3 className="font-black text-sm flex items-center gap-2">
                      Aegis Slippage Insurance
                      <Info className="w-4 h-4 text-aegis-text-dim" />
                    </h3>
                    <p className="text-[11px] font-bold text-aegis-text-dim leading-relaxed uppercase tracking-wider mt-1">
                      {isInsured ? "Max Slippage 0.05% GUARANTEED" : "UNPROTECTED: Market slippage applies"}
                    </p>
                  </div>
                </div>
                <div className={`w-14 h-7 rounded-full relative transition-all duration-300 ${isInsured ? "bg-aegis-accent shadow-[0_0_10px_rgba(0,242,255,0.4)]" : "bg-white/10"}`}>
                  <div className={`absolute top-1 w-5 h-5 rounded-full bg-white transition-all duration-300 shadow-md ${isInsured ? "left-8" : "left-1"}`} />
                </div>
              </div>

              {isInsured && (
                <div className="mt-5 pt-5 border-t border-aegis-accent/10 space-y-3 animate-in fade-in slide-in-from-top-2 duration-500">
                  <div className="flex justify-between items-center text-xs font-bold">
                    <span className="text-aegis-text-dim uppercase tracking-widest">Insurance Premium</span>
                    <span className="text-aegis-accent">0.12% (~$2.89)</span>
                  </div>
                  <div className="flex justify-between items-center text-xs font-bold">
                    <span className="text-aegis-text-dim uppercase tracking-widest">Payout Trigger</span>
                    <span className="text-green-400">-{">"} 0.5% Execution Delta</span>
                  </div>
                </div>
              )}
            </div>

            {/* Confirm Button */}
            <button className="w-full py-5 rounded-[28px] accent-gradient text-black font-black text-lg glow-accent hover:opacity-90 active:scale-[0.99] transition-all flex items-center justify-center gap-3">
              {isInsured && <Zap className="w-5 h-5" />}
              SWAP WITH PROTECTION
            </button>
          </div>

          {/* Stats Bar */}
          <div className="flex items-center justify-between px-6 mt-6">
            <div className="flex items-center gap-2 text-[11px] font-black text-aegis-text-dim uppercase tracking-tighter">
              <Lock className="w-3 h-3" />
              <span>Reactive Network Secured</span>
            </div>
            <div className="flex items-center gap-1.5 text-[11px] font-black text-aegis-accent uppercase cursor-pointer hover:glow-text">
              View Route Details
              <ExternalLink className="w-3 h-3" />
            </div>
          </div>
        </div>

        {/* Info Grid */}
        <div className="mt-24 grid grid-cols-1 md:grid-cols-3 gap-8 w-full max-w-[1100px]">
          <div className="glass-card p-8 rounded-[32px] group hover:border-aegis-accent/30 transition-all cursor-pointer">
            <div className="w-12 h-12 rounded-2xl bg-aegis-accent/10 flex items-center justify-center mb-6 text-aegis-accent group-hover:scale-110 transition-transform">
              <LayoutDashboard className="w-6 h-6" />
            </div>
            <h4 className="text-lg font-black mb-2 uppercase tracking-tight">Transparency Hub</h4>
            <p className="text-sm font-bold text-aegis-text-dim leading-relaxed">
              Real-time audit of every insured trade execution and automated payout status.
            </p>
          </div>
          <div className="glass-card p-8 rounded-[32px] group hover:border-green-400/30 transition-all cursor-pointer">
            <div className="w-12 h-12 rounded-2xl bg-green-500/10 flex items-center justify-center mb-6 text-green-400 group-hover:scale-110 transition-transform">
              <ShieldCheck className="w-6 h-6" />
            </div>
            <h4 className="text-lg font-black mb-2 uppercase tracking-tight">Liquidity Vaults</h4>
            <p className="text-sm font-bold text-aegis-text-dim leading-relaxed">
              Underwrite slippage risks by providing liquidity to the insurance reserves and earn premiums.
            </p>
          </div>
          <div className="glass-card p-8 rounded-[32px] group hover:border-amber-400/30 transition-all cursor-pointer">
            <div className="w-12 h-12 rounded-2xl bg-amber-500/10 flex items-center justify-center mb-6 text-amber-400 group-hover:scale-110 transition-transform">
              <History className="w-6 h-6" />
            </div>
            <h4 className="text-lg font-black mb-2 uppercase tracking-tight">Automated Claims</h4>
            <p className="text-sm font-bold text-aegis-text-dim leading-relaxed">
              Powered by Reactive Network. Instant settlement directly to your wallet — no manual claims needed.
            </p>
          </div>
        </div>
      </main>

      {/* Social Proof Line */}
      <div className="fixed bottom-0 left-0 right-0 h-10 bg-white/[0.03] backdrop-blur-md border-t border-aegis-border flex items-center justify-center gap-8 overflow-hidden">
        <div className="flex items-center gap-2 whitespace-nowrap animate-pulse">
          <div className="w-1.5 h-1.5 rounded-full bg-green-500" />
          <span className="text-[10px] font-black text-aegis-text-dim uppercase tracking-widest">LIVE FEED</span>
        </div>
        <div className="flex gap-12 text-[10px] font-bold text-aegis-text-dim/60 whitespace-nowrap overflow-hidden">
          <span>User 0x42...f23 saved <span className="text-aegis-accent">$12.42</span> in slippage</span>
          <span>User 0x1a...de9 saved <span className="text-aegis-accent">$4.10</span> in slippage</span>
          <span>User 0xde...9b2 protected swap execution on ETH/USDT</span>
        </div>
      </div>
    </div>
  )
}
