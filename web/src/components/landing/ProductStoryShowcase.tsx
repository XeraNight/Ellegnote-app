'use client'

import React, { useState } from 'react'

export default function ProductStoryShowcase() {
  // ── Chapter 1: 2D Canvas State ──
  const [selectedDance, setSelectedDance] = useState<'waltz' | 'chacha'>('waltz')
  const [selectedNode, setSelectedNode] = useState<number>(1)

  // ── Chapter 2: Audio Note Playing State ──
  const [isPlayingAudio, setIsPlayingAudio] = useState<boolean>(false)

  // ── Chapter 3: Video Scrubber State ──
  const [scrubberValue, setScrubberValue] = useState<number>(55)
  const [showPostureGuides, setShowPostureGuides] = useState<boolean>(true)

  const waltzNodes = [
    { id: 1, name: 'Natural Spin Turn', timing: '1 2 3', lod: '↗ LOD', footwork: 'T-H (Pán) • H-T (Dáma)' },
    { id: 2, name: 'Turning Lock to Right', timing: '1& 2 3', lod: '→ Stena', footwork: 'T-T-TH • C-Shape Sway' },
    { id: 3, name: 'Weave from PP', timing: '1 2 3 4 5 6', lod: '↖ Diagonála', footwork: 'T-H-T-T • Zníženie' },
  ]

  const chachaNodes = [
    { id: 1, name: 'Open Hip Twist', timing: '2 3 4& 1', lod: '↗ Vpred', footwork: 'Ball-Flat • Guapacha timing' },
    { id: 2, name: 'Hockey Stick', timing: '2 3 4& 1', lod: '→ Do strany', footwork: 'Pressure walk • Špirála' },
    { id: 3, name: 'New York to Left', timing: '2 3 4& 1', lod: '↖ Kontra', footwork: 'Check action • Voľná ruka' },
  ]

  const currentNodes = selectedDance === 'waltz' ? waltzNodes : chachaNodes
  const currentNode = currentNodes.find((n) => n.id === selectedNode) || currentNodes[0]

  return (
    <div className="relative z-10 space-y-32 md:space-y-44 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20">
      
      {/* ══════════════════════════════════════════════════════════════════
          ACT I: NEKONEČNÝ 2D PARKET (Choreografia & Priestor)
      ══════════════════════════════════════════════════════════════════ */}
      <section id="canvas" className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-16 items-center">
        {/* Left Column: Editorial Headline & Value */}
        <div className="lg:col-span-5 space-y-6">
          <div className="inline-flex items-center gap-2">
            <span className="text-[11px] font-sans font-black tracking-[0.2em] uppercase text-[#FFE088]">
              PRIESTOR & CHOREOGRAFIA
            </span>
          </div>

          <h2 className="text-3xl sm:text-4xl md:text-5xl font-serif font-bold text-white tracking-tight leading-[1.12]">
            Nekonečný 2D parket.{' '}
            <span className="bg-gradient-to-r from-[#FFF2CC] via-[#FFE088] to-[#D4AF37] bg-clip-text text-transparent block sm:inline">
              Každý krok na svojom mieste.
            </span>
          </h2>

          <p className="text-base text-zinc-300 leading-relaxed">
            Zaznamenaj zostavu presne tak, ako sa tancuje v sále. Smer pohybu (Line of Dance), stena, stred a prepojenia figúr plynulými krivkami. Obaja partneri odchádzajú z tréningu s identickou choreografiou.
          </p>

          {/* Dance Discipline Pill Switcher (Brand Guidelines §1A DanceMenuCapsule) */}
          <div className="pt-2 flex items-center gap-3">
            <button
              type="button"
              onClick={() => {
                setSelectedDance('waltz')
                setSelectedNode(1)
              }}
              className={`px-4 py-2 rounded-full text-xs font-bold tracking-wider uppercase transition-all duration-200 flex items-center gap-2 border ${
                selectedDance === 'waltz'
                  ? 'bg-white/10 text-white border-[#FFE088]/60 shadow-[0_0_15px_rgba(212,175,55,0.25)]'
                  : 'bg-black/30 text-zinc-400 border-white/5 hover:border-white/20'
              }`}
            >
              <span className="w-2 h-2 rounded-full bg-[#1E40AF]" />
              Štandard (Waltz)
            </button>

            <button
              type="button"
              onClick={() => {
                setSelectedDance('chacha')
                setSelectedNode(1)
              }}
              className={`px-4 py-2 rounded-full text-xs font-bold tracking-wider uppercase transition-all duration-200 flex items-center gap-2 border ${
                selectedDance === 'chacha'
                  ? 'bg-white/10 text-white border-[#E11D48]/60 shadow-[0_0_15px_rgba(225,29,72,0.25)]'
                  : 'bg-black/30 text-zinc-400 border-white/5 hover:border-white/20'
              }`}
            >
              <span className="w-2 h-2 rounded-full bg-[#E11D48]" />
              Latina (Cha-Cha)
            </button>
          </div>

          <div className="pt-4 border-t border-white/10 flex items-center gap-6 text-xs text-zinc-300">
            <span className="flex items-center gap-1.5">
              <span className="text-[#FFE088]">↗</span> Smer tanca (LOD)
            </span>
            <span className="flex items-center gap-1.5">
              <span className="text-[#FFE088]">●</span> Bezierove krivky
            </span>
            <span className="flex items-center gap-1.5">
              <span className="text-[#FFE088]">⚡</span> Zdieľanie cez QR kód
            </span>
          </div>
        </div>

        {/* Right Column: Interactive Theatrical 2D Floor */}
        <div className="lg:col-span-7">
          <div className="rounded-[24px] bg-[#1E0409]/80 border border-white/10 backdrop-blur-2xl p-6 sm:p-8 shadow-[0_20px_60px_rgba(0,0,0,0.6)] relative overflow-hidden group">
            
            {/* Top Stage Header */}
            <div className="flex items-center justify-between pb-4 border-b border-white/10 text-xs text-zinc-400">
              <div className="flex items-center gap-2">
                <span className={`w-2.5 h-2.5 rounded-full ${selectedDance === 'waltz' ? 'bg-[#1E40AF]' : 'bg-[#E11D48]'}`} />
                <span className="font-serif font-bold text-white tracking-wider">
                  {selectedDance === 'waltz' ? 'WALTZ • FINÁLOVÁ ZOSTAVA' : 'CHA-CHA • SÚŤAŽNÁ CHOREOGRAFIA'}
                </span>
              </div>
              <span className="font-mono text-[11px] text-[#FFE088]">3000 × 3000 pt PARKET</span>
            </div>

            {/* Interactive SVG Floor Visualization */}
            <div className="my-6 relative h-64 sm:h-72 w-full rounded-xl bg-black/40 border border-white/5 flex items-center justify-center overflow-hidden">
              {/* Floor Wood Grain / Grid Hint */}
              <div
                className="absolute inset-0 opacity-15"
                style={{
                  backgroundImage:
                    'radial-gradient(circle at 50% 50%, rgba(212, 175, 55, 0.15) 1px, transparent 1px)',
                  backgroundSize: '24px 24px',
                }}
              />

              {/* Choreography Path (Bezier Ribbon Curve) */}
              <svg className="absolute inset-0 w-full h-full" viewBox="0 0 500 250" fill="none">
                <path
                  d="M 60 180 C 140 60, 260 210, 440 80"
                  stroke={selectedDance === 'waltz' ? '#3B82F6' : '#E11D48'}
                  strokeWidth="3.5"
                  strokeDasharray="6 4"
                  className="opacity-70"
                />
                <path
                  d="M 60 180 C 140 60, 260 210, 440 80"
                  stroke="url(#pathGlow)"
                  strokeWidth="1.5"
                />
                <defs>
                  <linearGradient id="pathGlow" x1="0%" y1="0%" x2="100%" y2="0%">
                    <stop offset="0%" stopColor="#FFF2CC" />
                    <stop offset="50%" stopColor="#FFE088" />
                    <stop offset="100%" stopColor="#D4AF37" />
                  </linearGradient>
                </defs>
              </svg>

              {/* Interactive Nodes along the Dance Floor */}
              <div className="absolute inset-0 flex items-center justify-between px-10 sm:px-14">
                {currentNodes.map((node) => {
                  const isSelected = selectedNode === node.id
                  return (
                    <button
                      key={node.id}
                      type="button"
                      onClick={() => setSelectedNode(node.id)}
                      className={`relative group/node flex flex-col items-center transition-all duration-200 cursor-pointer ${
                        isSelected ? 'scale-110' : 'hover:scale-105 opacity-80'
                      }`}
                    >
                      <div
                        className={`w-11 h-11 rounded-full flex items-center justify-center font-bold text-xs transition-all shadow-xl ${
                          isSelected
                            ? 'bg-[#FFE088] text-black ring-4 ring-[#FFE088]/30 shadow-[0_0_20px_rgba(255,224,136,0.6)]'
                            : 'bg-[#180307] text-white border border-white/20 hover:border-[#FFE088]/50'
                        }`}
                      >
                        0{node.id}
                      </div>
                      <span className="text-[11px] font-semibold text-zinc-300 mt-2 max-w-[90px] text-center leading-tight truncate">
                        {node.name}
                      </span>
                      <span className="text-[9px] font-mono text-[#FFE088]/80">{node.lod}</span>
                    </button>
                  )
                })}
              </div>
            </div>

            {/* Selected Figure Micro-Detail (Brand Guidelines §4 1:1 Preview) */}
            <div className="rounded-xl bg-black/50 border border-white/10 p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
              <div>
                <div className="text-[10px] font-mono uppercase tracking-wider text-[#FFE088]">
                  Aktívna figúra #{selectedNode} • {currentNode.lod}
                </div>
                <div className="text-base font-serif font-bold text-white mt-0.5">
                  {currentNode.name}
                </div>
                <div className="text-xs text-zinc-400 mt-1">
                  Nášľap: <span className="text-zinc-200 font-medium">{currentNode.footwork}</span>
                </div>
              </div>

              <div className="flex items-center gap-2 self-start sm:self-center">
                <span className="px-3 py-1.5 rounded-lg bg-white/5 border border-white/10 text-xs font-mono font-bold text-[#FFE088]">
                  {currentNode.timing}
                </span>
              </div>
            </div>

          </div>
        </div>
      </section>


      {/* ══════════════════════════════════════════════════════════════════
          ACT II: TRÉNINGOVÁ ERGONÓMIA (1-Tap Diktát priamo pri parkete)
      ══════════════════════════════════════════════════════════════════ */}
      <section id="workflow" className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-16 items-center">
        {/* Left Column: Interactive Authentic Figure Card (§4 Architecture) */}
        <div className="lg:col-span-7 order-2 lg:order-1">
          <div className="rounded-[24px] bg-[#220409]/90 border border-white/10 backdrop-blur-2xl p-6 sm:p-8 shadow-[0_20px_60px_rgba(0,0,0,0.6)] space-y-6">
            
            {/* Figure Card Top Bar */}
            <div className="flex items-center justify-between text-xs pb-3 border-b border-white/10">
              <div className="flex items-center gap-2">
                <span className="w-2.5 h-2.5 rounded-full bg-[#1E40AF]" />
                <span className="font-serif font-bold text-white">WALTZ • Figúra #03</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="px-2 py-0.5 rounded bg-white/5 border border-white/10 font-mono text-[10px] text-[#FFE088]">
                  [ 1 2 3 ]
                </span>
                <span className="font-mono text-[10px] text-zinc-400">↗ LOD</span>
              </div>
            </div>

            {/* Figure Title & Quick Note */}
            <div>
              <div className="flex items-center justify-between">
                <h3 className="text-2xl font-serif font-bold text-white">
                  Natural Spin Turn
                </h3>
                <div className="text-xs text-[#FFE088]">★★★★★</div>
              </div>
              <p className="text-xs text-zinc-300 mt-1 leading-relaxed">
                Pravá noha vpred, zníženie a silná rotácia 3/8 vpravo do rohu sály.
              </p>
            </div>

            {/* Technical Attribute Badges (Brand Guidelines §4) */}
            <div className="flex flex-wrap gap-2 text-[11px] font-mono">
              <span className="px-2.5 py-1 rounded-md bg-white/5 border border-white/10 text-zinc-200">
                🦶 T-H (Pán)
              </span>
              <span className="px-2.5 py-1 rounded-md bg-white/5 border border-white/10 text-zinc-200">
                🦶 H-T (Dáma)
              </span>
              <span className="px-2.5 py-1 rounded-md bg-white/5 border border-white/10 text-[#FFE088]">
                📐 Náklon: Vpravo
              </span>
            </div>

            {/* Interactive Audio Note from Coach (Micro-interaction with wave animation) */}
            <div className="rounded-xl bg-black/60 border border-[#FFE088]/20 p-4 space-y-3">
              <div className="flex items-center justify-between text-xs">
                <div className="flex items-center gap-2">
                  <span className="text-sm">🎙️</span>
                  <span className="font-semibold text-white">Hlasová poznámka trénera</span>
                </div>
                <span className="text-[10px] font-mono text-zinc-400">Dnes 10:14 • V sále</span>
              </div>

              {/* The Audio Player Bar */}
              <div className="flex items-center gap-3">
                <button
                  type="button"
                  onClick={() => setIsPlayingAudio(!isPlayingAudio)}
                  className="w-10 h-10 rounded-full bg-[#FFE088] text-black font-black flex items-center justify-center hover:scale-105 active:scale-95 transition-all shadow-[0_0_15px_rgba(255,224,136,0.4)]"
                  aria-label={isPlayingAudio ? 'Zastaviť poznámku' : 'Prehrať poznámku'}
                >
                  {isPlayingAudio ? '⏸' : '▶'}
                </button>

                {/* Animated Audio Waveform */}
                <div className="flex-1 flex items-center gap-1 h-6">
                  {[40, 75, 50, 90, 60, 30, 85, 45, 95, 70, 35, 80, 50, 65, 40, 85, 55, 30].map((h, i) => (
                    <div
                      key={i}
                      className={`flex-1 rounded-full transition-all duration-200 ${
                        isPlayingAudio
                          ? 'bg-[#FFE088] animate-pulse'
                          : 'bg-white/20'
                      }`}
                      style={{
                        height: isPlayingAudio ? `${Math.max(20, (h * (i % 2 === 0 ? 1.2 : 0.8)) % 100)}%` : `${h * 0.4}%`,
                      }}
                    />
                  ))}
                </div>

                <span className="text-xs font-mono text-zinc-400">00:14</span>
              </div>

              <p className="text-xs text-zinc-300 italic pt-1">
                „Silnejší tlak do stojnej nohy na 1, udržať hlavu vľavo a nepredbiehať dámu v rotácii.“
              </p>
            </div>

            {/* Instant Partner Sync Status */}
            <div className="flex items-center justify-between text-xs text-zinc-400 pt-2 border-t border-white/5">
              <span className="flex items-center gap-1.5 text-emerald-400">
                <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping" />
                Synchronizované s partnerom
              </span>
              <span className="font-mono text-[10px]">Realtime WebSocket</span>
            </div>

          </div>
        </div>

        {/* Right Column: Editorial Copy */}
        <div className="lg:col-span-5 space-y-6 order-1 lg:order-2">
          <div className="inline-flex items-center gap-2">
            <span className="text-[11px] font-sans font-black tracking-[0.2em] uppercase text-[#FFE088]">
              TRÉNINGOVÁ ERGONÓMIA
            </span>
          </div>

          <h2 className="text-3xl sm:text-4xl md:text-5xl font-serif font-bold text-white tracking-tight leading-[1.12]">
            Zídeš z parketu.{' '}
            <span className="bg-gradient-to-r from-[#FFF2CC] via-[#FFE088] to-[#D4AF37] bg-clip-text text-transparent block sm:inline">
              Diktuješ. Uložené.
            </span>
          </h2>

          <p className="text-base text-zinc-300 leading-relaxed">
            Spotené ruky na tréningu a len 60 sekúnd na vydýchanie? Žiadne písanie na virtuálnej klávesnici ani listovanie v papierových zošitoch. Jediný dotyk na mikrofón a slová trénera sa okamžite prepíšu k figúre.
          </p>

          <div className="space-y-3 pt-2 text-sm text-zinc-200">
            <div className="flex items-start gap-3">
              <span className="text-[#FFE088] font-bold">✓</span>
              <span><strong>Hands-free diktovanie:</strong> Slovenský prepis hovoreného slova v sále.</span>
            </div>
            <div className="flex items-start gap-3">
              <span className="text-[#FFE088] font-bold">✓</span>
              <span><strong>Automatické priradenie:</strong> Poznámka sa uloží priamo k danej figúre a tancu.</span>
            </div>
            <div className="flex items-start gap-3">
              <span className="text-[#FFE088] font-bold">✓</span>
              <span><strong>Spoločná pamäť:</strong> Partner vidí novú figúru na svojom mobile v tej istej sekunde.</span>
            </div>
          </div>
        </div>
      </section>


      {/* ══════════════════════════════════════════════════════════════════
          ACT III: VIDEO DUEL (Objektívne Porovnanie Tanca)
      ══════════════════════════════════════════════════════════════════ */}
      <section id="duel" className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-16 items-center">
        {/* Left Column: Editorial Copy */}
        <div className="lg:col-span-5 space-y-6">
          <div className="inline-flex items-center gap-2">
            <span className="text-[11px] font-sans font-black tracking-[0.2em] uppercase text-[#FFE088]">
              POROVNANIE VIDEÍ
            </span>
          </div>

          <h2 className="text-3xl sm:text-4xl md:text-5xl font-serif font-bold text-white tracking-tight leading-[1.12]">
            Tvoj pohyb vs. vzor.{' '}
            <span className="bg-gradient-to-r from-[#FFF2CC] via-[#FFE088] to-[#D4AF37] bg-clip-text text-transparent block sm:inline">
              Vedľa seba.
            </span>
          </h2>

          <p className="text-base text-zinc-300 leading-relaxed">
            Pusť si svoje video z lekcie a trénerov vzor súčasne so zladeným začiatkom. Okamžite vidíš, kde strácaš držanie rámu, sklon tela alebo rotáciu. Žiadne dohady, len objektívny obraz.
          </p>

          <div className="pt-2 flex items-center gap-3">
            <button
              type="button"
              onClick={() => setShowPostureGuides(!showPostureGuides)}
              className="px-4 py-2 rounded-full text-xs font-bold tracking-wider uppercase transition-all duration-200 border bg-white/10 text-white border-[#FFE088]/40 hover:border-[#FFE088]"
            >
              {showPostureGuides ? '✓ Čiary postúry zapnuté' : '○ Zapnúť vodiace čiary'}
            </button>
          </div>
        </div>

        {/* Right Column: Interactive Dual Video Player */}
        <div className="lg:col-span-7">
          <div className="rounded-[24px] bg-[#1E0409]/80 border border-white/10 backdrop-blur-2xl p-6 sm:p-8 shadow-[0_20px_60px_rgba(0,0,0,0.6)] space-y-6">
            
            {/* Dual Screen Simulator */}
            <div className="grid grid-cols-2 gap-3 sm:gap-4">
              {/* Screen A: Moje video */}
              <div className="rounded-xl bg-black/60 border border-white/10 p-3 sm:p-4 aspect-[4/5] flex flex-col justify-between relative overflow-hidden">
                <div className="flex items-center justify-between text-[10px] font-mono text-zinc-300">
                  <span className="px-2 py-0.5 rounded bg-white/10 font-bold">A · Moje video</span>
                  <span>Slowfox</span>
                </div>

                {/* Silhouette simulation & posture guide */}
                <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
                  {showPostureGuides && (
                    <div className="w-px h-3/4 bg-[#FFE088]/60 shadow-[0_0_8px_rgba(255,224,136,0.8)]" />
                  )}
                  <span className="text-4xl opacity-30">🕺</span>
                </div>

                <div className="text-[10px] font-mono text-zinc-400 text-center">
                  Čas: 00:0{Math.floor(scrubberValue / 10)}.{scrubberValue % 10}s
                </div>
              </div>

              {/* Screen B: Trénerov vzor */}
              <div className="rounded-xl bg-black/60 border border-[#FFE088]/30 p-3 sm:p-4 aspect-[4/5] flex flex-col justify-between relative overflow-hidden shadow-[0_0_20px_rgba(212,175,55,0.1)]">
                <div className="flex items-center justify-between text-[10px] font-mono text-[#FFE088]">
                  <span className="px-2 py-0.5 rounded bg-[#FFE088]/20 font-bold">B · Vzor trénera</span>
                  <span>Slowfox</span>
                </div>

                {/* Silhouette simulation & posture guide */}
                <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
                  {showPostureGuides && (
                    <div className="w-px h-3/4 bg-[#FFE088]/90 shadow-[0_0_10px_rgba(255,224,136,0.9)]" />
                  )}
                  <span className="text-4xl opacity-40">🏆</span>
                </div>

                <div className="text-[10px] font-mono text-[#FFE088] text-center font-bold">
                  Offset: 0.00s (Synchrónne)
                </div>
              </div>
            </div>

            {/* Synchronized Scrubber */}
            <div className="space-y-2 pt-2">
              <div className="flex items-center justify-between text-xs text-zinc-300 font-mono">
                <span>Spoločný posuvník</span>
                <span className="text-[#FFE088]">
                  {Math.floor(scrubberValue / 10)}.{scrubberValue % 10}s / 12.0s
                </span>
              </div>
              <input
                type="range"
                min="0"
                max="120"
                value={scrubberValue}
                onChange={(e) => setScrubberValue(Number(e.target.value))}
                className="w-full accent-[#FFE088] cursor-pointer"
              />
            </div>

          </div>
        </div>
      </section>


      {/* ══════════════════════════════════════════════════════════════════
          ACT IV: SÚŤAŽNÝ REGISTER KSIS (SZTŠ)
      ══════════════════════════════════════════════════════════════════ */}
      <section id="ksis" className="rounded-[28px] bg-[#1A0307]/90 border border-[#FFE088]/20 backdrop-blur-2xl p-8 sm:p-12 shadow-[0_20px_60px_rgba(0,0,0,0.7)] text-center max-w-4xl mx-auto space-y-6">
        <div className="inline-flex items-center gap-2">
          <span className="text-[11px] font-sans font-black tracking-[0.2em] uppercase text-[#FFE088]">
            OFICIÁLNY REGISTER SZTŠ (KSIS.EU)
          </span>
        </div>

        <h2 className="text-3xl sm:text-4xl md:text-5xl font-serif font-bold text-white tracking-tight leading-[1.15]">
          Reálne súťažné body.{' '}
          <span className="bg-gradient-to-r from-[#FFF2CC] via-[#FFE088] to-[#D4AF37] bg-clip-text text-transparent block sm:inline">
            Žiadne vymyslené pravidlá.
          </span>
        </h2>

        <p className="text-base text-zinc-300 max-w-2xl mx-auto leading-relaxed">
          Prepojenie s oficiálnou databázou Slovenského zväzu tanečného športu. Postupové body, finálové umiestnenia a výkonnostné triedy bez manuálneho prepočítavania.
        </p>

        {/* Clean Live Metric Pills */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 pt-4">
          <div className="rounded-xl bg-black/50 border border-white/10 p-5 space-y-1">
            <span className="text-[11px] font-mono uppercase text-zinc-400">Postupové body</span>
            <div className="text-2xl font-serif font-bold text-[#FFE088]">142 b.</div>
            <span className="text-[10px] text-zinc-400">Overené v KSIS</span>
          </div>

          <div className="rounded-xl bg-black/50 border border-white/10 p-5 space-y-1">
            <span className="text-[11px] font-mono uppercase text-zinc-400">Finálové umiestnenia</span>
            <div className="text-2xl font-serif font-bold text-white">4× Finále</div>
            <span className="text-[10px] text-zinc-400">Oficiálne súťaže SZTŠ</span>
          </div>

          <div className="rounded-xl bg-black/50 border border-white/10 p-5 space-y-1">
            <span className="text-[11px] font-mono uppercase text-zinc-400">Kategória páru</span>
            <div className="text-2xl font-serif font-bold text-[#FFE088]">Dospelí B → A</div>
            <span className="text-[10px] text-zinc-400">Podľa súťažného poriadku</span>
          </div>
        </div>
      </section>

    </div>
  )
}
