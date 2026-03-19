'use client'
import { Activity, ExternalLink } from "lucide-react"
import { formatUnits } from "viem"
import { useRecentTrades } from "@/lib/hooks/useAegis"

function timeAgo(timestamp: number) {
  const diff = Math.floor(Date.now() / 1000) - timestamp
  if (diff < 60) return `${diff}s ago`
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`
  return `${Math.floor(diff / 3600)}h ago`
}

export default function RecentTrades() {
  const trades = useRecentTrades()

  return (
    <div className="space-y-4">
      <h2 className="text-xl font-black uppercase tracking-tight flex items-center gap-3">
        <Activity className="w-5 h-5 text-aegis-accent" />
        Recent Trades
      </h2>
      <div className="glass-card rounded-[40px] border border-aegis-border/20 overflow-hidden">
        <div className="grid grid-cols-3 p-6 border-b border-aegis-border/30 text-[10px] font-black text-aegis-text-dim uppercase tracking-widest">
          <div>Amount</div>
          <div className="text-center">Premium</div>
          <div className="text-right">Time</div>
        </div>
        <div className="divide-y divide-aegis-border/10">
          {trades.length === 0 ? (
            <div className="p-6 text-center text-aegis-text-dim text-[11px] font-bold">No recent trades</div>
          ) : (
            trades.map((t) => (
              <div key={t.txHash} className="grid grid-cols-3 px-6 py-4 items-center hover:bg-white/[0.01] transition-all">
                <div className="font-black text-sm">{Number(formatUnits(t.amount, 18)).toFixed(4)} mWETH</div>
                <div className="text-center text-[11px] font-bold text-aegis-accent">
                  {Number(formatUnits(t.premium, 18)).toFixed(6)} mWETH
                </div>
                <div className="text-right flex items-center justify-end gap-2">
                  <span className="text-[10px] font-bold text-aegis-text-dim">{timeAgo(t.timestamp)}</span>
                  <a href={`https://sepolia.uniscan.xyz/tx/${t.txHash}`} target="_blank" rel="noreferrer">
                    <ExternalLink className="w-3 h-3 text-aegis-text-dim hover:text-white" />
                  </a>
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  )
}
