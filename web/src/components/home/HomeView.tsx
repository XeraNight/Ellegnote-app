'use client'

import React, { useState, useEffect } from 'react'
import {
  Mic,
  Send,
  Sparkles,
  Play,
  Compass,
  Video,
  BookOpen,
  PlusCircle,
  Clock,
  Flame,
  CheckCircle2,
} from 'lucide-react'
import { RoutineInfo } from '@/components/RealtimeCanvas'
import EncoreAnimatedLogo from '@/components/common/EncoreAnimatedLogo'
import { DropletIcon } from '@/components/icons/DropletIcon'
import { FlameIcon as AnimatedFlameIcon } from '@/components/icons/FlameIcon'

interface HomeViewProps {
  routines: RoutineInfo[]
  userEmail: string
  onOpenRoutine: (routine: RoutineInfo) => void
  onNavigateTab: (tab: 'canvas' | 'studio' | 'library' | 'profile') => void
  onCreateRoutine: () => void
}

const DANCE_TAGS = [
  '#Držanie',
  '#Rytmus',
  '#Waltz',
  '#Rumba',
  '#Sway',
  '#Rotácia',
  '#Nášľap',
  '#Dynamika',
]

export default function HomeView({
  routines,
  userEmail,
  onOpenRoutine,
  onNavigateTab,
  onCreateRoutine,
}: HomeViewProps) {
  const [quickNote, setQuickNote] = useState('')
  const [isRecording, setIsRecording] = useState(false)
  const [waveformBars, setWaveformBars] = useState<number[]>([40, 65, 30, 80, 55, 90, 45, 70])
  const [savedNotes, setSavedNotes] = useState<
    { id: string; text: string; time: string; tag?: string }[]
  >([
    {
      id: '1',
      text: 'V Tangu udržať pevný rám v Promenade Link a ostrý nášľap na päty.',
      time: 'Pred 20 min',
      tag: '#Tango',
    },
    {
      id: '2',
      text: 'V Slowfoxe predĺžiť feather step a nezastavovať rotáciu v tele.',
      time: 'Včera',
      tag: '#Slowfox',
    },
  ])

  // Simulate dancing audio waveforms when recording
  useEffect(() => {
    if (!isRecording) return
    const interval = setInterval(() => {
      setWaveformBars(Array.from({ length: 12 }, () => Math.floor(Math.random() * 65) + 25))
    }, 120)
    return () => clearInterval(interval)
  }, [isRecording])

  const handleSaveNote = () => {
    if (!quickNote.trim()) return
    const newEntry = {
      id: Date.now().toString(),
      text: quickNote.trim(),
      time: 'Práve teraz',
    }
    setSavedNotes([newEntry, ...savedNotes])
    setQuickNote('')
  }

  const handleAddTag = (tag: string) => {
    setQuickNote(prev => (prev ? `${prev} ${tag}` : tag))
  }

  const recentRoutine = routines[0] || null

  return (
    <div className="w-full max-w-5xl mx-auto px-4 py-8 pb-32 space-y-8 animate-fadeIn">
      {/* ── 1. Hero Welcome & Logo Duet Showcase ────────────────────────── */}
      <section className="relative overflow-hidden rounded-3xl p-8 bg-gradient-to-b from-[#2a060e]/80 via-[#180308]/90 to-[#0c0205]/95 border border-[#D4AF37]/30 shadow-[0_25px_60px_rgba(0,0,0,0.7)] backdrop-blur-2xl flex flex-col md:flex-row items-center justify-between gap-6">
        <div className="space-y-2.5 text-center md:text-left z-10">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#D4AF37]/15 border border-[#D4AF37]/30 text-[#FFE088] text-xs font-black uppercase tracking-widest">
            <Sparkles className="w-3.5 h-3.5" />
            Tréningové Štúdio & Plátno
          </div>
          <h2 className="text-3xl sm:text-4xl font-black text-white tracking-tight">
            Vitaj na parkete,{' '}
            <span className="bg-gradient-to-r from-[#FFF5D6] via-[#D4AF37] to-[#FFE088] bg-clip-text text-transparent">
              {userEmail ? userEmail.split('@')[0] : 'Tanečník'}
            </span>
          </h2>
          <p className="text-white/60 text-sm max-w-md font-medium">
            Vytváraj a synchronizuj choreografie na 2:3 parkete so zlatými stenami v reálnom čase s
            partnerom.
          </p>
        </div>

        {/* Animated Duet Logo */}
        <div className="flex flex-col items-center justify-center p-4 rounded-2xl bg-white/[0.03] border border-white/[0.08] shadow-inner">
          <EncoreAnimatedLogo size={80} showHint={true} />
        </div>
      </section>

      {/* ── 2. Typewriter Quick Capture & Voice Dictation ───────────────── */}
      <section className="rounded-3xl p-6 bg-[#0f070b]/80 border border-white/[0.1] shadow-2xl backdrop-blur-xl space-y-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="w-2.5 h-2.5 rounded-full bg-[#D4AF37]" />
            <h3 className="text-sm font-black uppercase tracking-wider text-white">
              Rýchly tanečný záznam (Typewriter)
            </h3>
          </div>
          <span className="text-[11px] text-white/40 font-medium">Automatické ukladanie</span>
        </div>

        <div className="relative">
          <textarea
            value={quickNote}
            onChange={e => setQuickNote(e.target.value)}
            onKeyDown={e => {
              if (e.key === 'Enter' && (e.metaKey || e.ctrlKey)) {
                handleSaveNote()
              }
            }}
            placeholder="Zapíš si rýchlu poznámku z tréningu, pripomienku trénera alebo opravu držania..."
            className="w-full h-24 p-4 rounded-2xl bg-white/[0.03] border border-white/[0.08] focus:border-[#D4AF37]/60 focus:bg-white/[0.05] text-white placeholder-white/30 text-sm resize-none outline-none transition-all font-mono leading-relaxed"
          />

          <div className="absolute bottom-3 right-3 flex items-center gap-2">
            {/* Voice Dictation Simulator */}
            <button
              onClick={() => setIsRecording(!isRecording)}
              title={isRecording ? 'Zastaviť nahrávanie' : 'Diktovať hlasom'}
              className={`p-2 rounded-xl transition-all cursor-pointer ${
                isRecording
                  ? 'bg-rose-600 text-white animate-pulse shadow-[0_0_15px_#e11d48]'
                  : 'bg-white/[0.06] hover:bg-white/[0.12] text-white/70 hover:text-white'
              }`}
            >
              <Mic className="w-4 h-4" />
            </button>

            {/* Send / Save Note */}
            <button
              onClick={handleSaveNote}
              disabled={!quickNote.trim()}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-gradient-to-r from-[#D4AF37] to-[#B8861E] text-black font-bold text-xs hover:brightness-110 active:scale-95 transition-all disabled:opacity-30 disabled:pointer-events-none cursor-pointer shadow-[0_2px_12px_rgba(212,175,55,0.4)]"
            >
              <Send className="w-3.5 h-3.5" />
              <span>Uložiť</span>
            </button>
          </div>
        </div>

        {/* Dancing Waveform display if recording */}
        {isRecording && (
          <div className="flex items-center gap-1.5 p-3 rounded-xl bg-rose-950/40 border border-rose-500/30">
            <span className="text-xs font-bold text-rose-400 mr-2">Počúvam...</span>
            <div className="flex items-center gap-1 h-6">
              {waveformBars.map((height, i) => (
                <div
                  key={i}
                  className="w-1 bg-rose-400 rounded-full transition-all duration-100"
                  style={{ height: `${height}%` }}
                />
              ))}
            </div>
          </div>
        )}

        {/* Quick Dance Tags */}
        <div className="flex items-center gap-1.5 flex-wrap pt-1">
          <span className="text-[11px] font-bold text-white/40 mr-1">Štítky:</span>
          {DANCE_TAGS.map(tag => (
            <button
              key={tag}
              onClick={() => handleAddTag(tag)}
              className="px-2.5 py-1 rounded-lg bg-white/[0.04] hover:bg-[#D4AF37]/20 border border-white/[0.08] hover:border-[#D4AF37]/40 text-white/70 hover:text-[#FFE088] text-[11px] font-medium transition-all cursor-pointer"
            >
              {tag}
            </button>
          ))}
        </div>

        {/* Saved notes preview */}
        {savedNotes.length > 0 && (
          <div className="pt-2 space-y-2 border-t border-white/[0.06]">
            {savedNotes.slice(0, 2).map(n => (
              <div
                key={n.id}
                className="flex items-start justify-between p-3 rounded-xl bg-white/[0.02] border border-white/[0.05] text-xs text-white/80"
              >
                <div className="flex items-start gap-2">
                  <CheckCircle2 className="w-3.5 h-3.5 text-[#D4AF37] mt-0.5 shrink-0" />
                  <span>{n.text}</span>
                </div>
                <span className="text-[10px] text-white/30 shrink-0 ml-3">{n.time}</span>
              </div>
            ))}
          </div>
        )}
      </section>

      {/* ── 3. Quick Action Luxury Cards (4 Grid) ───────────────────────── */}
      <section className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Card 1: Nová Zostava */}
        <div
          onClick={onCreateRoutine}
          className="group p-5 rounded-2xl bg-gradient-to-b from-[#180d14]/90 to-[#0e070c]/90 border border-white/[0.1] hover:border-[#D4AF37]/50 shadow-lg hover:shadow-[0_10px_30px_rgba(212,175,55,0.15)] transition-all cursor-pointer flex flex-col justify-between h-44 relative overflow-hidden"
        >
          <div className="w-10 h-10 rounded-xl bg-[#D4AF37]/15 border border-[#D4AF37]/30 flex items-center justify-center text-[#FFE088] group-hover:scale-110 transition-transform">
            <PlusCircle className="w-5 h-5" />
          </div>
          <div>
            <h4 className="text-sm font-black text-white group-hover:text-[#FFE088] transition-colors">
              Nová Choreografia
            </h4>
            <p className="text-[11px] text-white/50 mt-1">
              Vytvor novú zostavu pre štandard alebo latinu.
            </p>
          </div>
          <span className="text-[10px] font-bold text-[#D4AF37] uppercase tracking-wider">
            + Vytvoriť zostavu
          </span>
        </div>

        {/* Card 2: Realtime Canvas */}
        <div
          onClick={() => onNavigateTab('canvas')}
          className="group p-5 rounded-2xl bg-gradient-to-b from-[#180d14]/90 to-[#0e070c]/90 border border-white/[0.1] hover:border-[#3B82F6]/50 shadow-lg hover:shadow-[0_10px_30px_rgba(59,130,246,0.15)] transition-all cursor-pointer flex flex-col justify-between h-44 relative overflow-hidden"
        >
          <div className="w-10 h-10 rounded-xl bg-[#3B82F6]/15 border border-[#3B82F6]/30 flex items-center justify-center text-[#93C5FD] group-hover:scale-110 transition-transform">
            <Compass className="w-5 h-5" />
          </div>
          <div>
            <h4 className="text-sm font-black text-white group-hover:text-[#93C5FD] transition-colors">
              Ballroom Canvas
            </h4>
            <p className="text-[11px] text-white/50 mt-1">
              Parket v pomere 2:3 so zlatými stenami a LOD šípkami.
            </p>
          </div>
          <span className="text-[10px] font-bold text-[#3B82F6] uppercase tracking-wider">
            Otvoriť parket →
          </span>
        </div>

        {/* Card 3: Dual Video Porovnávač */}
        <div
          onClick={() => onNavigateTab('studio')}
          className="group p-5 rounded-2xl bg-gradient-to-b from-[#180d14]/90 to-[#0e070c]/90 border border-white/[0.1] hover:border-[#E11D48]/50 shadow-lg hover:shadow-[0_10px_30px_rgba(225,29,72,0.15)] transition-all cursor-pointer flex flex-col justify-between h-44 relative overflow-hidden"
        >
          <div className="w-10 h-10 rounded-xl bg-[#E11D48]/15 border border-[#E11D48]/30 flex items-center justify-center text-[#FDA4AF] group-hover:scale-110 transition-transform">
            <Video className="w-5 h-5" />
          </div>
          <div>
            <h4 className="text-sm font-black text-white group-hover:text-[#FDA4AF] transition-colors">
              Video Štúdio
            </h4>
            <p className="text-[11px] text-white/50 mt-1">
              Dual player, zrkadlový režim a spomalenie 0.5x.
            </p>
          </div>
          <span className="text-[10px] font-bold text-[#E11D48] uppercase tracking-wider">
            Porovnať tanec →
          </span>
        </div>

        {/* Card 4: Knižnica Figúr */}
        <div
          onClick={() => onNavigateTab('library')}
          className="group p-5 rounded-2xl bg-gradient-to-b from-[#180d14]/90 to-[#0e070c]/90 border border-white/[0.1] hover:border-[#10B981]/50 shadow-lg hover:shadow-[0_10px_30px_rgba(16,185,129,0.15)] transition-all cursor-pointer flex flex-col justify-between h-44 relative overflow-hidden"
        >
          <div className="w-10 h-10 rounded-xl bg-[#10B981]/15 border border-[#10B981]/30 flex items-center justify-center text-[#6EE7B7] group-hover:scale-110 transition-transform">
            <BookOpen className="w-5 h-5" />
          </div>
          <div>
            <h4 className="text-sm font-black text-white group-hover:text-[#6EE7B7] transition-colors">
              Sylabus Figúr
            </h4>
            <p className="text-[11px] text-white/50 mt-1">
              WDSF/ISTD katalóg s nášľapmi a hodnotením.
            </p>
          </div>
          <span className="text-[10px] font-bold text-[#10B981] uppercase tracking-wider">
            Prezrieť sylabus →
          </span>
        </div>
      </section>

      {/* ── 4. Hero Recent Routine & Competition Finale Simulator ───────── */}
      <section className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left 2 Cols: Naposledy Upravovaná Zostava */}
        <div className="lg:col-span-2 p-6 rounded-3xl bg-gradient-to-br from-[#1b0912]/90 via-[#12050b]/90 to-[#080204]/90 border border-[#D4AF37]/30 shadow-2xl backdrop-blur-xl flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-4">
              <span className="text-[11px] font-black uppercase tracking-widest text-[#D4AF37] flex items-center gap-1.5">
                <Clock className="w-3.5 h-3.5" />
                Naposledy Cvičená Zostava
              </span>
              <span className="text-xs text-white/50 flex items-center gap-1 font-bold">
                {recentRoutine?.dance_category?.toLowerCase() === 'latin' ? (
                  <>
                    <AnimatedFlameIcon size={13} className="text-[#FDA4AF]" />
                    <span className="text-[#FDA4AF]">Latina</span>
                  </>
                ) : (
                  <>
                    <DropletIcon size={13} className="text-[#93C5FD]" />
                    <span className="text-[#93C5FD]">Štandard</span>
                  </>
                )}
              </span>
            </div>

            {recentRoutine ? (
              <div className="space-y-3">
                <div className="flex items-center gap-3">
                  <h3 className="text-2xl font-black text-white tracking-tight">
                    {recentRoutine.name}
                  </h3>
                  <span className="px-2.5 py-0.5 rounded-full text-xs font-black uppercase bg-[#D4AF37]/20 text-[#FFE088] border border-[#D4AF37]/40 flex items-center gap-1.5">
                    {recentRoutine?.dance_category?.toLowerCase() === 'latin' ? (
                      <AnimatedFlameIcon size={11} className="text-[#FFE088]" />
                    ) : (
                      <DropletIcon size={11} className="text-[#FFE088]" />
                    )}
                    {recentRoutine.dance_name}
                  </span>
                </div>
                <p className="text-sm text-white/60">
                  Kompletná choreografia s LOD prechodmi, rytmickými značkami a synchronizovanými
                  uzlami.
                </p>
              </div>
            ) : (
              <div className="space-y-2 py-4">
                <h3 className="text-xl font-bold text-white">Žiadna zostava zatiaľ</h3>
                <p className="text-sm text-white/50">Vytvor svoju prvú tanečnú choreografiu.</p>
              </div>
            )}
          </div>

          <div className="mt-6 pt-4 border-t border-white/[0.08] flex items-center justify-between">
            <span className="text-xs text-white/40">
              {recentRoutine
                ? `Aktualizované ${new Date(recentRoutine.updated_at).toLocaleDateString('sk-SK')}`
                : 'Pripravené na začiatok'}
            </span>
            {recentRoutine && (
              <button
                onClick={() => onOpenRoutine(recentRoutine)}
                className="flex items-center gap-2 px-5 py-2.5 rounded-full bg-gradient-to-r from-[#D4AF37] to-[#B8861E] text-black font-black text-xs hover:brightness-110 active:scale-95 transition-all shadow-[0_4px_16px_rgba(212,175,55,0.4)] cursor-pointer"
              >
                <Play className="w-3.5 h-3.5 fill-black" />
                <span>Otvoriť na Plátne</span>
              </button>
            )}
          </div>
        </div>

        {/* Right 1 Col: Súťažné Finále Tréner */}
        <div className="p-6 rounded-3xl bg-gradient-to-b from-[#24060f]/80 to-[#120207]/90 border border-rose-500/25 shadow-2xl backdrop-blur-xl flex flex-col justify-between">
          <div className="space-y-3">
            <div className="flex items-center gap-2 text-rose-400">
              <Flame className="w-4 h-4 fill-rose-500" />
              <span className="text-xs font-black uppercase tracking-wider">Súťažné Finále</span>
            </div>
            <h4 className="text-lg font-black text-white">5-Tancový Simulátor</h4>
            <p className="text-xs text-white/60 leading-relaxed">
              Trénuj 1:30 min na každý tanec s 30s pauzou. Otestuj fyzickú a technickú kondíciu pred
              súťažou.
            </p>

            <div className="p-3 rounded-xl bg-black/40 border border-white/[0.06] flex items-center justify-between text-xs">
              <span className="text-white/60">Aktuálny cyklus:</span>
              <span className="font-mono font-bold text-[#FFE088]">1:30 / 0:30</span>
            </div>
          </div>

          <button
            onClick={() => onNavigateTab('studio')}
            className="mt-6 w-full py-2.5 rounded-full bg-rose-600 hover:bg-rose-500 text-white font-bold text-xs active:scale-95 transition-all shadow-[0_4px_14px_rgba(225,29,72,0.4)] cursor-pointer text-center"
          >
            Spustiť Finálový Tréning
          </button>
        </div>
      </section>
    </div>
  )
}
