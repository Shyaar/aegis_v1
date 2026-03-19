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
import { useCoins } from "../coins/fetchCoin"
import { usePrivy } from "@privy-io/react-auth"
import { useAegisPremium, useMovingAverageGasPrice, useTokenBalance, useApproveToken, useProtectedSwap } from "@/lib/hooks/useAegis"
import { parseUnits, formatUnits, maxUint256 } from "viem"
import { AEGIS_CONTRACTS } from "@/lib/contracts"
import toast from "react-hot-toast"

export default function SwapCard({ activeTab = "Swap" }: { activeTab?: string }) {
  // Placeholders for Privy/Blockchain integration
  let isConnected = false
  let address = ""

  const { ready, authenticated, user, logout } = usePrivy();

  // helper to shorten wallet
  if (user?.wallet?.address) {
    isConnected = true;
    address = user?.wallet?.address
  }


  const MWETH_PRICE = 2000 // 1 mWETH = 2000 mUSDC (pool starting price)
  const [isInsured, setIsInsured] = useState(true)
  const [sellAmount, setSellAmount] = useState("0.1")
  const [buyAmount, setBuyAmount] = useState(String(0.1 * MWETH_PRICE))
  const [limitPrice, setLimitPrice] = useState("2000.00")
  const [sellSymbol, setSellSymbol] = useState("mWETH")
  const [buySymbol, setBuySymbol] = useState("mUSDC")
  const [coverageTier, setCoverageTier] = useState(1) // Default: Basic (1), not None (0)

  const { getCoinBySymbol, loading } = useCoins()
  const sellCoin = getCoinBySymbol(sellSymbol)
  const buyCoin = getCoinBySymbol(buySymbol)

  const sellDecimals = sellSymbol === "mWETH" ? 18 : 6

  // Aegis Contract Integration
  const { approve } = useApproveToken()
  const { swap, isPending: isSwapping } = useProtectedSwap()

  // Aegis Contract Integration
  const { data: premiumAmountData, isLoading: isPremiumLoading } = useAegisPremium({
    swapSize: parseUnits(sellAmount || "0", sellDecimals),
    poolLiquidity: BigInt(1000000) * BigInt(10 ** 18),
    baseFee: 3000,
    volatilitySignal: BigInt(100),
    tier: coverageTier,
  });

  const premiumAmount = premiumAmountData;
  const { data: movingAverageGas } = useMovingAverageGasPrice();
  const { data: sellBalance } = useTokenBalance(
    sellSymbol === "mWETH" ? AEGIS_CONTRACTS.mWETH : AEGIS_CONTRACTS.mUSDC,
    address as `0x${string}` | undefined
  );

  const handleSellAmountChange = (val: string) => {
    setSellAmount(val)
    if (!val || isNaN(Number(val))) { setBuyAmount(""); return }
    const amount = Number(val)
    setBuyAmount(sellSymbol === "mWETH"
      ? (amount * MWETH_PRICE).toFixed(2)
      : (amount / MWETH_PRICE).toFixed(6))
  }

  const handleBuyAmountChange = (val: string) => {
    setBuyAmount(val)
    if (!val || isNaN(Number(val))) { setSellAmount(""); return }
    const amount = Number(val)
    setSellAmount(buySymbol === "mWETH"
      ? (amount * MWETH_PRICE).toFixed(2)
      : (amount / MWETH_PRICE).toFixed(6))
  }

  const toggleTokens = () => {
    setSellSymbol(buySymbol)
    setBuySymbol(sellSymbol)
    const amount = Number(sellAmount)
    if (!isNaN(amount)) {
      setBuyAmount(buySymbol === "mWETH"
        ? (amount * MWETH_PRICE).toFixed(2)
        : (amount / MWETH_PRICE).toFixed(6))
    }
  }

  const handleProtectedSwap = async () => {
    if (!isConnected) return
    const toastId = toast.loading("Preparing swap...")
    try {
      // currency0=mUSDC, currency1=mWETH
      // zeroForOne=true  → selling mUSDC (currency0) for mWETH (currency1)
      // zeroForOne=false → selling mWETH (currency1) for mUSDC (currency0)
      const zeroForOne = sellSymbol === "mUSDC"
      const sellToken = sellSymbol === "mWETH" ? AEGIS_CONTRACTS.mWETH : AEGIS_CONTRACTS.mUSDC
      const decimals = sellSymbol === "mWETH" ? 18 : 6
      const amount = parseUnits(sellAmount || "0", decimals)

      // approve PoolSwapTest and Hook to spend sell token (hook pulls premium)
      toast.loading("Approving tokens...", { id: toastId })
      await approve(sellToken, AEGIS_CONTRACTS.POOL_SWAP_TEST, maxUint256)
      await approve(sellToken, AEGIS_CONTRACTS.HOOK, maxUint256)

      // execute swap through Aegis hook
      toast.loading("Executing swap...", { id: toastId })
      await swap(amount, zeroForOne, coverageTier)
      toast.success("Swap successful!", { id: toastId })
    } catch (e: any) {
      console.error("Swap failed:", e?.message ?? e)
      toast.error(e?.shortMessage || e?.message || "Swap failed", { id: toastId })
    }
  }

  const isBuyOrSell = activeTab === "Buy" || activeTab === "Sell"

  return (
    <div className="w-full max-w-[520px] relative">
      {/* Background Glows */}
      <div className="absolute -top-20 -left-20 w-64 h-64 bg-aegis-accent/10 blur-[100px] rounded-full" />
      <div className="absolute -bottom-20 -right-20 w-64 h-64 bg-blue-600/10 blur-[100px] rounded-full" />

      {/* Swap Area  */}
      <div className="relative glass-card rounded-[40px] p-8  overflow-hidden space-y-6">
        {/* Main Swap Card */}
        <div className="relative space-y-2 ">
          <div className="flex justify-between items-center px-1">
            <div className="flex flex-col">
              <h2 className="text-xl font-black tracking-tight uppercase">Aegis {activeTab}</h2>
              {movingAverageGas && (
                <span className="text-[9px] font-bold text-aegis-accent/60 uppercase tracking-widest mt-1">
                  Net Gas Average: {formatUnits(movingAverageGas, 9)} Gwei
                </span>
              )}
            </div>
          </div>

          <div className="bg-black/50 rounded-3xl p-6 border border-aegis-border group hover:border-white/10 transition-all">
            <div className="flex justify-between items-center mb-4">
              <span className="text-[10px] font-black text-aegis-text-dim uppercase tracking-widest">
                {activeTab === "Buy" ? "You Pay" : activeTab === "Sell" ? "You Sell" : "You Sell"}
              </span>
              <span className="text-[10px] font-bold text-aegis-text-dim uppercase">Balance: {sellBalance ? Number(formatUnits(sellBalance as bigint, sellDecimals)).toFixed(2) : '0.00'} {sellSymbol}</span>

            </div>
            <div className="flex justify-between items-center gap-4">
              <input
                type="number"
                value={sellAmount}
                onChange={(e) => handleSellAmountChange(e.target.value)}
                className="w-0 flex-1 bg-transparent text-4xl font-black outline-none placeholder:text-white/10"
                placeholder="0.0"
              />
              {!isBuyOrSell ? (
                <div className="flex items-center gap-2 bg-white/5 hover:bg-white/10 px-4 py-2.5 rounded-full cursor-pointer border border-aegis-border transition-all shrink-0 min-w-[120px] justify-center">
                  {sellCoin ? (
                    <img src={sellCoin.image} alt={sellCoin.symbol} className="w-6 h-6 rounded-full" />
                  ) : (
                    <div className="w-6 h-6 bg-white/10 rounded-full animate-pulse" />
                  )}
                  <span className="font-black text-lg">{sellCoin?.symbol || sellSymbol}</span>
                </div>

              ) : (
                <div className="flex items-center gap-2 bg-white/5 px-4 py-2.5 rounded-2xl border border-aegis-border text-aegis-text-dim font-black shrink-0">
                  {activeTab === "Buy" ? (
                    getCoinBySymbol("USDC") ? (
                      <img src={getCoinBySymbol("USDC")?.image} alt="USDC" className="w-6 h-6 rounded-full" />
                    ) : (
                      <div className="w-6 h-6 bg-white/10 rounded-full animate-pulse" />
                    )
                  ) : sellCoin ? (
                    <img src={sellCoin.image} alt={sellCoin.symbol} className="w-6 h-6 rounded-full" />
                  ) : (
                    <div className="w-6 h-6 bg-white/10 rounded-full animate-pulse" />
                  )}
                  {activeTab === "Buy" ? "USDC" : sellSymbol}
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
                <span className="text-sm font-black text-aegis-text-dim whitespace-nowrap">{buySymbol} per {sellSymbol}</span>

              </div>
            </div>
          )}

          {/* Switch Divider (Only for Swap and Limit) */}
          {!isBuyOrSell && (
            <div className="absolute h-2 flex items-center justify-center left-[45%] top-[50%] z-10">
              <div className="absolute w-full h-px bg-aegis-border" />
              <button
                onClick={toggleTokens}
                className="w-12 h-12 glass-card rounded-2xl flex items-center justify-center border border-aegis-border hover:scale-110 transition-transform bg-aegis-bg"
              >
                <ArrowDownUp className="w-6 h-6 text-aegis-accent" />
              </button>
            </div>
          )}

          {/* Output Token (Only for Swap and Limit) */}
          {!isBuyOrSell && (
            <div className={`bg-black/50 rounded-3xl p-6 border border-aegis-border group hover:border-white/10 transition-all ${activeTab === 'Limit' ? '' : 'pt-10'}`}>
              <div className="flex justify-between items-center mb-4">
                <span className="text-[10px] font-black text-aegis-text-dim uppercase tracking-widest">You Get</span>
              </div>
              <div className="flex justify-between items-center gap-4">
                <input
                  type="number"
                  value={buyAmount}
                  onChange={(e) => handleBuyAmountChange(e.target.value)}
                  className="w-0 flex-1 bg-transparent text-4xl font-black outline-none placeholder:text-white/10"
                  placeholder="0.0"
                />
                <div className="flex items-center gap-2 bg-white/5 hover:bg-white/10 px-4 py-2.5 rounded-full cursor-pointer border border-aegis-border transition-all shrink-0 min-w-[120px] justify-center">
                  {buyCoin ? (
                    <img src={buyCoin.image} alt={buyCoin.symbol} className="w-6 h-6 rounded-full" />
                  ) : (
                    <div className="w-6 h-6 bg-white/10 rounded-full animate-pulse" />
                  )}
                  <span className="font-black text-lg">{buyCoin?.symbol || buySymbol}</span>
                </div>

              </div>
            </div>
          )}

        </div>
        {/* Aegis Protection Tooltip/Toggle (Only for Swap for now) */}
        {activeTab === "Swap" && (
          <div
            className={`p-6 rounded-[28px] border transition-all relative group ${isInsured
              ? "bg-aegis-accent/5 border-aegis-accent/20"
              : "bg-white/[0.02] border-aegis-border hover:bg-white/[0.04]"
              }`}
          >
            {/* Header row — clicking this toggles insurance */}
            <div className="flex items-start justify-between cursor-pointer" onClick={() => setIsInsured(!isInsured)}>
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
                    {isInsured ? "PROTECTED" : "UNPROTECTED"}
                  </p>
                </div>
              </div>
              <div className={`w-14 h-7 rounded-full relative transition-all duration-300 ${isInsured ? "bg-aegis-accent glow-accent" : "bg-white/10"}`}>
                <div className={`absolute top-1 w-5 h-5 rounded-full bg-white transition-all duration-300 shadow-md ${isInsured ? "left-8" : "left-1"}`} />
              </div>
            </div>

            {isInsured && (
              <div className="mt-5 pt-5 border-t border-aegis-accent/10 space-y-4 animate-in fade-in slide-in-from-top-2 duration-500">
                {/* Tier selector */}
                <div className="grid grid-cols-3 gap-2">
                  {([
                    { label: "BASIC", value: 1, trigger: "1%", bps: "5bps" },
                    { label: "STANDARD", value: 2, trigger: "0.5%", bps: "10bps" },
                    { label: "PREMIUM", value: 3, trigger: "0.2%", bps: "20bps" },
                  ] as const).map((tier) => (
                    <button
                      key={tier.value}
                      onClick={() => setCoverageTier(tier.value)}
                      className={`flex flex-col items-center py-3 px-2 rounded-2xl border transition-all ${coverageTier === tier.value
                          ? "bg-aegis-accent/20 border-aegis-accent text-aegis-accent"
                          : "bg-white/[0.03] border-aegis-border text-aegis-text-dim hover:border-white/20"
                        }`}
                    >
                      <span className="text-[9px] font-black uppercase tracking-widest">{tier.label}</span>
                      <span className="text-[8px] font-bold mt-1 opacity-70">triggers &gt; {tier.trigger}</span>
                      <span className="text-[8px] font-bold opacity-50">{tier.bps} premium</span>
                    </button>
                  ))}
                </div>

                {/* Premium + payout info */}
                <div className="space-y-2">
                  <div className="flex justify-between items-center text-[10px] font-black uppercase tracking-widest">
                    <span className="text-aegis-text-dim">Insurance Premium</span>
                    <span className="text-aegis-accent">
                      {isPremiumLoading
                        ? "..."
                        : premiumAmountData !== undefined
                          ? `${formatUnits(premiumAmountData, sellDecimals)} ${sellSymbol}`
                          : "—"}
                    </span>
                  </div>
                  <div className="flex justify-between items-center text-[10px] font-black uppercase tracking-widest">
                    <span className="text-aegis-text-dim">Total You Pay</span>
                    <span className="text-white">
                      {premiumAmountData !== undefined
                        ? `${formatUnits(
                          parseUnits(sellAmount || "0", sellDecimals) + premiumAmountData,
                          sellDecimals
                        )} ${sellSymbol}`
                        : "—"}
                    </span>
                  </div>
                  <div className="flex justify-between items-center text-[10px] font-black uppercase tracking-widest">
                    <span className="text-aegis-text-dim">Payout Trigger</span>
                    <span className="text-green-400">
                      {coverageTier === 1 ? "> 1%" : coverageTier === 2 ? "> 0.5%" : "> 0.2%"} slippage
                    </span>
                  </div>
                </div>
              </div>
            )}
          </div>
        )}

        {/* Confirm Button */}
        <button
          onClick={handleProtectedSwap}
          disabled={!isConnected}
          className={`w-full py-5 rounded-[32px] accent-gradient text-black font-black text-lg glow-accent hover:opacity-90 active:scale-[0.99] transition-all flex items-center justify-center gap-3 ${(!isConnected || isSwapping) ? "opacity-30 cursor-not-allowed grayscale" : ""}`}
        >
          {!isConnected ? "CONNECT WALLET TO SWAP" : isSwapping ? "SWAPPING..." : (
            <>
              {activeTab === "Swap" && isInsured && <Zap className="w-5 h-5 fill-current" />}
              {activeTab === "Swap" ? (isInsured ? "PROTECTED SWAP" : "SWAP WITHOUT COVERAGE") :
                activeTab === "Limit" ? "PLACE LIMIT ORDER" :
                  activeTab === "Buy" ? "BUY WITH CARD" :
                    "SELL TO CARD / BANK"}
            </>
          )}
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
