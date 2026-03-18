'use client'
import { History, ShieldAlert, CheckCircle2, Search, ExternalLink, Zap } from "lucide-react"
import { useState, useEffect } from "react"
import { usePrivy } from "@privy-io/react-auth"
import { formatUnits } from "viem"
import { useNextClaimId, useClaim, useSettleClaim, useReserveBalance } from "@/lib/hooks/useAegis"
import { AEGIS_CONTRACTS } from "@/lib/contracts"

// Reads a single claim and renders a row
function ClaimRow({ claimId, userAddress, onSettle }: {
  claimId: bigint
  userAddress: string
  onSettle: (id: bigint) => void
}) {
  const { data } = useClaim(claimId)
  if (!data) return null
  const [swapper, token, amount, settled, timestamp] = data as [string, string, bigint, boolean, bigint]
  if (swapper.toLowerCase() !== userAddress.toLowerCase()) return null

  const isUSDC = token.toLowerCase() === AEGIS_CONTRACTS.mUSDC.toLowerCase()
  const formatted = formatUnits(amount, 18)
  const symbol = isUSDC ? 'mUSDC' : 'mWETH'
  const date = new Date(Number(timestamp) * 1000).toLocaleDateString()

  return (
    <div className="grid grid-cols-5 p-8 items-center group hover:bg-white/[0.01] transition-all">
      <div className="col-span-2 flex items-center gap-4">
        <div className="w-12 h-12 rounded-2xl bg-white/5 flex items-center justify-center border border-aegis-border p-2">
          <Zap className={`w-6 h-6 ${settled ? 'text-green-400' : 'text-aegis-accent animate-pulse'}`} />
        </div>
        <div>
          <div className="font-black text-lg">mWETH / mUSDC</div>
          <div className="text-[10px] font-bold text-aegis-text-dim uppercase">{date} • ID: CL-{claimId.toString()}</div>
        </div>
      </div>
      <div className="text-right font-black text-lg">{formatted} {symbol}</div>
      <div className="text-right">
        <span className={`px-3 py-1 rounded-full text-[9px] font-black uppercase tracking-widest ${settled ? "bg-green-500/10 text-green-400" : "bg-aegis-accent/10 text-aegis-accent"}`}>
          {settled ? "Settled" : "Ready to Claim"}
        </span>
      </div>
      <div className="text-right">
        {settled ? (
          <a href={`https://sepolia.uniscan.xyz/address/${AEGIS_CONTRACTS.RESERVE}`} target="_blank" rel="noreferrer">
            <ExternalLink className="w-5 h-5 ml-auto text-aegis-text-dim hover:text-white" />
          </a>
        ) : (
          <button
            onClick={() => onSettle(claimId)}
            className="px-6 py-2 rounded-xl accent-gradient text-black font-black text-[10px] glow-accent transition-all hover:scale-105"
          >
            SETTLE NOW
          </button>
        )}
      </div>
    </div>
  )
}

export default function ClaimsDashboard() {
  const { user } = usePrivy()
  const address = user?.wallet?.address ?? ""
  const { data: nextClaimId } = useNextClaimId()
  const { settle, isPending } = useSettleClaim()
  const { data: mWETHReserve } = useReserveBalance(AEGIS_CONTRACTS.mWETH)
  const { data: mUSDCReserve } = useReserveBalance(AEGIS_CONTRACTS.mUSDC)

  const claimIds = nextClaimId
    ? Array.from({ length: Number(nextClaimId) }, (_, i) => BigInt(i))
    : []

  return (
    <main className="max-w-[1200px] mx-auto px-6 py-16">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6 mb-12">
        <div>
          <h1 className="text-4xl font-black mb-2 tracking-tighter uppercase underline decoration-amber-500 decoration-4 underline-offset-8">Insurance Dashboard</h1>
          <p className="text-aegis-text-dim font-bold text-sm uppercase tracking-widest">Track your protection history and settle deferred claims.</p>
        </div>
        <div className="relative group">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-aegis-text-dim" />
          <input type="text" placeholder="Search claim ID..." className="pl-12 pr-6 py-4 rounded-2xl bg-white/5 border border-aegis-border focus:border-aegis-accent outline-none transition-all w-[300px] text-sm font-bold" />
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
              {!address ? (
                <div className="p-8 text-center text-aegis-text-dim text-sm font-bold">Connect wallet to view claims</div>
              ) : claimIds.length === 0 ? (
                <div className="p-8 text-center text-aegis-text-dim text-sm font-bold">No claims found</div>
              ) : (
                claimIds.map(id => (
                  <ClaimRow key={id.toString()} claimId={id} userAddress={address} onSettle={settle} />
                ))
              )}
            </div>
          </div>
        </div>

        <div className="space-y-8">
          <h2 className="text-xl font-black uppercase tracking-tight flex items-center gap-3">
            <ShieldAlert className="w-5 h-5 text-amber-500" />
            Reserve Health
          </h2>
          <div className="glass-card p-8 rounded-[40px] border border-aegis-border/20">
            <h3 className="font-black text-white text-sm uppercase mb-6">Live Reserve Balances</h3>
            <div className="space-y-4">
              <div className="flex justify-between text-[10px] font-bold uppercase">
                <span className="text-aegis-text-dim">mWETH Reserve</span>
                <span className="text-white">{mWETHReserve ? formatUnits(mWETHReserve as bigint, 18) : '...'} mWETH</span>
              </div>
              <div className="flex justify-between text-[10px] font-bold uppercase">
                <span className="text-aegis-text-dim">mUSDC Reserve</span>
                <span className="text-white">{mUSDCReserve ? formatUnits(mUSDCReserve as bigint, 18) : '...'} mUSDC</span>
              </div>
            </div>
            <div className="mt-6 pt-6 border-t border-aegis-border/10">
              <a href={`https://sepolia.uniscan.xyz/address/${AEGIS_CONTRACTS.RESERVE}`} target="_blank" rel="noreferrer"
                className="text-[10px] font-black text-aegis-accent uppercase tracking-widest flex items-center gap-1 hover:underline">
                View on Uniscan <ExternalLink className="w-3 h-3" />
              </a>
            </div>
          </div>
        </div>
      </div>
    </main>
  )
}
