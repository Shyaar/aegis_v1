"use client"

import { useState } from "react"
import {
  Settings,
  ChevronDown,
  ArrowDownUp,
  ShieldCheck,
  ShieldAlert,
  Info,
  Zap,
  BarChart3,
  Lock,
  ExternalLink
} from "lucide-react"

export default function SwapCard({ activeTab = "Swap" }: { activeTab?: string }) {
  const [isInsured, setIsInsured] = useState(true)
  const [amount, setAmount] = useState("1.0")
  const [limitPrice, setLimitPrice] = useState("2,410.50")

  const isBuyOrSell = activeTab === "Buy" || activeTab === "Sell"

  return (
    <div className="w-full max-w-[520px] relative">
      {/* Background Glows */}
      <div className="absolute -top-20 -left-20 w-64 h-64 bg-aegis-accent/10 blur-[100px] rounded-full" />
      <div className="absolute -bottom-20 -right-20 w-64 h-64 bg-blue-600/10 blur-[100px] rounded-full" />

      {/* Main Swap Card */}
      <div className="glass-card rounded-[40px] p-8 space-y-6 relative overflow-hidden">
        <div className="flex justify-between items-center px-1">
          <h2 className="text-xl font-black tracking-tight uppercase">Aegis {activeTab}</h2>
          <div className="flex gap-4">
            <BarChart3 className="w-5 h-5 text-aegis-text-dim cursor-pointer hover:text-white transition-colors" />
            <Settings className="w-5 h-5 text-aegis-text-dim cursor-pointer hover:text-white transition-colors" />
          </div>
        </div>

        {/* Input Token / Amount */}
        <div className="bg-black/50 rounded-3xl p-6 border border-aegis-border group hover:border-white/10 transition-all">
          <div className="flex justify-between items-center mb-4">
            <span className="text-[10px] font-black text-aegis-text-dim uppercase tracking-widest">
              {activeTab === "Buy" ? "You Pay" : activeTab === "Sell" ? "You Sell" : "You Sell"}
            </span>
            <span className="text-[10px] font-bold text-aegis-text-dim uppercase">Balance: 2.14 ETH</span>
          </div>
          <div className="flex justify-between items-center gap-4">
            <input
              type="number"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              className="w-full bg-transparent text-4xl font-black outline-none placeholder:text-white/10"
              placeholder="0.0"
            />
            {!isBuyOrSell ? (
              <div className="flex items-center gap-2 bg-white/5 hover:bg-white/10 px-4 py-2.5 rounded-2xl cursor-pointer border border-aegis-border transition-all whitespace-nowrap">
                <img src="https://cryptologos.cc/logos/ethereum-eth-logo.svg?v=040" alt="ETH" className="w-6 h-6" />
                <span className="font-black text-lg">ETH</span>
                <ChevronDown className="w-5 h-5 text-aegis-text-dim" />
              </div>
            ) : (
              <div className="flex items-center gap-2 bg-white/5 px-4 py-2.5 rounded-2xl border border-aegis-border text-aegis-text-dim font-black">
                {activeTab === "Buy" ? "USD" : "ETH"}
              </div>
            )}
          </div>
        </div>

        {/* Limit Price Input */}
        {activeTab === "Limit" && (
          <div className="bg-black/50 rounded-[28px] p-5 border border-aegis-border animate-in fade-in slide-in-from-top-2 duration-300">
            <div className="flex justify-between items-center mb-3 px-1">
              <span className="text-[10px] font-black text-aegis-text-dim uppercase tracking-widest">Limit Price</span>
              <span className="text-[10px] font-bold text-aegis-accent uppercase cursor-pointer hover:underline underline-offset-4">Market</span>
            </div>
            <div className="flex justify-between items-center gap-4">
              <input
                type="text"
                value={limitPrice}
                onChange={(e) => setLimitPrice(e.target.value)}
                className="w-full bg-transparent text-2xl font-black outline-none placeholder:text-white/10"
              />
              <span className="text-sm font-black text-aegis-text-dim whitespace-nowrap">USDT per ETH</span>
            </div>
          </div>
        )}

        {/* Switch Divider (Only for Swap and Limit) */}
        {!isBuyOrSell && (
          <div className="relative h-2 flex items-center justify-center -my-2 z-10">
            <div className="absolute w-full h-px bg-aegis-border" />
            <button className="w-12 h-12 glass-card rounded-2xl flex items-center justify-center border border-aegis-border hover:scale-110 transition-transform bg-aegis-bg">
              <ArrowDownUp className="w-6 h-6 text-aegis-accent" />
            </button>
          </div>
        )}

        {/* Output Token (Only for Swap and Limit) */}
        {!isBuyOrSell && (
          <div className={`bg-black/50 rounded-3xl p-6 border border-aegis-border group hover:border-white/10 transition-all ${activeTab === 'Limit' ? '' : 'pt-10'}`}>
            <div className="flex justify-between items-center mb-4">
              <span className="text-[10px] font-black text-aegis-text-dim uppercase tracking-widest">You Buy</span>
            </div>
            <div className="flex justify-between items-center gap-4">
              <div className="text-4xl font-black text-white/40">2,410.50</div>
            <div className="flex items-center gap-2 bg-white/5 hover:bg-white/10 px-4 py-2.5 rounded-2xl cursor-pointer border border-aegis-border transition-all whitespace-nowrap">
                <img src="https://cryptologos.cc/logos/tether-usdt-logo.svg?v=040" alt="USDT" className="w-6 h-6" />
                <span className="font-black text-lg">USDT</span>
                <ChevronDown className="w-5 h-5 text-aegis-text-dim" />
              </div>
            </div>
          </div>
        )}

        {/* Aegis Protection Tooltip/Toggle (Only for Swap for now) */}
        {activeTab === "Swap" && (
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
                  <h3 className="font-black text-sm flex items-center gap-2 uppercase tracking-tight">
                    Aegis Slippage Insurance
                    <Info className="w-4 h-4 text-aegis-text-dim" />
                  </h3>
                  <p className="text-[10px] font-black text-aegis-text-dim leading-relaxed uppercase tracking-widest mt-1">
                    {isInsured ? "Slippage 0.05% GUARANTEED" : "UNPROTECTED"}
                  </p>
                </div>
              </div>
              <div className={`w-14 h-7 rounded-full relative transition-all duration-300 ${isInsured ? "bg-aegis-accent glow-accent" : "bg-white/10"}`}>
                <div className={`absolute top-1 w-5 h-5 rounded-full bg-white transition-all duration-300 shadow-md ${isInsured ? "left-8" : "left-1"}`} />
              </div>
            </div>

            {isInsured && (
              <div className="mt-5 pt-5 border-t border-aegis-accent/10 space-y-3 animate-in fade-in slide-in-from-top-2 duration-500">
                <div className="flex justify-between items-center text-[10px] font-black uppercase tracking-widest">
                  <span className="text-aegis-text-dim">Insurance Premium</span>
                  <span className="text-aegis-accent underline decoration-aegis-accent/30 underline-offset-4 cursor-pointer">0.12% (~$2.89)</span>
                </div>
                <div className="flex justify-between items-center text-[10px] font-black uppercase tracking-widest">
                  <span className="text-aegis-text-dim">Payout Trigger</span>
                  <span className="text-green-400">-{">"} 0.5% Execution Delta</span>
                </div>
              </div>
            )}
          </div>
        )}

        {/* Confirm Button */}
        <button className="w-full py-5 rounded-[32px] accent-gradient text-black font-black text-lg glow-accent hover:opacity-90 active:scale-[0.99] transition-all flex items-center justify-center gap-3">
          {activeTab === "Swap" && isInsured && <Zap className="w-5 h-5 fill-current" />}
          {activeTab === "Swap" ? (isInsured ? "PROTECTED SWAP" : "SWAP WITHOUT COVERAGE") :
            activeTab === "Limit" ? "PLACE LIMIT ORDER" :
              activeTab === "Buy" ? "BUY WITH CARD" :
                "SELL TO CARD / BANK"}
        </button>
      </div>

      {/* Stats Bar */}
      <div className="flex items-center justify-between px-6 mt-6">
        <div className="flex items-center gap-2 text-[10px] font-black text-aegis-text-dim uppercase tracking-widest">
          <Lock className="w-3 h-3" />
          <span>Reactive Network Enabled</span>
        </div>
        <div className="flex items-center gap-1.5 text-[10px] font-black text-aegis-accent uppercase tracking-widest cursor-pointer hover:glow-text">
          View Route Details
          <ExternalLink className="w-3 h-3" />
        </div>
      </div>
    </div>
  )
}
