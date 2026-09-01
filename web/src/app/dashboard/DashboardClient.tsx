'use client'

import { useState, useEffect } from 'react'
import { signOut } from '../actions'
import { DownloadButton } from '@/components/DownloadButton'

type Routine = {
  id: string
  name: string
  dance_name: string
  dance_category: string
  updated_at: string
  last_modified_by?: string
}

type Figure = {
  id: string
  name: string
  dance_name: string
  rhythm: string
  technique_notes: string
  is_custom: boolean
}

type Props = {
  user: { email: string; id: string }
  routines: Routine[]
  figures: Figure[]
}

type CaptureMode = 'text' | 'voice' | 'camera'
type MainView = 'home' | 'canvas' | 'library' | 'compare'

export default function DashboardClient({ user, routines, figures }: Props) {
  const [currentView, setCurrentView] = useState<MainView>('home')
  const [captureMode, setCaptureMode] = useState<CaptureMode>('text')
  const [noteText, setNoteText] = useState('')
  const [searchQuery, setSearchQuery] = useState('')
  const [isCommandPaletteOpen, setIsCommandPaletteOpen] = useState(false)
  const [savedFeedback, setSavedFeedback] = useState(false)
  const [isRecording, setIsRecording] = useState(false)
  
  // Compare Mode State
  const [compareRoutineA, setCompareRoutineA] = useState<string>(routines[0]?.id || '')
  const [compareRoutineB, setCompareRoutineB] = useState<string>(routines[1]?.id || '')

  // Keyboard shortcut for Command Palette (Cmd+K / Ctrl+K)
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault()
        setIsCommandPaletteOpen(prev => !prev)
      }
    }
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [])

  const filteredRoutines = routines.filter(r =>
    r.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    r.dance_name.toLowerCase().includes(searchQuery.toLowerCase())
  )

  const filteredFigures = figures.filter(f =>
    f.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    f.dance_name.toLowerCase().includes(searchQuery.toLowerCase())
  )

  const latestRoutine = routines[0]

  const quickTags = ['#Držanie', '#Rytmus', '#Waltz', '#Rumba', '#Sway', '#Rotácia', '#Nášľap']

  const handleSaveNote = () => {
    if (!noteText.trim()) return
    setSavedFeedback(true)
    setTimeout(() => {
      setNoteText('')
      setSavedFeedback(false)
    }, 1500)
  }

  return (
    <div className="min-h-screen bg-[#050505] text-white selection:bg-[#D4AF37]/30 pb-32 font-sans relative overflow-x-hidden">
      
      {/* ── Ambient Background Glows ─────────────────────────────────── */}
      <div className="fixed top-[-150px] left-[-100px] w-[500px] h-[500px] bg-[#D4AF37]/8 rounded-full blur-[140px] pointer-events-none" />
      <div className="fixed bottom-[-100px] right-[-100px] w-[500px] h-[500px] bg-[#1E293B]/20 rounded-full blur-[150px] pointer-events-none" />

      {/* ── Top Bar with Interactive Logo ───────────────────────────── */}
      <header className="sticky top-0 z-40 bg-[#050505]/75 backdrop-blur-2xl border-b border-white/[0.06]">
        <div className="max-w-4xl mx-auto px-4 py-3.5 flex items-center justify-between">
          
          {/* Interactive Logo trigger */}
          <button
            onClick={() => setIsCommandPaletteOpen(true)}
            className="flex items-center gap-3 group text-left transition-transform active:scale-95"
            title="Otvoriť Command Palette (Cmd+K)"
          >
            <div className="w-10 h-10 rounded-2xl bg-gradient-to-br from-[#D4AF37]/20 to-[#FFE088]/5 border border-[#D4AF37]/30 flex items-center justify-center shadow-lg shadow-[#D4AF37]/10 group-hover:border-[#D4AF37]/50 transition-all">
              <span className="text-xl transform group-hover:scale-110 transition-transform">💃</span>
            </div>
            <div>
              <div className="flex items-center gap-1.5">
                <h1 className="text-sm font-black tracking-wider text-white">ELLEGNOTE</h1>
                <span className="text-[9px] px-1.5 py-0.5 rounded-full bg-white/10 text-white/60 font-mono">⌘K</span>
              </div>
              <p className="text-[11px] text-[#D4AF37]/90 font-medium">Pripravený na tréning</p>
            </div>
          </button>

          {/* Top Actions */}
          <div className="flex items-center gap-2">
            <DownloadButton
              label="Export"
              loadingLabel="..."
              successLabel="Stiahnuté!"
              data={{ routines, figures, exportedAt: new Date().toISOString() }}
              filename={`ellegnote-export-${new Date().toISOString().slice(0, 10)}.json`}
              className="text-xs !py-1.5 !px-3 bg-white/5 hover:bg-white/10 border border-white/10 rounded-xl transition-colors text-white/80"
            />

            <form action={signOut}>
              <button
                type="submit"
                className="text-xs text-white/50 hover:text-white transition-colors px-3 py-1.5 rounded-xl hover:bg-white/5"
              >
                Odhlásiť
              </button>
            </form>
          </div>
        </div>
      </header>

      {/* ── Main Workspace Content ──────────────────────────────────── */}
      <main className="max-w-4xl mx-auto px-4 pt-6 space-y-6">
        
        {/* ── 1. Central Capture Area (Liquid Glass Workspace) ──────── */}
        <section className="bg-[#0e0e12]/85 backdrop-blur-2xl border border-white/[0.08] hover:border-[#D4AF37]/30 rounded-3xl p-5 sm:p-6 shadow-2xl shadow-black/60 transition-all">
          
          {/* Mode Switcher */}
          <div className="flex items-center justify-between mb-4 pb-3 border-b border-white/[0.06]">
            <div className="flex items-center gap-1 bg-white/[0.04] p-1 rounded-full border border-white/[0.05]">
              <button
                onClick={() => setCaptureMode('text')}
                className={`px-3.5 py-1.5 rounded-full text-xs font-semibold transition-all ${
                  captureMode === 'text'
                    ? 'bg-gradient-to-r from-[#D4AF37] to-[#FFE088] text-[#050505] shadow-md shadow-[#D4AF37]/20'
                    : 'text-white/60 hover:text-white'
                }`}
              >
                📝 Text
              </button>
              <button
                onClick={() => setCaptureMode('voice')}
                className={`px-3.5 py-1.5 rounded-full text-xs font-semibold transition-all ${
                  captureMode === 'voice'
                    ? 'bg-gradient-to-r from-[#D4AF37] to-[#FFE088] text-[#050505] shadow-md shadow-[#D4AF37]/20'
                    : 'text-white/60 hover:text-white'
                }`}
              >
                🎙️ Hlas
              </button>
              <button
                onClick={() => setCaptureMode('camera')}
                className={`px-3.5 py-1.5 rounded-full text-xs font-semibold transition-all ${
                  captureMode === 'camera'
                    ? 'bg-gradient-to-r from-[#D4AF37] to-[#FFE088] text-[#050505] shadow-md shadow-[#D4AF37]/20'
                    : 'text-white/60 hover:text-white'
                }`}
              >
                🎥 Video
              </button>
            </div>

            {savedFeedback && (
              <span className="text-xs font-bold text-[#10B981] flex items-center gap-1 animate-fade-in">
                ✓ Uložené do poznámok
              </span>
            )}
          </div>

          {/* Mode 1: Text Note */}
          {captureMode === 'text' && (
            <div className="space-y-4">
              <textarea
                value={noteText}
                onChange={e => setNoteText(e.target.value)}
                placeholder="Zadaj myšlienku, figúru, technickú pripomienku alebo postreh z tréningu..."
                className="w-full h-28 bg-transparent text-sm sm:text-base text-white placeholder-white/30 resize-none focus:outline-none leading-relaxed"
              />

              {/* Quick Tags */}
              <div className="flex flex-wrap items-center gap-1.5">
                {quickTags.map(tag => (
                  <button
                    key={tag}
                    onClick={() => setNoteText(prev => prev ? `${prev} ${tag}` : tag)}
                    className="text-[11px] font-medium text-[#D4AF37]/80 bg-[#D4AF37]/10 hover:bg-[#D4AF37]/20 border border-[#D4AF37]/20 px-2.5 py-1 rounded-lg transition-colors"
                  >
                    {tag}
                  </button>
                ))}
              </div>

              {/* Action Bar */}
              <div className="flex items-center justify-between pt-2">
                <span className="text-[11px] text-white/40">
                  {noteText.length} znakov
                </span>

                <button
                  onClick={handleSaveNote}
                  disabled={!noteText.trim()}
                  className="px-4 py-2 rounded-full text-xs font-bold bg-gradient-to-r from-[#D4AF37] to-[#FFE088] text-[#050505] disabled:opacity-40 disabled:cursor-not-allowed shadow-lg shadow-[#D4AF37]/20 transition-all active:scale-95"
                >
                  Uložiť poznámku
                </button>
              </div>
            </div>
          )}

          {/* Mode 2: Voice Dictation */}
          {captureMode === 'voice' && (
            <div className="py-6 flex flex-col items-center justify-center text-center space-y-4">
              <div className="flex items-center gap-1.5 h-12">
                {[...Array(16)].map((_, i) => (
                  <div
                    key={i}
                    className={`w-1 rounded-full transition-all duration-200 ${
                      isRecording ? 'bg-gradient-to-t from-[#E11D48] to-[#FFE088]' : 'bg-white/20'
                    }`}
                    style={{
                      height: isRecording ? `${Math.max(12, Math.sin(i * 0.8) * 44 + 10)}px` : '8px'
                    }}
                  />
                ))}
              </div>

              <p className="text-xs text-white/60">
                {isRecording ? 'Nahrávam tréningový komentár...' : 'Stlačte mikrofón pre hlasový záznam trénera'}
              </p>

              <button
                onClick={() => setIsRecording(!isRecording)}
                className={`w-14 h-14 rounded-full flex items-center justify-center text-xl transition-all shadow-lg active:scale-90 ${
                  isRecording
                    ? 'bg-[#E11D48] text-white shadow-[#E11D48]/40 animate-pulse'
                    : 'bg-gradient-to-r from-[#D4AF37] to-[#FFE088] text-[#050505] shadow-[#D4AF37]/30'
                }`}
              >
                {isRecording ? '⏹' : '🎙️'}
              </button>
            </div>
          )}

          {/* Mode 3: Video Recording / Vault */}
          {captureMode === 'camera' && (
            <div className="py-8 flex flex-col items-center justify-center text-center space-y-3 bg-white/[0.02] rounded-2xl border border-dashed border-white/10">
              <div className="w-12 h-12 rounded-2xl bg-[#D4AF37]/15 flex items-center justify-center text-2xl">
                🎥
              </div>
              <div>
                <h4 className="text-sm font-bold text-white">Tréningové Video a Porovnávač</h4>
                <p className="text-xs text-white/50 mt-1 max-w-sm">
                  Prehrajte referenčný vzor alebo nahrajte vlastný pokus na analýzu techniky.
                </p>
              </div>
              <button
                onClick={() => setCurrentView('compare')}
                className="mt-2 px-4 py-2 rounded-full text-xs font-bold bg-white/10 hover:bg-white/15 border border-white/15 text-white transition-all"
              >
                Otvoriť Porovnávač ➔
              </button>
            </div>
          )}
        </section>

        {/* ── 2. Quick Actions Row ──────────────────────────────────── */}
        <section className="space-y-2.5">
          <h3 className="text-[11px] font-black tracking-widest text-white/40 uppercase px-1">
            Rýchle akcie
          </h3>

          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
            
            {/* New Routine */}
            <button
              onClick={() => { setCurrentView('canvas'); setSearchQuery('') }}
              className="p-4 rounded-2xl bg-[#0e0e12] border border-white/[0.06] hover:border-[#D4AF37]/40 text-left transition-all group"
            >
              <div className="w-9 h-9 rounded-xl bg-[#D4AF37]/15 flex items-center justify-center text-base mb-2 group-hover:scale-110 transition-transform">
                ➕
              </div>
              <h4 className="text-xs font-bold text-white group-hover:text-[#D4AF37] transition-colors">Nová zostava</h4>
              <p className="text-[10px] text-white/50 mt-0.5">Založiť choreografiu</p>
            </button>

            {/* Compare Mode */}
            <button
              onClick={() => setCurrentView('compare')}
              className="p-4 rounded-2xl bg-[#0e0e12] border border-white/[0.06] hover:border-[#3B82F6]/40 text-left transition-all group"
            >
              <div className="w-9 h-9 rounded-xl bg-[#3B82F6]/15 flex items-center justify-center text-base mb-2 group-hover:scale-110 transition-transform">
                ⚔️
              </div>
              <h4 className="text-xs font-bold text-white group-hover:text-[#3B82F6] transition-colors">Porovnať</h4>
              <p className="text-[10px] text-white/50 mt-0.5">Vzor vs. Môj tanec</p>
            </button>

            {/* Library */}
            <button
              onClick={() => { setCurrentView('library'); setSearchQuery('') }}
              className="p-4 rounded-2xl bg-[#0e0e12] border border-white/[0.06] hover:border-[#10B981]/40 text-left transition-all group"
            >
              <div className="w-9 h-9 rounded-xl bg-[#10B981]/15 flex items-center justify-center text-base mb-2 group-hover:scale-110 transition-transform">
                📚
              </div>
              <h4 className="text-xs font-bold text-white group-hover:text-[#10B981] transition-colors">Knižnica</h4>
              <p className="text-[10px] text-white/50 mt-0.5">{figures.length} figúr a krokov</p>
            </button>

            {/* Canvas */}
            <button
              onClick={() => { setCurrentView('canvas'); setSearchQuery('') }}
              className="p-4 rounded-2xl bg-[#0e0e12] border border-white/[0.06] hover:border-[#F43F5E]/40 text-left transition-all group"
            >
              <div className="w-9 h-9 rounded-xl bg-[#F43F5E]/15 flex items-center justify-center text-base mb-2 group-hover:scale-110 transition-transform">
                🎨
              </div>
              <h4 className="text-xs font-bold text-white group-hover:text-[#F43F5E] transition-colors">Canvas</h4>
              <p className="text-[10px] text-white/50 mt-0.5">{routines.length} zostáv na plátne</p>
            </button>
          </div>
        </section>

        {/* ── 3. Most Recent Edit Card ──────────────────────────────── */}
        {latestRoutine && currentView === 'home' && (
          <section className="space-y-2.5">
            <div className="flex items-center justify-between px-1">
              <h3 className="text-[11px] font-black tracking-widest text-white/40 uppercase">
                Naposledy upravované
              </h3>
              <button
                onClick={() => setCurrentView('canvas')}
                className="text-xs font-bold text-[#D4AF37] hover:underline"
              >
                Zobraziť všetky ({routines.length})
              </button>
            </div>

            <div
              onClick={() => setCurrentView('canvas')}
              className="p-5 rounded-2xl bg-gradient-to-br from-[#121216] to-[#0a0a0d] border border-white/[0.08] hover:border-[#D4AF37]/40 cursor-pointer transition-all shadow-lg group"
            >
              <div className="flex items-start justify-between gap-4">
                <div className="space-y-1.5">
                  <div className="flex items-center gap-2">
                    <span className={`text-[10px] font-black px-2 py-0.5 rounded-md ${
                      latestRoutine.dance_category?.toLowerCase() === 'standard'
                        ? 'bg-[#3B82F6]/20 text-[#3B82F6] border border-[#3B82F6]/30'
                        : 'bg-[#F43F5E]/20 text-[#F43F5E] border border-[#F43F5E]/30'
                    }`}>
                      {latestRoutine.dance_category?.toUpperCase() || 'ŠTANDARD'}
                    </span>
                    <span className="text-xs text-white/40">•</span>
                    <span className="text-xs font-bold text-[#D4AF37]">{latestRoutine.dance_name}</span>
                  </div>

                  <h4 className="text-base font-bold text-white group-hover:text-[#D4AF37] transition-colors">
                    {latestRoutine.name}
                  </h4>
                  
                  {latestRoutine.last_modified_by && (
                    <p className="text-xs text-white/50">
                      Naposledy upravil: {latestRoutine.last_modified_by}
                    </p>
                  )}
                </div>

                <span className="text-xs text-white/40 shrink-0">
                  {new Date(latestRoutine.updated_at).toLocaleDateString('sk-SK', { day: 'numeric', month: 'short' })}
                </span>
              </div>

              <div className="mt-4 pt-3 border-t border-white/[0.06] flex items-center justify-between text-xs font-bold text-[#D4AF37]">
                <span>Pokračovať v úpravách na plátne</span>
                <span className="transform group-hover:translate-x-1 transition-transform">➔</span>
              </div>
            </div>
          </section>
        )}

        {/* ── Sub-View: Canvas / Routines ─────────────────────────────── */}
        {currentView === 'canvas' && (
          <section className="space-y-4 pt-2">
            <div className="flex items-center justify-between">
              <h2 className="text-base font-bold text-white">Všetky choreografie ({filteredRoutines.length})</h2>
              <button
                onClick={() => setCurrentView('home')}
                className="text-xs text-white/50 hover:text-white"
              >
                ✕ Zavrieť
              </button>
            </div>

            <div className="space-y-3">
              {filteredRoutines.map(r => (
                <div
                  key={r.id}
                  className="p-4 rounded-2xl bg-[#0e0e12] border border-white/[0.06] hover:border-[#D4AF37]/30 transition-all flex items-center justify-between"
                >
                  <div>
                    <h4 className="font-bold text-sm text-white">{r.name}</h4>
                    <p className="text-xs text-white/50 mt-0.5">{r.dance_name} · {r.dance_category}</p>
                  </div>
                  <span className="text-xs font-bold text-[#D4AF37]">Otvoriť ➔</span>
                </div>
              ))}
            </div>
          </section>
        )}

        {/* ── Sub-View: Library & Figures ────────────────────────────── */}
        {currentView === 'library' && (
          <section className="space-y-4 pt-2">
            <div className="flex items-center justify-between">
              <h2 className="text-base font-bold text-white">Knižnica figúr ({filteredFigures.length})</h2>
              <button
                onClick={() => setCurrentView('home')}
                className="text-xs text-white/50 hover:text-white"
              >
                ✕ Zavrieť
              </button>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {filteredFigures.map(f => (
                <div
                  key={f.id}
                  className="p-4 rounded-2xl bg-[#0e0e12] border border-white/[0.06] hover:border-[#10B981]/30 transition-all space-y-1.5"
                >
                  <div className="flex items-start justify-between">
                    <h4 className="font-bold text-sm text-white">{f.name}</h4>
                    <span className="text-[10px] px-2 py-0.5 rounded-full bg-[#10B981]/15 text-[#10B981] font-bold">
                      {f.dance_name}
                    </span>
                  </div>
                  <p className="text-xs text-[#D4AF37] font-mono">{f.rhythm}</p>
                  {f.technique_notes && (
                    <p className="text-xs text-white/50 line-clamp-2">{f.technique_notes}</p>
                  )}
                </div>
              ))}
            </div>
          </section>
        )}

        {/* ── Sub-View: Compare Mode ──────────────────────────────────── */}
        {currentView === 'compare' && (
          <section className="space-y-4 pt-2">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-base font-bold text-white">⚔️ Dual Porovnávač</h2>
                <p className="text-xs text-white/50">Porovnanie vzoru a vlastného výkonu</p>
              </div>
              <button
                onClick={() => setCurrentView('home')}
                className="text-xs text-white/50 hover:text-white"
              >
                ✕ Zavrieť
              </button>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {/* Slot A */}
              <div className="p-4 rounded-2xl bg-[#0e0e12] border border-[#E11D48]/30 space-y-3">
                <span className="text-[11px] font-black text-[#E11D48] tracking-wider uppercase">
                  🔴 Moje video (A)
                </span>
                <select
                  value={compareRoutineA}
                  onChange={e => setCompareRoutineA(e.target.value)}
                  className="w-full bg-[#141418] text-xs text-white p-2.5 rounded-xl border border-white/10 focus:outline-none"
                >
                  {routines.map(r => (
                    <option key={r.id} value={r.id}>{r.name} ({r.dance_name})</option>
                  ))}
                </select>
                <div className="h-36 rounded-xl bg-black/50 border border-white/5 flex items-center justify-center text-xs text-white/40">
                  Prehrávač videa A (Môj pokus)
                </div>
              </div>

              {/* Slot B */}
              <div className="p-4 rounded-2xl bg-[#0e0e12] border border-[#10B981]/30 space-y-3">
                <span className="text-[11px] font-black text-[#10B981] tracking-wider uppercase">
                  🟢 Vzor / Idol (B)
                </span>
                <select
                  value={compareRoutineB}
                  onChange={e => setCompareRoutineB(e.target.value)}
                  className="w-full bg-[#141418] text-xs text-white p-2.5 rounded-xl border border-white/10 focus:outline-none"
                >
                  {routines.map(r => (
                    <option key={r.id} value={r.id}>{r.name} ({r.dance_name})</option>
                  ))}
                </select>
                <div className="h-36 rounded-xl bg-black/50 border border-white/5 flex items-center justify-center text-xs text-white/40">
                  Prehrávač videa B (Referenčný vzor)
                </div>
              </div>
            </div>
          </section>
        )}
      </main>

      {/* ── Floating Command Palette Modal (Cmd+K) ───────────────────── */}
      {isCommandPaletteOpen && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-xl flex items-center justify-center p-4">
          <div className="w-full max-w-xl bg-[#0e0e12] border border-[#D4AF37]/30 rounded-3xl p-5 shadow-2xl shadow-black space-y-4 animate-scale-up">
            
            {/* Search Input */}
            <div className="flex items-center gap-3 bg-white/[0.04] px-4 py-3 rounded-2xl border border-white/10">
              <span className="text-white/40">🔍</span>
              <input
                type="text"
                autoFocus
                placeholder="Hľadať akcie, zostavy alebo figúry..."
                value={searchQuery}
                onChange={e => setSearchQuery(e.target.value)}
                className="w-full bg-transparent text-sm text-white placeholder-white/40 focus:outline-none"
              />
              <button
                onClick={() => setIsCommandPaletteOpen(false)}
                className="text-xs text-white/40 hover:text-white px-2 py-1"
              >
                ESC
              </button>
            </div>

            {/* Command List */}
            <div className="max-h-72 overflow-y-auto space-y-2 pr-1">
              <div className="text-[10px] font-black text-white/40 uppercase tracking-wider px-2">
                Rýchle príkazy
              </div>

              <button
                onClick={() => { setCurrentView('canvas'); setIsCommandPaletteOpen(false) }}
                className="w-full p-2.5 rounded-xl hover:bg-white/5 flex items-center justify-between text-left text-xs font-semibold text-white/90 transition-colors"
              >
                <span>➕ Nová choreografia na plátne</span>
                <span className="text-[10px] text-[#D4AF37]">Canvas</span>
              </button>

              <button
                onClick={() => { setCurrentView('compare'); setIsCommandPaletteOpen(false) }}
                className="w-full p-2.5 rounded-xl hover:bg-white/5 flex items-center justify-between text-left text-xs font-semibold text-white/90 transition-colors"
              >
                <span>⚔️ Porovnať tanec so vzorom</span>
                <span className="text-[10px] text-[#3B82F6]">Dual</span>
              </button>

              <button
                onClick={() => { setCurrentView('library'); setIsCommandPaletteOpen(false) }}
                className="w-full p-2.5 rounded-xl hover:bg-white/5 flex items-center justify-between text-left text-xs font-semibold text-white/90 transition-colors"
              >
                <span>📚 Otvoriť knižnicu figúr</span>
                <span className="text-[10px] text-[#10B981]">Library</span>
              </button>

              {/* Matching Routines */}
              {searchQuery && filteredRoutines.length > 0 && (
                <>
                  <div className="text-[10px] font-black text-white/40 uppercase tracking-wider px-2 pt-2">
                    Zostavy ({filteredRoutines.length})
                  </div>
                  {filteredRoutines.slice(0, 4).map(r => (
                    <button
                      key={r.id}
                      onClick={() => { setCurrentView('canvas'); setIsCommandPaletteOpen(false) }}
                      className="w-full p-2.5 rounded-xl hover:bg-white/5 flex items-center justify-between text-left text-xs text-white transition-colors"
                    >
                      <span className="font-bold">{r.name}</span>
                      <span className="text-white/40">{r.dance_name}</span>
                    </button>
                  ))}
                </>
              )}
            </div>
          </div>
        </div>
      )}

      {/* ── Minimal Liquid Glass Bottom Dock ─────────────────────────── */}
      <nav className="fixed bottom-5 inset-x-0 z-40 flex justify-center px-4 pointer-events-none">
        <div className="bg-[#0e0e12]/80 backdrop-blur-2xl border border-white/[0.12] rounded-full p-1.5 shadow-2xl shadow-black/80 flex items-center gap-1 pointer-events-auto">
          
          <button
            onClick={() => setCurrentView('home')}
            className={`px-4 py-2 rounded-full text-xs font-bold transition-all flex items-center gap-1.5 ${
              currentView === 'home'
                ? 'bg-gradient-to-r from-[#D4AF37] to-[#FFE088] text-[#050505] shadow-md shadow-[#D4AF37]/20'
                : 'text-white/60 hover:text-white'
            }`}
          >
            <span>🏠</span>
            <span>Domov</span>
          </button>

          <button
            onClick={() => setCurrentView('canvas')}
            className={`px-4 py-2 rounded-full text-xs font-bold transition-all flex items-center gap-1.5 ${
              currentView === 'canvas'
                ? 'bg-gradient-to-r from-[#D4AF37] to-[#FFE088] text-[#050505] shadow-md shadow-[#D4AF37]/20'
                : 'text-white/60 hover:text-white'
            }`}
          >
            <span>🎨</span>
            <span>Canvas</span>
          </button>

          <button
            onClick={() => setCurrentView('compare')}
            className={`px-4 py-2 rounded-full text-xs font-bold transition-all flex items-center gap-1.5 ${
              currentView === 'compare'
                ? 'bg-gradient-to-r from-[#D4AF37] to-[#FFE088] text-[#050505] shadow-md shadow-[#D4AF37]/20'
                : 'text-white/60 hover:text-white'
            }`}
          >
            <span>⚔️</span>
            <span>Porovnať</span>
          </button>

          <button
            onClick={() => setCurrentView('library')}
            className={`px-4 py-2 rounded-full text-xs font-bold transition-all flex items-center gap-1.5 ${
              currentView === 'library'
                ? 'bg-gradient-to-r from-[#D4AF37] to-[#FFE088] text-[#050505] shadow-md shadow-[#D4AF37]/20'
                : 'text-white/60 hover:text-white'
            }`}
          >
            <span>📚</span>
            <span>Knižnica</span>
          </button>
        </div>
      </nav>
    </div>
  )
}
