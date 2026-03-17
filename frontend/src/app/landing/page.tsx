"use client"

import { ShieldCheck, Zap, BarChart3, Lock, ArrowRight, Shield, Activity, Globe } from "lucide-react"
import Link from "next/link"
import Swap from "../swap/swap"
import { useState } from "react"
import FaucetModal from "../../components/modals/FaucetModal"

export default function LandingPage() {
  const [isFaucetOpen, setIsFaucetOpen] = useState(false)

  return (
    <div className="flex flex-col items-center">
      {/*Swap Area*/}
      <div id="swap" className="scroll-mt-24">
        <Swap />
      </div>
      {/* Hero Section */}
      <section className="w-full max-w-[1400px] px-6 pt-24 pb-32 flex flex-col items-center text-center relative">
        {/* Background Gradients */}
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[1000px] h-[600px] bg-aegis-accent/10 blur-[120px] rounded-full -z-10" />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 w-[800px] h-[400px] bg-blue-600/10 blur-[100px] rounded-full -z-10" />

        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/5 border border-aegis-border text-xs font-black tracking-widest text-aegis-accent mb-8 animate-in fade-in slide-in-from-bottom-4 duration-1000">
          <Zap className="w-3 h-3 fill-current" />
          POWERED BY REACTIVE NETWORK
        </div>

        <h1 className="text-6xl md:text-8xl font-black tracking-tighter leading-[0.9] mb-8 animate-in fade-in slide-in-from-bottom-6 duration-1000 delay-100">
          SWAP WITHOUT <br />
          <span className="text-gradient glow-text">COMPROMISE.</span>
        </h1>

        <p className="max-w-2xl text-lg md:text-xl font-medium text-aegis-text-dim mb-12 animate-in fade-in slide-in-from-bottom-8 duration-1000 delay-200">
          The first Uniswap v4 hook that natively embeds slippage insurance into every trade.
          Get protected. Get compensated. Automatically.
        </p>

        <div className="flex flex-col sm:flex-row gap-6 animate-in fade-in slide-in-from-bottom-10 duration-1000 delay-300">
          <Link href="/swap" className="px-10 py-5 rounded-[28px] accent-gradient text-black font-black text-lg glow-accent hover:scale-105 transition-all flex items-center justify-center gap-3">
            LAUNCH APP
            <ArrowRight className="w-5 h-5" />
          </Link>
          <button onClick={() => setIsFaucetOpen(true)} className="px-10 py-5 rounded-[28px] glass-card border border-aegis-border hover:bg-white/5 transition-all font-black text-lg">
            GET TEST TOKENS
          </button>
        </div>

        {/* Floating Stats */}
        <div className="mt-24 grid grid-cols-2 md:grid-cols-4 gap-12 border-t border-aegis-border/30 pt-16 w-full max-w-4xl">
          {[
            { label: "Total Protected", value: "$42.1M" },
            { label: "Fees Saved", value: "$1.2M" },
            { label: "Avg Execution", value: "99.9%" },
            { label: "Active Pools", value: "128" },
          ].map((stat) => (
            <div key={stat.label} className="flex flex-col gap-2">
              <span className="text-[10px] font-black tracking-widest text-aegis-text-dim uppercase">{stat.label}</span>
              <span className="text-3xl font-black">{stat.value}</span>
            </div>
          ))}
        </div>
      </section>

      {/* Features Grid */}
      <section className="w-full max-w-[1200px] px-6 py-32 grid grid-cols-1 md:grid-cols-3 gap-8">
        <div className="glass-card p-10 rounded-[40px] border border-aegis-border group hover:border-aegis-accent/30 transition-all">
          <div className="w-14 h-14 rounded-2xl bg-aegis-accent/10 flex items-center justify-center text-aegis-accent mb-8 group-hover:scale-110 transition-transform">
            <Shield className="w-8 h-8" />
          </div>
          <h3 className="text-2xl font-black mb-4 tracking-tight">ATOMIC PROTECTION</h3>
          <p className="font-medium text-aegis-text-dim leading-relaxed">
            Slippage insurance is baked into the swap lifecycle. No external claims, no waiting. Payouts happen in the same block.
          </p>
        </div>

        <div className="glass-card p-10 rounded-[40px] border border-aegis-border group hover:border-green-400/30 transition-all">
          <div className="w-14 h-14 rounded-2xl bg-green-500/10 flex items-center justify-center text-green-400 mb-8 group-hover:scale-110 transition-transform">
            <Activity className="w-8 h-8" />
          </div>
          <h3 className="text-2xl font-black mb-4 tracking-tight">DYNAMIC RISK</h3>
          <p className="font-medium text-aegis-text-dim leading-relaxed">
            Premiums and fees scale based on real-time market volatility. Protected swaps stay cheap during calm, and LPs stay safe during storms.
          </p>
        </div>

        <div className="glass-card p-10 rounded-[40px] border border-aegis-border group hover:border-blue-600/30 transition-all">
          <div className="w-14 h-14 rounded-2xl bg-blue-600/10 flex items-center justify-center text-blue-600 mb-8 group-hover:scale-110 transition-transform">
            <Globe className="w-8 h-8" />
          </div>
          <h3 className="text-2xl font-black mb-4 tracking-tight">POWERED BY REACTIVE</h3>
          <p className="font-medium text-aegis-text-dim leading-relaxed">
            The Reactive Network autonomously monitors reserve health and adjusts protocol parameters 24/7 without human intervention.
          </p>
        </div>
      </section>

      {/* Final CTA */}
      <section className="w-full py-32 flex justify-center px-6">
        <div className="w-full max-w-[1200px] glass-card rounded-[60px] p-16 md:p-32 relative overflow-hidden flex flex-col items-center text-center border border-aegis-border/20">
          <div className="absolute top-0 right-0 w-[400px] h-[400px] bg-aegis-accent/5 blur-[100px] -z-10" />
          <h2 className="text-4xl md:text-6xl font-black tracking-tighter mb-10 leading-none">
            READY TO SECURE <br /> Trades?
          </h2>
          <Link 
            href="#swap" 
            onClick={(e) => {
              e.preventDefault();
              document.getElementById('swap')?.scrollIntoView({ behavior: 'smooth' });
            }}
            className="px-12 py-6 rounded-[32px] accent-gradient text-black font-black text-xl glow-accent hover:scale-105 transition-all"
          >
            Swap with protection
          </Link>
        </div>
      </section>
      <FaucetModal isOpen={isFaucetOpen} onClose={() => setIsFaucetOpen(false)} />
    </div>
  )
}
