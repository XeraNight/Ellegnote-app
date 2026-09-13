'use client'

import React from 'react'
import EncoreAnimatedLogo from '@/components/common/EncoreAnimatedLogo'
import { QrCode, Search, LogOut, Sparkles } from 'lucide-react'

interface EncoreHeaderProps {
  userEmail: string
  onOpenCommandPalette: () => void
  onOpenQRCode: () => void
  onSignOut: () => void
}

export default function EncoreHeader({
  userEmail,
  onOpenCommandPalette,
  onOpenQRCode,
  onSignOut,
}: EncoreHeaderProps) {
  const dancerName = userEmail ? userEmail.split('@')[0] : 'Tanečník'

  return (
    <header className="sticky top-0 left-0 right-0 z-30 px-6 py-3 bg-[#0a0407]/75 backdrop-blur-xl border-b border-white/[0.08] shadow-[0_4px_30px_rgba(0,0,0,0.5)]">
      <div className="max-w-7xl mx-auto flex items-center justify-between">
        {/* Left: Animated Logo & App Title */}
        <div className="flex items-center gap-3.5">
          <EncoreAnimatedLogo size={42} />

          <div className="flex flex-col">
            <div className="flex items-center gap-2">
              <h1 className="text-base font-black tracking-wider text-white uppercase font-sans">
                ENCORE
              </h1>
              <span className="px-1.5 py-0.5 rounded text-[9px] font-black uppercase tracking-widest bg-[#D4AF37]/20 text-[#FFE088] border border-[#D4AF37]/40 flex items-center gap-1">
                <Sparkles className="w-2.5 h-2.5" />
                BALLROOM
              </span>
            </div>
            <p className="text-[11px] text-white/45 font-medium tracking-tight">
              Tanečný choreografický systém
            </p>
          </div>
        </div>

        {/* Center: Quick Search Trigger (Cmd+K) */}
        <button
          onClick={onOpenCommandPalette}
          className="hidden md:flex items-center gap-3 px-4 py-2 rounded-full bg-white/[0.05] hover:bg-white/[0.09] border border-white/[0.1] text-xs text-white/60 hover:text-white transition-all cursor-pointer shadow-inner"
        >
          <Search className="w-3.5 h-3.5 text-[#D4AF37]" />
          <span>Hľadať choreografiu, figúru alebo tanec...</span>
          <kbd className="px-1.5 py-0.5 rounded bg-white/10 text-[10px] font-mono text-white/50 border border-white/10">
            ⌘K
          </kbd>
        </button>

        {/* Right: Partner Sync, QR Code, Profile & Sign Out */}
        <div className="flex items-center gap-2.5">
          {/* Cloud Sync Status */}
          <div className="hidden sm:flex items-center gap-2 px-3 py-1.5 rounded-full bg-[#140b10] border border-white/[0.08] text-xs">
            <span className="w-2 h-2 rounded-full bg-emerald-400 shadow-[0_0_8px_#34d399]" />
            <span className="text-white/70 text-[11px] font-medium">Supabase Sync</span>
          </div>

          {/* QR Code Button */}
          <button
            onClick={onOpenQRCode}
            title="Otvoriť QR kód pre mobil alebo partnera"
            className="p-2 rounded-full bg-white/[0.06] hover:bg-white/[0.12] border border-white/[0.1] text-white/80 hover:text-[#FFE088] transition-colors cursor-pointer"
          >
            <QrCode className="w-4 h-4" />
          </button>

          {/* Dancer Pill */}
          <div className="flex items-center gap-2 pl-2 pr-3 py-1 rounded-full bg-gradient-to-r from-white/[0.06] to-white/[0.02] border border-white/[0.1]">
            <div className="w-6 h-6 rounded-full bg-gradient-to-br from-[#D4AF37] to-[#8C6215] flex items-center justify-center text-[10px] font-black text-black">
              {dancerName.charAt(0).toUpperCase()}
            </div>
            <span className="text-xs font-bold text-white/90 max-w-[100px] truncate">
              {dancerName}
            </span>
          </div>

          {/* Sign Out */}
          <button
            onClick={onSignOut}
            title="Odhlásiť sa"
            className="p-2 rounded-full bg-white/[0.04] hover:bg-rose-500/20 border border-white/[0.08] hover:border-rose-500/40 text-white/50 hover:text-rose-300 transition-colors cursor-pointer"
          >
            <LogOut className="w-4 h-4" />
          </button>
        </div>
      </div>
    </header>
  )
}
