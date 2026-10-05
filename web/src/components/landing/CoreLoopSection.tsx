import React from 'react'

export default function CoreLoopSection() {
  return (
    <section id="core-loop" className="py-24 relative z-10 bg-gradient-to-b from-transparent via-[#0d070b]/60 to-transparent">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Section Header */}
        <div className="text-center max-w-3xl mx-auto mb-16 space-y-3">
          <span className="text-xs font-mono font-bold uppercase tracking-[0.25em] text-[#FFE088] bg-[#D4AF37]/10 px-4 py-1.5 rounded-full border border-[#D4AF37]/25">
            Filozofia Encore
          </span>
          <h2 className="text-3xl sm:text-5xl font-serif font-black tracking-tight text-white">
            „Rob jednu vec 10× lepšie.“
          </h2>
          <p className="text-sm sm:text-base text-zinc-400">
            Aplikácia nesmie zdržiavať nekonečnými menu. Na parkete rozhodujú sekundy medzi tancami.
          </p>
        </div>

        {/* 3-Step Sequence */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 relative">
          
          {/* Step 1 */}
          <div className="p-8 rounded-3xl bg-[#100f16]/90 border border-zinc-800 relative flex flex-col justify-between space-y-6 shadow-xl">
            <div className="flex justify-between items-center">
              <span className="text-3xl font-serif font-black text-[#D4AF37]">01</span>
              <span className="text-[10px] font-mono uppercase tracking-wider text-zinc-500 bg-white/5 px-2.5 py-1 rounded-full">
                V sále
              </span>
            </div>
            <div className="space-y-2">
              <h3 className="text-xl font-serif font-bold text-white">
                Zídenie z parketu po lekcii
              </h3>
              <p className="text-xs sm:text-sm text-zinc-400 leading-relaxed">
                Tréner práve vysvetlil kľúčový detail držania hlavy v Tango Promenáde. Máte spotené ruky, telefón je na statíve.
              </p>
            </div>
            <div className="p-3 rounded-xl bg-black/40 border border-zinc-800 text-[11px] text-zinc-400 flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-[#E11D48]" />
              <span>Otvorenie aplikácie: max. 1 sekunda</span>
            </div>
          </div>

          {/* Step 2 */}
          <div className="p-8 rounded-3xl bg-gradient-to-b from-[#1c1208] to-[#120a05] border border-[#D4AF37]/50 relative flex flex-col justify-between space-y-6 shadow-2xl shadow-[#D4AF37]/10">
            <div className="flex justify-between items-center">
              <span className="text-3xl font-serif font-black text-[#FFE088]">02</span>
              <span className="text-[10px] font-mono uppercase tracking-wider text-[#D4AF37] bg-[#D4AF37]/15 px-2.5 py-1 rounded-full font-bold">
                1-Tap Záznam
              </span>
            </div>
            <div className="space-y-2">
              <h3 className="text-xl font-serif font-bold text-white">
                Hlasový diktát alebo 15s video
              </h3>
              <p className="text-xs sm:text-sm text-zinc-300 leading-relaxed">
                Jediný dotyk na mikrofón na hlavnej obrazovke. Hlasový prepis Apple Speech Recognition okamžite premení slová trénera do textu.
              </p>
            </div>
            <div className="p-3 rounded-xl bg-[#2a1b0a] border border-[#D4AF37]/30 text-[11px] text-[#FFE088] font-bold flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
              <span>Automatický prepis bez písania na klávesnici</span>
            </div>
          </div>

          {/* Step 3 */}
          <div className="p-8 rounded-3xl bg-[#100f16]/90 border border-zinc-800 relative flex flex-col justify-between space-y-6 shadow-xl">
            <div className="flex justify-between items-center">
              <span className="text-3xl font-serif font-black text-[#D4AF37]">03</span>
              <span className="text-[10px] font-mono uppercase tracking-wider text-zinc-500 bg-white/5 px-2.5 py-1 rounded-full">
                Prepojenie
              </span>
            </div>
            <div className="space-y-2">
              <h3 className="text-xl font-serif font-bold text-white">
                Priradené k figúre & Synchronizované
              </h3>
              <p className="text-xs sm:text-sm text-zinc-400 leading-relaxed">
                Poznámka aj video sú naviazané priamo na konkrétny uzol na 2D parkete. Partner v rovnakej sekunde vidí novú poznámku na svojom telefóne.
              </p>
            </div>
            <div className="p-3 rounded-xl bg-black/40 border border-zinc-800 text-[11px] text-zinc-400 flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-[#D4AF37]" />
              <span>Realtime synchronizácia cez Supabase EÚ</span>
            </div>
          </div>

        </div>
      </div>
    </section>
  )
}
