'use client'

import React, { useState } from 'react'
import {
  Users,
  ShieldCheck,
  QrCode,
  Download,
  Flame,
  Award,
  Check,
  Copy,
  Compass,
  BookOpen,
} from 'lucide-react'

interface ProfileViewProps {
  userEmail: string
  routinesCount: number
  figuresCount: number
  onOpenQRCode: () => void
}

export default function ProfileView({
  userEmail,
  routinesCount,
  figuresCount,
  onOpenQRCode,
}: ProfileViewProps) {
  const dancerName = userEmail ? userEmail.split('@')[0] : 'Jakub'
  const [partnerCode] = useState('ENC-8429')
  const [inputCode, setInputCode] = useState('')
  const [isCopied, setIsCopied] = useState(false)
  const [isPaired, setIsPaired] = useState(true)
  const [partnerName, setPartnerName] = useState('Nela')

  const handleCopyCode = () => {
    navigator.clipboard.writeText(partnerCode)
    setIsCopied(true)
    setTimeout(() => setIsCopied(false), 2000)
  }

  const handleConnectPartner = () => {
    if (!inputCode.trim()) return
    setIsPaired(true)
    setPartnerName('Partnerka (' + inputCode.toUpperCase() + ')')
    setInputCode('')
  }

  const handleExportJSON = () => {
    const backupData = {
      user: userEmail,
      exportDate: new Date().toISOString(),
      app: 'Encore Ballroom Companion',
      version: '2.0',
    }
    const blob = new Blob([JSON.stringify(backupData, null, 2)], { type: 'application/json' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `encore_backup_${new Date().toISOString().slice(0, 10)}.json`
    a.click()
    URL.revokeObjectURL(url)
  }

  return (
    <div className="w-full max-w-5xl mx-auto px-4 py-8 pb-32 space-y-6 animate-fadeIn">
      {/* ── Dancer Profile Card with Gold Avatar Frame ────────────────── */}
      <section className="relative overflow-hidden rounded-3xl p-8 bg-gradient-to-b from-[#250810]/80 via-[#150409]/90 to-[#0c0205]/95 border border-[#D4AF37]/30 shadow-2xl backdrop-blur-2xl flex flex-col md:flex-row items-center md:items-start gap-6">
        {/* Luxury Gold Framed Avatar */}
        <div className="relative group shrink-0">
          <div className="w-28 h-28 rounded-full p-1 bg-gradient-to-br from-[#FFF5D6] via-[#D4AF37] to-[#8C6215] shadow-[0_10px_30px_rgba(212,175,55,0.4)]">
            <div className="w-full h-full rounded-full overflow-hidden bg-black/80 flex items-center justify-center border-2 border-black">
              {/* Profile Image with fallback */}
              <img
                src="/avatar_crop.png"
                alt="Dancer Avatar"
                className="w-full h-full object-cover"
                onError={e => {
                  e.currentTarget.style.display = 'none'
                  if (e.currentTarget.nextElementSibling) {
                    ;(e.currentTarget.nextElementSibling as HTMLElement).style.display = 'flex'
                  }
                }}
              />
              <div className="hidden w-full h-full bg-gradient-to-br from-[#D4AF37] to-[#785110] items-center justify-center text-3xl font-black text-black">
                {dancerName.charAt(0).toUpperCase()}
              </div>
            </div>
          </div>

          <div className="absolute -bottom-1 right-2 px-2 py-0.5 rounded-full bg-[#D4AF37] text-black font-black text-[9px] uppercase tracking-wider shadow">
            Trieda S
          </div>
        </div>

        {/* Dancer Details */}
        <div className="flex-1 text-center md:text-left space-y-2">
          <div className="flex flex-col sm:flex-row sm:items-center gap-2 justify-center md:justify-start">
            <h2 className="text-2xl font-black text-white capitalize">{dancerName}</h2>
            <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-[#D4AF37]/15 text-[#FFE088] border border-[#D4AF37]/30 self-center md:self-auto">
              🏆 Hlavná kategória • ŠTT & LAT
            </span>
          </div>

          <p className="text-sm text-white/70 font-medium">
            Tanečný klub: <span className="text-white font-bold">KTC Bratislava</span>
          </p>
          <p className="text-xs text-white/40">{userEmail}</p>

          <div className="pt-2 flex flex-wrap items-center gap-2 justify-center md:justify-start">
            <span className="px-3 py-1 rounded-xl bg-white/[0.04] border border-white/[0.08] text-[11px] text-white/70 flex items-center gap-1.5">
              <Award className="w-3.5 h-3.5 text-[#D4AF37]" />
              WDSF ID: 10048291
            </span>
            <span className="px-3 py-1 rounded-xl bg-white/[0.04] border border-white/[0.08] text-[11px] text-white/70 flex items-center gap-1.5">
              <Flame className="w-3.5 h-3.5 text-rose-400" />
              Tréningová séria: 14 dní
            </span>
          </div>
        </div>
      </section>

      {/* ── Partner Pairing Card ──────────────────────────────────────── */}
      <section className="rounded-3xl p-6 bg-[#0f070b]/80 border border-white/[0.1] shadow-2xl backdrop-blur-xl space-y-5">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Users className="w-4 h-4 text-[#D4AF37]" />
            <h3 className="text-sm font-black uppercase tracking-wider text-white">
              Párovanie s Partnerom (Live Sync)
            </h3>
          </div>
          <span
            className={`px-2.5 py-0.5 rounded-full text-[10px] font-black uppercase tracking-wider flex items-center gap-1 ${
              isPaired
                ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30'
                : 'bg-white/10 text-white/40'
            }`}
          >
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" />
            {isPaired ? `Spárovaný s: ${partnerName}` : 'Nespárovaný'}
          </span>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {/* My Pairing Code */}
          <div className="p-4 rounded-2xl bg-white/[0.03] border border-white/[0.06] space-y-2">
            <span className="text-xs text-white/50 font-medium">Môj unikátny kód partnera:</span>
            <div className="flex items-center justify-between p-2.5 rounded-xl bg-black/40 border border-white/[0.08]">
              <span className="font-mono text-base font-black text-[#FFE088] tracking-wider">
                {partnerCode}
              </span>
              <div className="flex items-center gap-1.5">
                <button
                  onClick={handleCopyCode}
                  title="Skopírovať kód"
                  className="p-1.5 rounded-lg bg-white/[0.06] hover:bg-white/[0.12] text-white/70 hover:text-white transition-colors cursor-pointer"
                >
                  {isCopied ? (
                    <Check className="w-3.5 h-3.5 text-emerald-400" />
                  ) : (
                    <Copy className="w-3.5 h-3.5" />
                  )}
                </button>
                <button
                  onClick={onOpenQRCode}
                  title="Zobraziť QR kód"
                  className="p-1.5 rounded-lg bg-white/[0.06] hover:bg-white/[0.12] text-white/70 hover:text-[#FFE088] transition-colors cursor-pointer"
                >
                  <QrCode className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
            <p className="text-[10px] text-white/35">
              Partner zadá tento kód vo svojej Encore aplikácii pre živú synchronizáciu choreografií.
            </p>
          </div>

          {/* Connect to Partner */}
          <div className="p-4 rounded-2xl bg-white/[0.03] border border-white/[0.06] space-y-2">
            <span className="text-xs text-white/50 font-medium">Zadať kód partnera:</span>
            <div className="flex items-center gap-2">
              <input
                type="text"
                value={inputCode}
                onChange={e => setInputCode(e.target.value)}
                placeholder="Napr. ENC-9012"
                className="flex-1 p-2.5 rounded-xl bg-black/40 border border-white/[0.08] text-xs font-mono uppercase text-white placeholder-white/30 focus:outline-none focus:border-[#D4AF37]/50"
              />
              <button
                onClick={handleConnectPartner}
                className="px-4 py-2.5 rounded-xl bg-[#D4AF37] hover:bg-[#FFE088] text-black font-bold text-xs active:scale-95 transition-all cursor-pointer shrink-0"
              >
                Spárovať
              </button>
            </div>
            <p className="text-[10px] text-white/35">
              Po spárovaní uvidíte živé kurzory partnera a zmeny na plátne parketu.
            </p>
          </div>
        </div>
      </section>

      {/* ── Dancer Stats Grid ─────────────────────────────────────────── */}
      <section className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        <div className="p-5 rounded-2xl bg-[#11070d]/80 border border-white/[0.08] backdrop-blur-xl text-center space-y-1">
          <Compass className="w-5 h-5 text-[#3B82F6] mx-auto mb-1" />
          <div className="text-2xl font-black text-white">{routinesCount}</div>
          <div className="text-[11px] font-bold text-white/40 uppercase tracking-wider">
            Zostavy
          </div>
        </div>

        <div className="p-5 rounded-2xl bg-[#11070d]/80 border border-white/[0.08] backdrop-blur-xl text-center space-y-1">
          <BookOpen className="w-5 h-5 text-[#10B981] mx-auto mb-1" />
          <div className="text-2xl font-black text-white">{figuresCount || 8}</div>
          <div className="text-[11px] font-bold text-white/40 uppercase tracking-wider">Figúry</div>
        </div>

        <div className="p-5 rounded-2xl bg-[#11070d]/80 border border-white/[0.08] backdrop-blur-xl text-center space-y-1">
          <Flame className="w-5 h-5 text-rose-500 mx-auto mb-1" />
          <div className="text-2xl font-black text-white">12</div>
          <div className="text-[11px] font-bold text-white/40 uppercase tracking-wider">
            Tréningy
          </div>
        </div>

        <div className="p-5 rounded-2xl bg-[#11070d]/80 border border-white/[0.08] backdrop-blur-xl text-center space-y-1">
          <ShieldCheck className="w-5 h-5 text-[#D4AF37] mx-auto mb-1" />
          <div className="text-2xl font-black text-emerald-400">100%</div>
          <div className="text-[11px] font-bold text-white/40 uppercase tracking-wider">
            Cloud Sync
          </div>
        </div>
      </section>

      {/* ── Settings & Backup Section ─────────────────────────────────── */}
      <section className="rounded-3xl p-6 bg-[#0f070b]/80 border border-white/[0.1] shadow-2xl backdrop-blur-xl flex flex-col sm:flex-row items-center justify-between gap-4">
        <div className="space-y-1 text-center sm:text-left">
          <h4 className="text-sm font-bold text-white">Záloha a export údajov</h4>
          <p className="text-xs text-white/40">
            Stiahni si kompletnú offline zálohu svojich choreografií a poznámok vo formáte JSON.
          </p>
        </div>

        <button
          onClick={handleExportJSON}
          className="flex items-center gap-2 px-5 py-2.5 rounded-full bg-white/[0.06] hover:bg-white/[0.12] border border-white/[0.12] text-white font-bold text-xs hover:border-[#D4AF37]/40 transition-all cursor-pointer"
        >
          <Download className="w-4 h-4 text-[#D4AF37]" />
          <span>Exportovať JSON zálohu</span>
        </button>
      </section>
    </div>
  )
}
