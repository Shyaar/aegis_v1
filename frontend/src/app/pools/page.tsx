"use client"

import { Plus, Info, ShieldCheck, TrendingUp, Wallet, BarChart2 } from "lucide-react"

export default function PoolsPage() {
  const pools = [
    { id: 1, pair: "ETH / USDC", totalLiquidity: "$12.4M", insuranceReserve: "$420,000", totalPremiums: "$24,500", apr: "18.4%" },
    { id: 2, pair: "WBTC / ETH", totalLiquidity: "$8.1M", insuranceReserve: "$150,000", totalPremiums: "$12,100", apr: "14.2%" },
    { id: 3, pair: "USDT / USDC", totalLiquidity: "$24.5M", insuranceReserve: "$890,000", totalPremiums: "$5,400", apr: "6.8%" },
  ]

  return (
    <main className="max-w-[1200px] mx-auto px-6 py-16">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6 mb-12">
        <div>
          <h1 className="text-4xl font-black mb-2 tracking-tighter uppercase underline decoration-aegis-accent decoration-4 underline-offset-8">Insurance Pools</h1>
          <p className="text-aegis-text-dim font-bold text-sm uppercase lg:tracking-widest">Provide liquidity and underwrite slippage insurance to earn premiums.</p>
        </div>
        <button className="flex items-center gap-2 px-8 py-4 rounded-2xl accent-gradient text-black font-black text-sm glow-accent hover:scale-105 transition-all">
          <Plus className="w-5 h-5" />
          NEW POSITION
        </button>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
        <div className="glass-card p-8 rounded-[32px] border border-aegis-border/30">
          <div className="flex items-center gap-3 text-aegis-text-dim mb-4">
            <TrendingUp className="w-4 h-4" />
            <span className="text-[10px] font-black uppercase tracking-widest">Total Value Locked</span>
          </div>
          <div className="text-3xl font-black">$45,042,120</div>
          <div className="mt-2 text-[10px] font-bold text-green-400 uppercase tracking-widest">+12.4% THIS WEEK</div>
        </div>
        <div className="glass-card p-8 rounded-[32px] border border-aegis-border/30">
          <div className="flex items-center gap-3 text-aegis-text-dim mb-4">
            <ShieldCheck className="w-4 h-4" />
            <span className="text-[10px] font-black uppercase tracking-widest">Global Reserve</span>
          </div>
          <div className="text-3xl font-black">$1,460,000</div>
          <div className="mt-2 text-[10px] font-bold text-aegis-accent uppercase tracking-widest">SECURED BY REACTIVE</div>
        </div>
        <div className="glass-card p-8 rounded-[32px] border border-aegis-border/30">
          <div className="flex items-center gap-3 text-aegis-text-dim mb-4">
            <BarChart2 className="w-4 h-4" />
            <span className="text-[10px] font-black uppercase tracking-widest">Premiums Paid</span>
          </div>
          <div className="text-3xl font-black">$42,000</div>
          <div className="mt-2 text-[10px] font-bold text-aegis-text-dim uppercase tracking-widest">LAST 24 HOURS</div>
        </div>
      </div>

      {/* Pools Table */}
      <div className="glass-card rounded-[40px] overflow-hidden border border-aegis-border/20">
        <div className="grid grid-cols-5 p-8 border-b border-aegis-border/30 text-[10px] font-black text-aegis-text-dim uppercase tracking-widest">
          <div className="col-span-2">Liquidity Pair</div>
          <div className="text-right">TVL</div>
          <div className="text-right">Reserve Depth</div>
          <div className="text-right">Underwriting APR</div>
        </div>
        <div className="divide-y divide-aegis-border/10">
          {pools.map((pool) => (
            <div key={pool.id} className="grid grid-cols-5 p-8 items-center group hover:bg-white/[0.02] transition-all cursor-pointer">
              <div className="col-span-2 flex items-center gap-4">
                <div className="flex -space-x-4">
                  <div className="w-10 h-10 rounded-full border-2 border-aegis-bg bg-white p-1 z-10 overflow-hidden">
                    <img src={pool.pair.includes("ETH") ? "https://cryptologos.cc/logos/ethereum-eth-logo.svg" : "https://cryptologos.cc/logos/wrapped-bitcoin-wbtc-logo.svg"} alt="Token0" className="w-full h-full object-contain" />
                  </div>
                  <div className="w-10 h-10 rounded-full border-2 border-aegis-bg bg-white p-1 overflow-hidden">
                    <img src={pool.pair.includes("USDC") ? "https://cryptologos.cc/logos/usd-coin-usdc-logo.svg" : pool.pair.includes("USDT") ? "https://cryptologos.cc/logos/tether-usdt-logo.svg" : "https://cryptologos.cc/logos/ethereum-eth-logo.svg"} alt="Token1" className="w-full h-full object-contain" />
                  </div>
                </div>
                <div>
                  <div className="text-lg font-black">{pool.pair}</div>
                  <div className="text-[10px] font-bold text-aegis-text-dim uppercase flex items-center gap-1">
                    v4 Hook Enabled
                    <Info className="w-3 h-3" />
                  </div>
                </div>
              </div>
              <div className="text-right font-black text-lg">{pool.totalLiquidity}</div>
              <div className="text-right flex flex-col items-end">
                <div className="font-black text-lg">{pool.insuranceReserve}</div>
                <div className="text-[9px] font-bold text-aegis-accent uppercase">Reserve Health: 98%</div>
              </div>
              <div className="text-right">
                <div className="text-xl font-black text-green-400 glow-text">{pool.apr}</div>
                <div className="text-[9px] font-bold text-aegis-text-dim uppercase">Base + Premiums</div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* LP Info Section */}
      <div className="mt-20 glass-card rounded-[40px] p-12 flex flex-col md:flex-row items-center gap-12 border border-aegis-accent/10 relative overflow-hidden">
        <div className="absolute top-0 right-0 w-64 h-64 bg-aegis-accent/5 blur-[80px] -z-10 rounded-full" />
        <div className="w-20 h-20 rounded-3xl bg-aegis-accent/10 flex items-center justify-center text-aegis-accent shrink-0">
          <Wallet className="w-10 h-10" />
        </div>
        <div className="space-y-4">
          <h3 className="text-3xl font-black tracking-tighter uppercase">Why Underwrite with Aegis?</h3>
          <p className="text-aegis-text-dim font-medium max-w-2xl leading-relaxed">
            Standard Uniswap v4 LPs only earn swap fees. Aegis LPs earn **Swap Fees + Insurance Premiums**. 
            During low-volatility periods, you collect free premiums. During high volatility, 
            Dynamic Fees increase to protect your principal.
          </p>
          <div className="flex gap-4">
            <button className="text-xs font-black uppercase tracking-widest text-aegis-accent border-b border-aegis-accent pb-1 hover:text-white hover:border-white transition-all">Learn about risk management</button>
            <button className="text-xs font-black uppercase tracking-widest text-aegis-text-dim hover:text-white transition-all">Contract Audit</button>
          </div>
        </div>
      </div>
    </main>
  )
}
