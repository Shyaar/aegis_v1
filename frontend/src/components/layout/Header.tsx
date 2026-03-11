"use client"

import { ShieldCheck } from "lucide-react"
import Link from "next/link"
import { usePathname } from "next/navigation"

export default function Header() {
  const pathname = usePathname()

  const tabs = [
    { name: "Landing", href: "/landing" },
    { name: "Swap", href: "/swap" },
    { name: "Pools", href: "/pools" },
    { name: "Claims", href: "/claims" },
  ]

  return (
    <nav className="flex items-center justify-between px-8 py-4 border-b border-aegis-border bg-aegis-bg/60 backdrop-blur-xl sticky top-0 z-50">
      <div className="flex items-center gap-10">
        <Link href="/landing" className="flex items-center gap-2 group cursor-pointer">
          <div className="w-10 h-10 accent-gradient rounded-xl flex items-center justify-center glow-accent transition-transform group-hover:scale-105">
            <ShieldCheck className="text-white w-6 h-6" />
          </div>
          <span className="text-2xl font-black tracking-tighter glow-text">AEGIS</span>
        </Link>

        <div className="hidden lg:flex items-center gap-8 text-[13px] font-bold uppercase tracking-widest text-aegis-text-dim">
          {tabs.map((tab) => (
            <Link
              key={tab.name}
              href={tab.href}
              className={`transition-all hover:text-aegis-accent relative py-2 ${
                pathname === tab.href ? "text-aegis-accent" : ""
              }`}
            >
              {tab.name}
              {pathname === tab.href && (
                <div className="absolute -bottom-1 left-0 right-0 h-0.5 bg-aegis-accent glow-accent rounded-full" />
              )}
            </Link>
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
  )
}
