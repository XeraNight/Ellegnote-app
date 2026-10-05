'use client'

import React, { useState } from 'react'

export default function BentoFeatures() {
  const [bentoFilter, setBentoFilter] = useState<'all' | 'standard' | 'latin'>('all')

  return (
    <section id="features" className="py-28 relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      
      {/* ── Section Header ────────────────────────────────────────── */}
      <div className="text-center max-w-3xl mx-auto mb-20 space-y-4">
        <div className="badge-gold mx-auto">
          <span className="w-1.5 h-1.5 rounded-full bg-[#FFE088] animate-pulse" />
          <span>Architektúra pre šampiónov</span>
        </div>

        <h2 className="text-3xl sm:text-5xl lg:text-6xl font-serif font-black tracking-tight text-white leading-tight">
          Všetko, čo profesionálny pár potrebuje.{' '}
          <span className="bg-gradient-to-r from-[#FFF2CC] via-[#FFE088] to-[#D4AF37] bg-clip-text text-transparent block sm:inline">
            Na jednom mieste.
          </span>
        </h2>

        <p className="text-sm sm:text-base text-zinc-300 max-w-2xl mx-auto">
          Zabudnite na papierové zošity a stovky neprehľadných videí v galérii. Encore prepája choreografiu, video rozbor, rytmus a súťažné dáta do jedného dokonale zosúladeného celku.
        </p>
      </div>

      {/* ── High-Craft Bento Grid (Unified Obsidian & Gold System) ── */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        
        {/* CARD 1: 2D Parket Canvas (2 cols) */}
        <div className="md:col-span-2 rounded-[32px] p-8 sm:p-10 surface-obsidian relative overflow-hidden flex flex-col justify-between group">
          <div className="space-y-4 z-10 max-w-xl">
            <div className="flex items-center gap-3">
              <span className="badge-gold">
                Choreografia & Priestor
              </span>
              <span className="text-[11px] font-mono text-zinc-500">60 / 120 FPS Metal</span>
            </div>

            <h3 className="text-2xl sm:text-4xl font-serif font-bold text-white">
              Nekonečný 2D Parket s Bezierovými krivkami
            </h3>

            <p className="text-xs sm:text-sm text-zinc-300 leading-relaxed">
              Zaznamenajte svoju zostavu presne tak, ako sa tancuje v sále. Definujte smer pohybu (Line of Dance), rohy tancodromu, uhly nášľapov, rytmické doby (SQQ, 1 2 3) a prepojte jednotlivé figúry plynulými krivkami. Partner aj tréner vidia každý detail.
            </p>
          </div>

          {/* Interactive Mini Parquet Visualizer */}
          <div className="mt-8 p-5 rounded-2xl bg-[#0A0A0A] border border-white/10 z-10 space-y-4">
            <div className="flex justify-between items-center text-xs">
              <div className="flex gap-2">
                <button
                  onClick={() => setBentoFilter('all')}
                  className={`px-3 py-1 rounded-full font-mono text-[10px] font-bold transition-all ${
                    bentoFilter === 'all'
                      ? 'bg-[#FFE088] text-black shadow-sm'
                      : 'bg-white/5 text-zinc-400 hover:text-white'
                  }`}
                >
                  Všetky tance (10)
                </button>
                <button
                  onClick={() => setBentoFilter('standard')}
                  className={`px-3 py-1 rounded-full font-mono text-[10px] font-bold transition-all ${
                    bentoFilter === 'standard'
                      ? 'bg-[#FFE088] text-black shadow-sm'
                      : 'bg-white/5 text-zinc-400 hover:text-white'
                  }`}
                >
                  Štandard (W, T, V, SF, Q)
                </button>
                <button
                  onClick={() => setBentoFilter('latin')}
                  className={`px-3 py-1 rounded-full font-mono text-[10px] font-bold transition-all ${
                    bentoFilter === 'latin'
                      ? 'bg-[#FFE088] text-black shadow-sm'
                      : 'bg-white/5 text-zinc-400 hover:text-white'
                  }`}
                >
                  Latina (S, CH, R, P, J)
                </button>
              </div>
              <span className="text-[11px] font-mono text-[#FFE088]">3000 pt Tancodrom</span>
            </div>

            {/* Parquet stats strip */}
            <div className="grid grid-cols-3 gap-3 text-center pt-2 border-t border-zinc-800/80">
              <div className="p-2.5 rounded-xl bg-[#141418] border border-white/5">
                <span className="text-xl sm:text-2xl font-mono font-bold text-[#FFE088]">100+</span>
                <span className="text-[10px] text-zinc-400 block mt-0.5">WDSF Figúr v knižnici</span>
              </div>
              <div className="p-2.5 rounded-xl bg-[#141418] border border-white/5">
                <span className="text-xl sm:text-2xl font-mono font-bold text-[#FFE088]">&lt; 50 ms</span>
                <span className="text-[10px] text-zinc-400 block mt-0.5">WebSocket Latencia</span>
              </div>
              <div className="p-2.5 rounded-xl bg-[#141418] border border-white/5">
                <span className="text-xl sm:text-2xl font-mono font-bold text-[#FFE088]">1-Tap QR</span>
                <span className="text-[10px] text-zinc-400 block mt-0.5">Zdieľanie s partnerom</span>
              </div>
            </div>
          </div>
        </div>

        {/* CARD 2: Video Duel & Slo-Mo (1 col) */}
        <div className="rounded-[32px] p-8 surface-obsidian relative overflow-hidden flex flex-col justify-between group">
          <div className="space-y-4 z-10">
            <span className="badge-gold">
              Technická Analýza
            </span>

            <h3 className="text-2xl sm:text-3xl font-serif font-bold text-white">
              Video Duel & Slo-Mo 120/240 FPS
            </h3>

            <p className="text-xs sm:text-sm text-zinc-300 leading-relaxed">
              Pustite si svoj záznam a video majstra sveta alebo trénera vedľa seba. Jediný spoločný posuvník času a krokovanie po snímkach odhalí každú chybu v nášľape či držaní tela.
            </p>
          </div>

          <div className="mt-8 p-4 rounded-2xl bg-[#0A0A0A] border border-white/10 space-y-3 z-10">
            <div className="flex justify-between items-center text-xs font-mono">
              <span className="text-zinc-400">Synchronizovaný posun</span>
              <span className="text-[#FFE088] font-bold">120 FPS Slo-Mo</span>
            </div>
            <div className="w-full h-1.5 bg-zinc-800 rounded-full overflow-hidden">
              <div className="h-full bg-gradient-to-r from-[#FFE088] to-[#D4AF37] w-2/3" />
            </div>
            <div className="flex justify-between text-[10px] font-mono text-zinc-400">
              <span>Uhol chrbtice: 14°</span>
              <span className="text-[#FFE088] font-bold">Vzor: 0° (Vertikála)</span>
            </div>
          </div>
        </div>

        {/* CARD 3: Syntetický PCM Metronóm & Pitch Trainer */}
        <div className="rounded-[32px] p-8 surface-obsidian relative overflow-hidden flex flex-col justify-between group">
          <div className="space-y-4 z-10">
            <span className="badge-gold">
              Rytmus & Svalová Pamäť
            </span>

            <h3 className="text-2xl sm:text-3xl font-serif font-bold text-white">
              Syntetický PCM Metronóm & Pitch
            </h3>

            <p className="text-xs sm:text-sm text-zinc-300 leading-relaxed">
              Žiadne MP3 súbory ani oneskorenie na Bluetooth reproduktore. Klik generuje audio engine priamo v RAM s presnosťou na vzorku. Spomaľte hudbu na 80 % bez zmeny tóniny alebo zrýchlite na 105 % pre finále.
            </p>
          </div>

          <div className="mt-8 p-4 rounded-2xl bg-[#0A0A0A] border border-white/10 z-10 space-y-2.5">
            <div className="flex justify-between text-xs font-mono">
              <span className="text-zinc-400">Bluetooth Latencia</span>
              <span className="text-[#FFE088] font-bold">0.00 ms (Zero Lag)</span>
            </div>
            <div className="flex justify-between text-xs font-mono">
              <span className="text-zinc-400">Tempo Trainer</span>
              <span className="text-[#FFE088] font-bold">80 % – 110 % Pitch</span>
            </div>
          </div>
        </div>

        {/* CARD 4: SZTŠ & ksis.eu Výkonnostný Radar */}
        <div className="rounded-[32px] p-8 surface-obsidian relative overflow-hidden flex flex-col justify-between group">
          <div className="space-y-4 z-10">
            <span className="badge-gold">
              Súťažný Rebríček
            </span>

            <h3 className="text-2xl sm:text-3xl font-serif font-bold text-white">
              SZTŠ & ksis.eu Výkonnostný Radar
            </h3>

            <p className="text-xs sm:text-sm text-zinc-300 leading-relaxed">
              Zadajte číslo páru a Encore automaticky načíta Vaše finálové umiestnenia, postupové body a rozstrely. Presne viete, koľko bodov chýba do postupu do vyššej výkonnostnej triedy.
            </p>
          </div>

          <div className="mt-8 p-4 rounded-2xl bg-[#0A0A0A] border border-white/10 z-10 space-y-2.5">
            <div className="flex justify-between text-xs font-mono">
              <span className="text-zinc-400">Postupový rebríček</span>
              <span className="text-[#FFE088] font-bold">Triedy D ➔ S</span>
            </div>
            <div className="w-full h-1.5 bg-zinc-800 rounded-full overflow-hidden">
              <div className="h-full bg-gradient-to-r from-[#FFE088] to-[#D4AF37] w-3/4" />
            </div>
            <span className="text-[10px] text-zinc-400 block text-right font-mono">
              145 / 200 b. (4/5 finále)
            </span>
          </div>
        </div>

        {/* CARD 5: Apple Wallet & Live Activities */}
        <div className="rounded-[32px] p-8 surface-obsidian relative overflow-hidden flex flex-col justify-between group">
          <div className="space-y-4 z-10">
            <span className="badge-gold">
              Apple Ekosystém
            </span>

            <h3 className="text-2xl sm:text-3xl font-serif font-bold text-white">
              Apple Wallet Preukaz & Dynamic Island
            </h3>

            <p className="text-xs sm:text-sm text-zinc-300 leading-relaxed">
              Váš oficiálny digitálny tanečný preukaz priamo v Apple Peňaženke s QR kódom na okamžité prepojenie s partnerom. Počas tréningu beží metronóm v Dynamic Islande a na zamknutej ploche.
            </p>
          </div>

          {/* Styled Apple Wallet Pass Card */}
          <div className="mt-8 p-4 rounded-2xl bg-[#0A0A0A] border border-[#FFE088]/25 shadow-xl flex items-center justify-between z-10">
            <div className="space-y-1">
              <span className="text-[9px] font-mono text-[#FFE088] uppercase tracking-wider block">
                Apple Wallet Pass
              </span>
              <p className="text-xs font-serif font-bold text-white">Tanečný Preukaz SZTŠ</p>
              <span className="text-[10px] text-zinc-400 font-mono">ID #SK-84920</span>
            </div>
            <div className="w-10 h-10 rounded-xl bg-white p-1 shadow-md">
              <div className="w-full h-full bg-black rounded-lg flex items-center justify-center text-white text-[9px] font-mono font-bold">
                QR
              </div>
            </div>
          </div>
        </div>

      </div>
    </section>
  )
}
