"use client"

import { X } from "lucide-react"
import { useEffect, useState } from "react"

interface ModalProps {
  isOpen: boolean
  onClose: () => void
  title: string
  children: React.ReactNode
}

export default function Modal({ isOpen, onClose, title, children }: ModalProps) {
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
    if (isOpen) {
      document.body.style.overflow = "hidden"
    } else {
      document.body.style.overflow = "unset"
    }
    return () => {
      document.body.style.overflow = "unset"
    }
  }, [isOpen])

  if (!mounted || !isOpen) return null

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center px-4">
      <div 
        className="absolute inset-0 bg-black/80 backdrop-blur-md animate-in fade-in duration-300"
        onClick={onClose}
      />
      <div className="glass-card w-full max-w-[480px] rounded-[40px] border border-aegis-border p-8 relative animate-in zoom-in-95 duration-300">
        <div className="flex justify-between items-center mb-8">
          <h3 className="text-xl font-black uppercase tracking-tight">{title}</h3>
          <button 
            onClick={onClose}
            className="p-2 rounded-xl hover:bg-white/5 transition-colors text-aegis-text-dim hover:text-white"
          >
            <X className="w-6 h-6" />
          </button>
        </div>
        
        {children}
      </div>
    </div>
  )
}
