'use client'

import React, { useState } from 'react'

export default function BentoFeatures() {
  const [activeDance, setActiveDance] = useState<'waltz' | 'tango' | 'chacha'>('waltz')
  const [videoScrubber, setVideoScrubber] = useState<number>(45)

  return (
    <section id="features" className="py-24 md:py-32 relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      
      {/* ── Section Header (Brand Guidelines §1A: HomeSectionHeader standard) ── */}
      <div className="text-center max-w-3xl mx-auto mb-16 md:mb-20 space-y-4">
        <div className="flex items-center justify-center gap-2">
          <span className="text-xs font-sans font-black tracking-[0.2em] uppercase text-[#FFE088]">
            HLAVNÉ FUNKCIE PRE TANEČNÍKOV A TRÉNEROV
          </span>
        </div>

        <h2 className="text-3xl sm:text-5xl lg:text-6xl font-serif font-black tracking-tight text-white leading-tight">
          Všetko, čo profesionálny pár potrebuje.{' '}
          <span className="bg-gradient-to-r from-[#FFF2CC] via-[#FFE088] to-[#D4AF37] bg-clip-text text-transparent block sm:inline">
            Na jednom mieste.
          </span>
        </h2>

        <p className="text-sm sm:text-base text-zinc-300 max-w-2xl mx-auto leading-relaxed">
          Zabudnite na papierové zošity a neprehľadné videá v galérii telefónu. Encore prepája priestorovú choreografiu, video rozbor, tréningové poznámky a súťažné dáta do jedného čistého natívneho celku.
        </p>
      </div>

      {/* ── High-Craft Feature Showcase Grid (Brand Guidelines §1A: homeCard glass surfaces) ── */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 items-stretch">
        
        {/* ── FEATURE 1: 2D Choreografický Parket ───────────────────────── */}
        <div className="rounded-[28px] p-8 sm:p-10 bg-white/[0.05] border border-white/10 backdrop-blur-xl hover:border-[#FFE088]/30 transition-all flex flex-col justify-between">
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-xs font-mono font-bold tracking-[0.15em] text-[#FFE088] uppercase">
                01 • CHOREOGRAFIA & PRIESTOR
              </span>
              <span className="text-[11px] font-mono text-zinc-400">LOD & Smerovanie</span>
            </div>

            <h3 className="text-2xl sm:text-3xl font-serif font-bold text-white">
              Nekonečný 2D Parket s Bezierovými krivkami
            </h3>

            <p className="text-sm text-zinc-300 leading-relaxed">
              Zaznamenajte svoju zostavu presne tak, ako sa tancuje v sále. Definujte smer pohybu (Line of Dance), rohy tancodromu, uhly nášľapov (stena, stred, diagonála) a prepojte jednotlivé figúry plynulými krivkami. Obaja partneri aj tréner vidia každý krok bez dohadovania.
            </p>
          </div>

          {/* Authentic Figure Card Preview (BRAND_GUIDELINES §4 1:1) */}
          <div className="mt-8 rounded-2xl bg-[#0A0A0A] border border-white/10 p-5 space-y-4 shadow-2xl">
            {/* Top row: Dance + Figure Number + Timing + LOD */}
            <div className="flex items-center justify-between text-xs border-b border-zinc-800/80 pb-3">
              <div className="flex items-center gap-2">
                <span className="w-2.5 h-2.5 rounded-full bg-[#1E40AF]" />
                <span className="font-serif font-bold text-white">WALTZ</span>
                <span className="text-zinc-500">•</span>
                <span className="text-zinc-400 font-mono">Figúra #03</span>
              </div>
              <div className="flex items-center gap-2 font-mono text-[11px]">
                <span className="px-2 py-0.5 rounded bg-white/5 border border-white/10 text-[#FFE088] font-bold">SQQ</span>
                <span className="text-zinc-400">↗ LOD</span>
              </div>
            </div>

            {/* Middle row: Figure Name & Description */}
            <div>
              <div className="flex items-center justify-between">
                <h4 className="text-lg font-serif font-bold text-white">Natural Spin Turn</h4>
                <div className="flex text-[#FFE088] text-xs">★★★★★</div>
              </div>
              <p className="text-xs text-zinc-400 mt-1">
                Pravá noha vpred, zníženie a silná rotácia 3/8 vpravo do nového smeru.
              </p>
            </div>

            {/* Chips row: Footwork & Posture */}
            <div className="flex flex-wrap gap-2 pt-1">
              <span className="px-2.5 py-1 rounded-md bg-white/5 border border-white/5 text-[10px] font-mono text-zinc-300">
                🦶 T-H (Pán)
              </span>
              <span className="px-2.5 py-1 rounded-md bg-white/5 border border-white/5 text-[10px] font-mono text-zinc-300">
                🦶 H-T (Dáma)
              </span>
              <span className="px-2.5 py-1 rounded-md bg-white/5 border border-white/5 text-[10px] font-mono text-zinc-300">
                📐 Náklon: Vpravo
              </span>
              <span className="px-2.5 py-1 rounded-md bg-[#FFE088]/10 border border-[#FFE088]/20 text-[10px] font-mono text-[#FFE088]">
                🎙️ Tréner: 1 poznámka
              </span>
            </div>

            {/* Bottom video snippet */}
            <div className="flex items-center justify-between pt-2 border-t border-zinc-800/80 text-xs">
              <div className="flex items-center gap-2 text-zinc-400">
                <span>🎬 Video ukážka:</span>
                <span className="font-mono text-zinc-300">00:14 (HD)</span>
              </div>
              <span className="text-[#FFE088] font-bold hover:underline cursor-pointer">
                Porovnať v dueli ›
              </span>
            </div>
          </div>
        </div>

        {/* ── FEATURE 2: Video Duel & Analýza Pohybu ─────────────────────── */}
        <div className="rounded-[28px] p-8 sm:p-10 bg-white/[0.05] border border-white/10 backdrop-blur-xl hover:border-[#FFE088]/30 transition-all flex flex-col justify-between">
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-xs font-mono font-bold tracking-[0.15em] text-[#FFE088] uppercase">
                02 • TECHNICKÁ ANALÝZA
              </span>
              <span className="text-[11px] font-mono text-zinc-400">120 / 240 FPS Slo-Mo</span>
            </div>

            <h3 className="text-2xl sm:text-3xl font-serif font-bold text-white">
              Video Duel & Synchrónne Porovnanie
            </h3>

            <p className="text-sm text-zinc-300 leading-relaxed">
              Pustite si svoj záznam a video majstra sveta alebo trénera synchrónne vedľa seba. Jediný spoločný posuvník času a krokovanie po snímkach odhalia každú chybu v nášľape, vertikále chrbtice či držaní rámu.
            </p>
          </div>

          {/* Interactive Dual Video Frame Simulator */}
          <div className="mt-8 rounded-2xl bg-[#0A0A0A] border border-white/10 p-5 space-y-4 shadow-2xl">
            {/* Split Screen Mockup */}
            <div className="grid grid-cols-2 gap-3">
              <div className="rounded-xl bg-[#141418] border border-white/5 p-3 text-center space-y-2">
                <div className="text-[10px] font-mono uppercase tracking-wider text-zinc-400 flex items-center justify-center gap-1.5">
                  <span className="w-1.5 h-1.5 rounded-full bg-red-500" />
                  Váš záznam (Tréning)
                </div>
                <div className="h-20 rounded-lg bg-black/60 flex flex-col items-center justify-center border border-white/5">
                  <span className="text-[10px] font-mono text-zinc-500">Slowfox • Takt 4</span>
                  <span className="text-xs font-bold text-zinc-300 mt-1">Uhol rámu: 12°</span>
                </div>
              </div>

              <div className="rounded-xl bg-[#141418] border border-white/5 p-3 text-center space-y-2">
                <div className="text-[10px] font-mono uppercase tracking-wider text-[#FFE088] flex items-center justify-center gap-1.5">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#FFE088]" />
                  Vzor / Tréner (WDSF)
                </div>
                <div className="h-20 rounded-lg bg-black/60 flex flex-col items-center justify-center border border-[#FFE088]/20">
                  <span className="text-[10px] font-mono text-zinc-500">Slowfox • Takt 4</span>
                  <span className="text-xs font-bold text-[#FFE088] mt-1">Uhol rámu: 0° (Vzor)</span>
                </div>
              </div>
            </div>

            {/* Synchronized Scrubber */}
            <div className="space-y-2 pt-1">
              <div className="flex justify-between items-center text-xs font-mono">
                <span className="text-zinc-400">Spoločný scrubber</span>
                <span className="text-[#FFE088] font-bold">00:04.12 / 00:14.00</span>
              </div>
              <input
                type="range"
                min="0"
                max="100"
                value={videoScrubber}
                onChange={(e) => setVideoScrubber(Number(e.target.value))}
                className="w-full h-1.5 bg-zinc-800 rounded-lg appearance-none cursor-pointer accent-[#FFE088]"
              />
            </div>

            <div className="flex justify-between items-center text-[11px] font-mono text-zinc-400 pt-1 border-t border-zinc-800/80">
              <span>Rýchlosť: 0.25× / 0.5× / 1.0×</span>
              <span className="text-emerald-400 font-bold">Synchronizácia na vzorku</span>
            </div>
          </div>
        </div>

        {/* ── FEATURE 3: 1-Tap Hlasový Záznam v Sále (Core Loop) ────────── */}
        <div className="rounded-[28px] p-8 sm:p-10 bg-white/[0.05] border border-white/10 backdrop-blur-xl hover:border-[#FFE088]/30 transition-all flex flex-col justify-between">
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-xs font-mono font-bold tracking-[0.15em] text-[#FFE088] uppercase">
                03 • TRÉNINGOVÝ WORKFLOW
              </span>
              <span className="text-[11px] font-mono text-zinc-400">Reakcia &lt; 2 sekundy</span>
            </div>

            <h3 className="text-2xl sm:text-3xl font-serif font-bold text-white">
              1-Tap Hlasový Záznam Poznámok v Sále
            </h3>

            <p className="text-sm text-zinc-300 leading-relaxed">
              Po zídení z parketu po náročnej variácii máte spotené ruky a telefón je na statíve. Žiadne písanie zdĺhavých textov na displeji. Jediný dotyk na mikrofón a hlasový pokyn trénera sa okamžite prepíše a priradí priamo k danej figúre.
            </p>
          </div>

          {/* Dictation Card Simulator */}
          <div className="mt-8 rounded-2xl bg-[#0A0A0A] border border-white/10 p-5 space-y-4 shadow-2xl">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2.5">
                <div className="w-8 h-8 rounded-full bg-red-600/20 border border-red-500/40 flex items-center justify-center">
                  <span className="w-2.5 h-2.5 rounded-full bg-red-500 animate-pulse" />
                </div>
                <div>
                  <span className="text-xs font-bold text-white block">Hlasový diktát z lekcie</span>
                  <span className="text-[10px] text-zinc-400 font-mono">Dnes 15:42 • Tréner Stanislav</span>
                </div>
              </div>
              <span className="text-[11px] font-mono text-emerald-400 font-bold bg-emerald-500/10 px-2.5 py-0.5 rounded-full border border-emerald-500/20">
                Prevedené na text
              </span>
            </div>

            <div className="p-3.5 rounded-xl bg-[#141418] border border-white/5 text-xs text-zinc-200 italic leading-relaxed">
              „V Natural Turne udržať hlavu vľavo až do konca rotácie 3/8, nezalamovať ľavý lakeť a na dobe 3 predĺžiť výdych.“
            </div>

            <div className="flex items-center justify-between text-[11px] font-mono text-zinc-400 pt-2 border-t border-zinc-800/80">
              <span className="text-[#FFE088]">Priradené k: Natural Spin Turn</span>
              <span>Okamžitá sync s partnerom</span>
            </div>
          </div>
        </div>

        {/* ── FEATURE 4: Súťažný Radar SZTŠ & ksis.eu ──────────────────── */}
        <div className="rounded-[28px] p-8 sm:p-10 bg-white/[0.05] border border-white/10 backdrop-blur-xl hover:border-[#FFE088]/30 transition-all flex flex-col justify-between">
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-xs font-mono font-bold tracking-[0.15em] text-[#FFE088] uppercase">
                04 • SÚŤAŽNÝ RAST
              </span>
              <span className="text-[11px] font-mono text-zinc-400">Oficiálne dáta ksis.eu</span>
            </div>

            <h3 className="text-2xl sm:text-3xl font-serif font-bold text-white">
              Súťažný Radar SZTŠ & Postupové Body
            </h3>

            <p className="text-sm text-zinc-300 leading-relaxed">
              Oficiálne dáta zo systému Slovenského zväzu tanečného športu priamo v aplikácii. Sledujte finálové umiestnenia, počet postupových bodov a presne viete, koľko bodov a finále Vám chýba k postupu do vyššej kategórie.
            </p>
          </div>

          {/* Official Competition Radar Card Simulator */}
          <div className="mt-8 rounded-2xl bg-[#0A0A0A] border border-white/10 p-5 space-y-4 shadow-2xl">
            <div className="flex items-center justify-between">
              <div>
                <span className="text-[10px] font-mono uppercase tracking-wider text-[#FFE088] block">
                  Grand Prix Žilina 2026
                </span>
                <h4 className="text-sm font-serif font-bold text-white">Dospelí B — Štandardné tance</h4>
              </div>
              <div className="text-right">
                <span className="text-xs font-mono font-bold text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded border border-emerald-500/20">
                  2. Miesto (Finále)
                </span>
              </div>
            </div>

            {/* Advancement Progress Meter */}
            <div className="space-y-2 pt-1">
              <div className="flex justify-between items-center text-xs font-mono">
                <span className="text-zinc-400">Postup do triedy A</span>
                <span className="text-[#FFE088] font-bold">145 / 200 bodov</span>
              </div>
              <div className="w-full h-2 bg-zinc-800 rounded-full overflow-hidden">
                <div className="h-full bg-gradient-to-r from-[#FFE088] to-[#D4AF37] w-[72%]" />
              </div>
            </div>

            <div className="flex justify-between items-center text-[11px] font-mono text-zinc-400 pt-2 border-t border-zinc-800/80">
              <span>Finálové umiestnenia: 4 / 5</span>
              <span className="text-zinc-300">Zostáva: 55 b. + 1 finále</span>
            </div>
          </div>
        </div>

      </div>
    </section>
  )
}
