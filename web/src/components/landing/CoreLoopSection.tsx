'use client'

import React, { useState, useEffect } from 'react'

export default function CoreLoopSection() {
  const [activeStep, setActiveStep] = useState<number>(2)
  const [isAutoPlaying, setIsAutoPlaying] = useState<boolean>(true)

  // Gentle auto-rotation through the 3-second cycle unless hovered
  useEffect(() => {
    if (!isAutoPlaying) return
    const timer = setInterval(() => {
      setActiveStep((prev) => (prev >= 3 ? 1 : prev + 1))
    }, 4500)
    return () => clearInterval(timer)
  }, [isAutoPlaying])

  const steps = [
    {
      id: 1,
      num: '01',
      title: 'Zídenie z parketu po lekcii',
      tag: '0.0s • V Sále',
      desc: 'Tréner práve vysvetlil kľúčový detail držania hlavy a zníženia v Slowfoxe. Máte spotené ruky, telefón je na statíve alebo lavičke.',
      subtext: 'Žiadne odomykanie zbytočných menu. Jediný dotyk a Encore je pripravený.',
      visualBadge: 'Reakčný čas: < 1.0 sekundy',
    },
    {
      id: 2,
      num: '02',
      title: '1-Tap Hlasový diktát alebo video',
      tag: '0.8s • Rýchly Záznam',
      desc: 'Jediný dotyk na mikrofón na hlavnej obrazovke. Natívne Apple Speech Recognition okamžite premení slová trénera na čistý text.',
      subtext: 'Nemusíte na spotenom displeji písať písmená. Hlas sa ukladá automaticky.',
      visualBadge: 'Automatický prepis bez klávesnice',
    },
    {
      id: 3,
      num: '03',
      title: 'Priradené k figúre & Synchronizované',
      tag: '1.5s • Realtime EÚ',
      desc: 'Poznámka aj 15s video sa okamžite priradia k správnemu uzlu na 2D parkete. Partner vidí novú figúru a pokyn v tej istej sekunde.',
      subtext: 'Koniec dohadov, kto čo zabudol. Obaja partneri odchádzajú zo sály s identickou zostavou.',
      visualBadge: 'WebSocket synchronizácia: 38 ms',
    },
  ]

  return (
    <section
      id="core-loop"
      className="py-28 relative z-10"
      onMouseEnter={() => setIsAutoPlaying(false)}
      onMouseLeave={() => setIsAutoPlaying(true)}
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* ── Section Header ────────────────────────────────────────── */}
        <div className="text-center max-w-3xl mx-auto mb-16 space-y-4">
          <div className="badge-gold mx-auto">
            <span className="w-1.5 h-1.5 rounded-full bg-[#FFE088] animate-pulse" />
            <span>Filozofia Encore</span>
          </div>

          <h2 className="text-3xl sm:text-5xl lg:text-6xl font-serif font-black tracking-tight text-white leading-tight">
            „Rob jednu vec{' '}
            <span className="bg-gradient-to-r from-[#FFF2CC] via-[#FFE088] to-[#D4AF37] bg-clip-text text-transparent">
              10× lepšie.
            </span>“
          </h2>

          <p className="text-sm sm:text-base text-zinc-300 max-w-2xl mx-auto">
            Tanečná aplikácia nesmie zdržiavať. Medzi dvoma kolami na tréningu rozhodujú sekundy. Pozrite sa, ako funguje 2-sekundový cyklus Encore.
          </p>
        </div>

        {/* ── Interactive 3-Step Playground ──────────────────────────── */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
          
          {/* Left Column: Interactive Step Selectors (5 cols) */}
          <div className="lg:col-span-5 space-y-4">
            {steps.map((step) => {
              const isActive = activeStep === step.id
              return (
                <div
                  key={step.id}
                  onClick={() => setActiveStep(step.id)}
                  className={`p-6 rounded-3xl transition-all duration-300 cursor-pointer border relative overflow-hidden ${
                    isActive
                      ? 'surface-obsidian border-[#FFE088]/40 shadow-[0_10px_35px_rgba(212,175,55,0.15)] scale-[1.02]'
                      : 'bg-[#121216]/60 border-white/5 hover:border-white/10 hover:bg-[#121216]'
                  }`}
                >
                  {/* Active gold accent bar */}
                  {isActive && (
                    <div className="absolute top-0 left-0 bottom-0 w-1.5 bg-gradient-to-b from-[#FFE088] to-[#D4AF37]" />
                  )}

                  <div className="flex items-center justify-between mb-2">
                    <span
                      className={`text-2xl font-serif font-black ${
                        isActive ? 'text-[#FFE088]' : 'text-zinc-600'
                      }`}
                    >
                      {step.num}
                    </span>
                    <span
                      className={`text-[10px] font-mono uppercase tracking-wider px-2.5 py-0.5 rounded-full font-bold ${
                        isActive
                          ? 'badge-gold'
                          : 'bg-white/5 text-zinc-500'
                      }`}
                    >
                      {step.tag}
                    </span>
                  </div>

                  <h3 className="text-lg font-serif font-bold text-white mb-1.5">
                    {step.title}
                  </h3>

                  <p className="text-xs text-zinc-300 leading-relaxed">
                    {step.desc}
                  </p>

                  {isActive && (
                    <div className="mt-3 pt-3 border-t border-[#FFE088]/20 flex items-center gap-2 text-[11px] font-mono text-[#FFE088]">
                      <span>{step.visualBadge}</span>
                    </div>
                  )}
                </div>
              )
            })}
          </div>

          {/* Right Column: Dynamic Stage Simulator Screen (7 cols) */}
          <div className="lg:col-span-7">
            <div className="surface-obsidian rounded-[36px] p-6 sm:p-10 min-h-[420px] flex flex-col justify-between relative overflow-hidden">
              
              {/* Stage Top Header */}
              <div className="flex justify-between items-center border-b border-zinc-800 pb-4 z-10">
                <div className="flex items-center gap-2.5">
                  <div className="w-2.5 h-2.5 rounded-full bg-zinc-600" />
                  <div className="w-2.5 h-2.5 rounded-full bg-zinc-600" />
                  <div className="w-2.5 h-2.5 rounded-full bg-[#FFE088]" />
                  <span className="text-xs font-mono text-zinc-400 ml-2">
                    Encore Workflow Simulator • Krok 0{activeStep} z 03
                  </span>
                </div>
                <span className="badge-gold">
                  {activeStep === 1 && 'KROK 1: VSTUP'}
                  {activeStep === 2 && 'KROK 2: HLASOVÝ DIKTÁT'}
                  {activeStep === 3 && 'KROK 3: REALTIME SYNCHRONIZÁCIA'}
                </span>
              </div>

              {/* Stage Content Render based on Active Step */}
              <div className="my-auto py-6 z-10">
                
                {/* ── STEP 1 VISUAL ── */}
                {activeStep === 1 && (
                  <div className="space-y-6 animate-fadeIn">
                    <div className="flex items-center justify-between">
                      <div>
                        <span className="text-xs font-mono text-zinc-400 uppercase">Tréningová sála</span>
                        <h4 className="text-2xl font-serif font-bold text-white mt-0.5">
                          Telefón na statíve. Ruky na parkete.
                        </h4>
                      </div>
                      <div className="text-right">
                        <span className="text-3xl font-mono font-black text-[#FFE088]">00:00.8s</span>
                        <span className="text-[9px] text-zinc-400 block font-mono">okamžitá odozva</span>
                      </div>
                    </div>

                    {/* Interactive Mock Display Card */}
                    <div className="p-6 rounded-2xl bg-[#0A0A0A] border border-white/10 space-y-4">
                      <div className="flex items-center justify-between text-xs text-zinc-400">
                        <span>Režim tréningu: Slowfox</span>
                        <span className="text-[#FFE088] font-mono">● 0 dotykov pred diktátom</span>
                      </div>
                      <div className="p-4 rounded-xl bg-[#141418] border border-[#FFE088]/25 flex items-center gap-4">
                        <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-[#FFE088] to-[#D4AF37] flex items-center justify-center text-black shadow-lg shrink-0">
                          <svg className="w-6 h-6" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2">
                            <path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z" />
                            <path d="M19 10v2a7 7 0 0 1-14 0v-2" />
                            <line x1="12" y1="19" x2="12" y2="23" />
                            <line x1="8" y1="23" x2="16" y2="23" />
                          </svg>
                        </div>
                        <div>
                          <p className="text-sm font-bold text-white">Veľké 1-Tap tlačidlo na domovskej obrazovke</p>
                          <p className="text-xs text-zinc-400 mt-0.5">Prispôsobené pre rýchly dotyk jedným prstom na lavičke.</p>
                        </div>
                      </div>
                    </div>
                  </div>
                )}

                {/* ── STEP 2 VISUAL ── */}
                {activeStep === 2 && (
                  <div className="space-y-6 animate-fadeIn">
                    <div className="flex items-center justify-between">
                      <div>
                        <span className="text-xs font-mono text-[#D4AF37] uppercase">Apple Speech Framework</span>
                        <h4 className="text-2xl font-serif font-bold text-white mt-0.5">
                          Okamžitý prepis trénerových slov
                        </h4>
                      </div>
                      <div className="flex items-center gap-2">
                        <span className="w-2 h-2 rounded-full bg-[#FFE088] animate-pulse" />
                        <span className="text-xs font-mono text-[#FFE088] font-bold">REC 00:06</span>
                      </div>
                    </div>

                    {/* Simulated Speech Waveform & Typewriter Box */}
                    <div className="p-6 rounded-2xl bg-[#0A0A0A] border border-[#FFE088]/25 shadow-xl space-y-4">
                      {/* Audio bars */}
                      <div className="flex items-center gap-1.5 h-8 justify-center">
                        {[40, 75, 95, 60, 85, 100, 70, 50, 90, 80, 60, 45, 80, 95, 70, 40].map((h, i) => (
                          <div
                            key={i}
                            style={{ height: `${h}%` }}
                            className="w-1 rounded-full bg-gradient-to-t from-[#D4AF37] to-[#FFE088]"
                          />
                        ))}
                      </div>

                      {/* Transcribed Text Bubble */}
                      <div className="p-4 rounded-xl bg-[#141418] border border-white/5">
                        <span className="text-[10px] font-mono text-zinc-400 uppercase block mb-1">
                          Živý prepis hovoreného slova (Slovenčina / Angličtina):
                        </span>
                        <p className="text-sm font-serif font-semibold text-white leading-relaxed">
                          „V treťom takte Slowfoxu pridať zníženie do stojnej nohy na 1, udržať rotáciu trupu a nezalamovať ľavú stranu pred prechodom.“
                        </p>
                      </div>

                      <div className="flex justify-between items-center text-[10px] text-zinc-400 font-mono">
                        <span>Spoľahlivosť prepisu: 99.4%</span>
                        <span className="text-[#FFE088]">Žiadne preklepy na klávesnici</span>
                      </div>
                    </div>
                  </div>
                )}

                {/* ── STEP 3 VISUAL ── */}
                {activeStep === 3 && (
                  <div className="space-y-6 animate-fadeIn">
                    <div className="flex items-center justify-between">
                      <div>
                        <span className="text-xs font-mono text-[#D4AF37] uppercase">Supabase Realtime Sync</span>
                        <h4 className="text-2xl font-serif font-bold text-white mt-0.5">
                          Choreografia okamžite na oboch telefónoch
                        </h4>
                      </div>
                      <div className="badge-gold">
                        <span>● Synced (38 ms)</span>
                      </div>
                    </div>

                    {/* Synchronized Parquet Node Preview */}
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                      {/* Partner A (iPhone) */}
                      <div className="p-4 rounded-2xl bg-[#0A0A0A] border border-[#FFE088]/25 space-y-2">
                        <div className="flex justify-between text-[10px] font-mono text-[#FFE088]">
                          <span>Partner (iPhone 16 Pro)</span>
                          <span>Odoslané</span>
                        </div>
                        <div className="p-3 rounded-xl bg-[#141418] border border-white/5">
                          <span className="text-[9px] font-mono text-[#D4AF37]">Figúra #04</span>
                          <p className="text-xs font-bold text-white">Feather Step (SQQ)</p>
                          <span className="text-[9px] text-zinc-400 block mt-1 font-mono">Trénerova poznámka priradená</span>
                        </div>
                      </div>

                      {/* Partner B (Partnerka) */}
                      <div className="p-4 rounded-2xl bg-[#0A0A0A] border border-[#FFE088]/25 space-y-2">
                        <div className="flex justify-between text-[10px] font-mono text-[#FFE088]">
                          <span>Partnerka (Live Presence)</span>
                          <span>Prijaté</span>
                        </div>
                        <div className="p-3 rounded-xl bg-[#141418] border border-white/5">
                          <span className="text-[9px] font-mono text-[#D4AF37]">Figúra #04</span>
                          <p className="text-xs font-bold text-white">Feather Step (SQQ)</p>
                          <span className="text-[9px] text-[#FFE088] block mt-1 font-mono">✓ Synchronizované v sále</span>
                        </div>
                      </div>
                    </div>
                  </div>
                )}

              </div>

              {/* Stage Bottom Footer */}
              <div className="pt-4 border-t border-zinc-800/80 flex flex-wrap justify-between items-center text-xs text-zinc-400 gap-2 z-10">
                <span className="font-mono text-[11px]">
                  Vyvinuté podľa potrieb reálnych slovenských a medzinárodných tanečníkov.
                </span>
                <div className="flex gap-2">
                  {[1, 2, 3].map((num) => (
                    <button
                      key={num}
                      onClick={() => setActiveStep(num)}
                      className={`w-6 h-6 rounded-full font-mono text-[10px] font-bold transition-all ${
                        activeStep === num
                          ? 'bg-[#FFE088] text-black shadow-md'
                          : 'bg-zinc-800 text-zinc-400 hover:text-white'
                      }`}
                    >
                      {num}
                    </button>
                  ))}
                </div>
              </div>

            </div>
          </div>

        </div>

      </div>
    </section>
  )
}
