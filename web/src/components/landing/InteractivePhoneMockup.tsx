'use client'

import React, { useState, useEffect, useRef } from 'react'

type MockupTab = 'canvas' | 'video' | 'metronome' | 'planner'

export default function InteractivePhoneMockup() {
  const [activeTab, setActiveTab] = useState<MockupTab>('canvas')
  const [selectedNode, setSelectedNode] = useState<number | null>(1)
  const [isPlayingMetronome, setIsPlayingMetronome] = useState<boolean>(false)
  const [tempoMPM, setTempoMPM] = useState<number>(29)
  const [currentBeat, setCurrentBeat] = useState<number>(1)
  const [videoScrub, setVideoScrub] = useState<number>(45)
  const [showBodyAngles, setShowBodyAngles] = useState<boolean>(true)
  const [rsvpState, setRsvpState] = useState<'idle' | 'attending' | 'skipped'>('attending')
  const [plannerSubTab, setPlannerSubTab] = useState<'regime' | 'ksis'>('regime')
  const [dynamicIslandExpanded, setDynamicIslandExpanded] = useState<boolean>(false)

  // 3D Parallax tilt effect on mouse hover
  const frameRef = useRef<HTMLDivElement>(null)
  const [tilt, setTilt] = useState<{ x: number; y: number }>({ x: 0, y: 0 })

  const handleMouseMove = (e: React.MouseEvent<HTMLDivElement>) => {
    if (!frameRef.current) return
    const rect = frameRef.current.getBoundingClientRect()
    const x = e.clientX - rect.left - rect.width / 2
    const y = e.clientY - rect.top - rect.height / 2
    setTilt({
      x: (y / (rect.height / 2)) * -6,
      y: (x / (rect.width / 2)) * 6,
    })
  }

  const handleMouseLeave = () => {
    setTilt({ x: 0, y: 0 })
  }

  // Audio Context Metronome Engine (Synthetic PCM Web Audio)
  useEffect(() => {
    let interval: NodeJS.Timeout | null = null
    if (isPlayingMetronome) {
      // 29 MPM in 3/4 = 87 beats per minute -> interval = (60 / (tempoMPM * 3)) * 1000
      const intervalMs = (60 / (tempoMPM * 3)) * 1000
      interval = setInterval(() => {
        setCurrentBeat((prev) => {
          const next = prev >= 3 ? 1 : prev + 1
          // Play synthetic click with Web Audio API if available
          try {
            const AudioContext = window.AudioContext || (window as unknown as { webkitAudioContext: typeof window.AudioContext }).webkitAudioContext
            if (AudioContext) {
              const ctx = new AudioContext()
              const osc = ctx.createOscillator()
              const gain = ctx.createGain()
              osc.type = 'sine'
              // Beat 1 higher pitch (880Hz), Beats 2 & 3 lower (440Hz)
              osc.frequency.setValueAtTime(next === 1 ? 880 : 440, ctx.currentTime)
              gain.gain.setValueAtTime(0.12, ctx.currentTime)
              gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.08)
              osc.connect(gain)
              gain.connect(ctx.destination)
              osc.start()
              osc.stop(ctx.currentTime + 0.09)
            }
          } catch {
            // AudioContext muted or blocked by browser policy
          }
          return next
        })
      }, intervalMs)
    } else {
      setCurrentBeat(1)
    }
    return () => {
      if (interval) clearInterval(interval)
    }
  }, [isPlayingMetronome, tempoMPM])

  return (
    <div className="w-full flex flex-col items-center">
      
      {/* ── Top Module Selector Pill Bar ────────────────────────────── */}
      <div className="flex flex-wrap justify-center items-center gap-2 mb-10 p-1.5 rounded-full bg-[#100f16]/90 border border-[#D4AF37]/30 backdrop-blur-2xl shadow-[0_10px_30px_rgba(0,0,0,0.8)] max-w-2xl">
        <button
          onClick={() => setActiveTab('canvas')}
          className={`px-5 py-2.5 rounded-full text-xs font-bold transition-all flex items-center gap-2 ${
            activeTab === 'canvas'
              ? 'bg-gradient-to-r from-[#FFF2CC] via-[#FFE088] to-[#D4AF37] text-black shadow-[0_0_20px_rgba(212,175,55,0.45)]'
              : 'text-zinc-400 hover:text-white'
          }`}
        >
          <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2">
            <rect x="3" y="3" width="18" height="18" rx="2" />
            <path d="M3 9h18M9 21V9" />
          </svg>
          <span>2D Parket</span>
        </button>

        <button
          onClick={() => setActiveTab('video')}
          className={`px-5 py-2.5 rounded-full text-xs font-bold transition-all flex items-center gap-2 ${
            activeTab === 'video'
              ? 'bg-gradient-to-r from-[#FFF2CC] via-[#FFE088] to-[#D4AF37] text-black shadow-[0_0_20px_rgba(212,175,55,0.45)]'
              : 'text-zinc-400 hover:text-white'
          }`}
        >
          <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2">
            <rect x="2" y="2" width="20" height="20" rx="3" />
            <path d="M12 2v20M7 7l10 10" />
          </svg>
          <span>Video Duel</span>
        </button>

        <button
          onClick={() => setActiveTab('metronome')}
          className={`px-5 py-2.5 rounded-full text-xs font-bold transition-all flex items-center gap-2 ${
            activeTab === 'metronome'
              ? 'bg-gradient-to-r from-[#FFF2CC] via-[#FFE088] to-[#D4AF37] text-black shadow-[0_0_20px_rgba(212,175,55,0.45)]'
              : 'text-zinc-400 hover:text-white'
          }`}
        >
          <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2">
            <circle cx="12" cy="12" r="9" />
            <path d="M12 7v5l3 3" />
          </svg>
          <span>Metronóm</span>
        </button>

        <button
          onClick={() => setActiveTab('planner')}
          className={`px-5 py-2.5 rounded-full text-xs font-bold transition-all flex items-center gap-2 ${
            activeTab === 'planner'
              ? 'bg-gradient-to-r from-[#FFF2CC] via-[#FFE088] to-[#D4AF37] text-black shadow-[0_0_20px_rgba(212,175,55,0.45)]'
              : 'text-zinc-400 hover:text-white'
          }`}
        >
          <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2">
            <rect x="3" y="4" width="18" height="18" rx="2" />
            <path d="M16 2v4M8 2v4M3 10h18" />
          </svg>
          <span>Plán & KSIS</span>
        </button>
      </div>

      {/* ── Realistic iPhone 16 Pro Titanium Chassis ─────────────────── */}
      <div
        ref={frameRef}
        onMouseMove={handleMouseMove}
        onMouseLeave={handleMouseLeave}
        style={{
          transform: `perspective(1000px) rotateX(${tilt.x}deg) rotateY(${tilt.y}deg)`,
          transition: 'transform 0.15s ease-out',
        }}
        className="relative w-[320px] sm:w-[370px] aspect-[9/19.5] rounded-[54px] p-3.5 bg-gradient-to-b from-[#3a3745] via-[#23212b] to-[#14131a] shadow-[0_30px_90px_rgba(0,0,0,0.95),0_0_50px_rgba(212,175,55,0.22)] border-[3.5px] border-[#4a4756] cursor-pointer"
      >
        {/* Left Side Buttons (Action Button + Volume Rockers) */}
        <div className="absolute -left-[6px] top-28 w-[3.5px] h-7 bg-[#4a4756] rounded-l-md" />
        <div className="absolute -left-[6px] top-40 w-[3.5px] h-12 bg-[#4a4756] rounded-l-md" />
        <div className="absolute -left-[6px] top-56 w-[3.5px] h-12 bg-[#4a4756] rounded-l-md" />
        {/* Right Side Button (Power Button) */}
        <div className="absolute -right-[6px] top-36 w-[3.5px] h-16 bg-[#4a4756] rounded-r-md" />

        {/* Specular Edge Sheen (Titanium Finish) */}
        <div className="absolute inset-0 rounded-[50px] border border-[#FFE088]/25 pointer-events-none" />

        {/* ── OLED Display Screen ──────────────────────────────────── */}
        <div className="relative w-full h-full rounded-[44px] bg-[#07070a] overflow-hidden flex flex-col justify-between border border-black text-white select-none shadow-inner">
          
          {/* Status Bar & Interactive Dynamic Island */}
          <div className="pt-3.5 px-6 flex justify-between items-center text-[11px] font-medium text-zinc-400 z-40 relative">
            <span className="font-semibold tracking-tight">9:41</span>

            {/* Dynamic Island */}
            <div
              onClick={() => setDynamicIslandExpanded(!dynamicIslandExpanded)}
              className={`transition-all duration-300 bg-black border border-zinc-800/80 shadow-lg flex items-center justify-between cursor-pointer ${
                dynamicIslandExpanded
                  ? 'h-10 w-56 px-3 rounded-2xl bg-[#0d0c13]'
                  : 'h-6 w-28 px-2.5 rounded-full'
              }`}
            >
              {dynamicIslandExpanded ? (
                <div className="w-full flex items-center justify-between text-[10px]">
                  <div className="flex items-center gap-1.5">
                    <span className="w-2 h-2 rounded-full bg-[#FFE088] animate-ping" />
                    <span className="font-serif font-bold text-white">Slow Waltz</span>
                  </div>
                  <span className="text-[#FFE088] font-mono text-[9px]">29 MPM</span>
                </div>
              ) : (
                <>
                  <span className="w-2 h-2 rounded-full bg-[#D4AF37] animate-pulse" />
                  <span className="text-[9px] font-mono text-[#FFE088] tracking-wider font-bold">
                    {activeTab === 'metronome' ? `${tempoMPM} MPM` : 'ENCORE'}
                  </span>
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" />
                </>
              )}
            </div>

            <div className="flex items-center gap-1.5 text-[10px] font-mono">
              <span>5G</span>
              <div className="w-4 h-2 rounded-sm border border-zinc-400 p-0.5 flex items-center">
                <div className="w-full h-full bg-emerald-400 rounded-2xs" />
              </div>
            </div>
          </div>

          {/* Screen Content Container */}
          <div className="flex-1 px-4 py-2.5 flex flex-col justify-between overflow-hidden relative">
            
            {/* ═════════ TAB 1: 2D PARKET CANVAS ═════════ */}
            {activeTab === 'canvas' && (
              <div className="h-full flex flex-col justify-between animate-fadeIn space-y-2">
                <div className="flex items-center justify-between border-b border-zinc-800/90 pb-2">
                  <div>
                    <span className="text-[9px] font-mono uppercase text-[#D4AF37] tracking-wider">
                      Waltz • 3/4 • 29 MPM
                    </span>
                    <h4 className="text-xs font-serif font-bold text-white flex items-center gap-1.5">
                      Súťažná Variácia 2026
                      <span className="text-[9px] text-zinc-400 font-normal">#01</span>
                    </h4>
                  </div>
                  <div className="flex items-center gap-1 bg-[#1E40AF]/25 border border-[#1E40AF]/60 px-2 py-0.5 rounded-full text-[9px] text-blue-300 font-mono">
                    <span>LOD ↗</span>
                  </div>
                </div>

                {/* Parquet Simulation Area */}
                <div className="relative h-60 rounded-2xl bg-[#0a0a0f] border border-[#D4AF37]/30 p-2.5 overflow-hidden flex flex-col justify-between shadow-inner">
                  {/* Real parquet floor texture grid */}
                  <div className="absolute inset-0 opacity-20 bg-[radial-gradient(#D4AF37_1px,transparent_1px)] [background-size:14px_14px]" />
                  <div className="absolute top-2 right-2 text-[8px] font-mono text-zinc-600 uppercase tracking-widest">
                    Tancodrom 3000pt
                  </div>

                  {/* Bezier Path SVG */}
                  <svg className="absolute inset-0 w-full h-full pointer-events-none" viewBox="0 0 300 240">
                    <defs>
                      <linearGradient id="goldCurve" x1="0%" y1="0%" x2="100%" y2="100%">
                        <stop offset="0%" stopColor="#FFE088" />
                        <stop offset="50%" stopColor="#D4AF37" />
                        <stop offset="100%" stopColor="#8A6715" />
                      </linearGradient>
                    </defs>
                    <path
                      d="M 50 45 C 130 55, 120 125, 140 120 C 160 115, 230 160, 220 195"
                      fill="none"
                      stroke="url(#goldCurve)"
                      strokeWidth="2.5"
                      strokeDasharray="5 5"
                    />
                  </svg>

                  {/* Figure Node 1 */}
                  <div
                    onClick={() => setSelectedNode(1)}
                    className={`relative z-10 self-start p-2 rounded-xl transition-all cursor-pointer max-w-[155px] ${
                      selectedNode === 1
                        ? 'bg-[#1b1926] border-2 border-[#FFE088] shadow-[0_0_15px_rgba(212,175,55,0.4)] scale-105'
                        : 'bg-[#12111a] border border-zinc-800'
                    }`}
                  >
                    <div className="flex items-center justify-between text-[8px] text-[#FFE088] font-mono font-bold">
                      <span>#01 • LOD</span>
                      <span className="bg-[#D4AF37]/20 px-1 rounded text-white">1 2 3</span>
                    </div>
                    <p className="text-[10px] font-serif font-bold text-white leading-tight mt-0.5">
                      Natural Spin Turn
                    </p>
                    <div className="flex items-center gap-1 mt-1 text-[7.5px] text-zinc-400 font-mono">
                      <span className="bg-zinc-800 px-1 rounded text-zinc-300">T-H</span>
                      <span>Rotácia 3/8 R</span>
                    </div>
                  </div>

                  {/* Figure Node 2 */}
                  <div
                    onClick={() => setSelectedNode(2)}
                    className={`relative z-10 self-center p-2 rounded-xl transition-all cursor-pointer max-w-[155px] ${
                      selectedNode === 2
                        ? 'bg-[#1b1926] border-2 border-[#FFE088] shadow-[0_0_15px_rgba(212,175,55,0.4)] scale-105'
                        : 'bg-[#12111a] border border-zinc-800'
                    }`}
                  >
                    <div className="flex items-center justify-between text-[8px] text-[#FFE088] font-mono font-bold">
                      <span>#02 • Stena</span>
                      <span className="bg-[#D4AF37]/20 px-1 rounded text-white">1& 2 3</span>
                    </div>
                    <p className="text-[10px] font-serif font-bold text-white leading-tight mt-0.5">
                      Turning Lock to R
                    </p>
                    <div className="flex items-center gap-1 mt-1 text-[7.5px] text-zinc-400 font-mono">
                      <span className="bg-emerald-950 text-emerald-300 px-1 rounded border border-emerald-800">
                        C-Shape Sway
                      </span>
                    </div>
                  </div>

                  {/* Figure Node 3 */}
                  <div
                    onClick={() => setSelectedNode(3)}
                    className={`relative z-10 self-end p-2 rounded-xl transition-all cursor-pointer max-w-[155px] ${
                      selectedNode === 3
                        ? 'bg-[#1b1926] border-2 border-[#FFE088] shadow-[0_0_15px_rgba(212,175,55,0.4)] scale-105'
                        : 'bg-[#12111a] border border-zinc-800'
                    }`}
                  >
                    <div className="flex items-center justify-between text-[8px] text-[#FFE088] font-mono font-bold">
                      <span>#03 • Roh</span>
                      <span className="bg-[#D4AF37]/20 px-1 rounded text-white">1 2 3 4 5 6</span>
                    </div>
                    <p className="text-[10px] font-serif font-bold text-white leading-tight mt-0.5">
                      Weave from PP
                    </p>
                    <div className="flex items-center gap-1 mt-1 text-[7.5px] text-zinc-400 font-mono">
                      <span>Prechod do slowfoxu</span>
                    </div>
                  </div>
                </div>

                {/* Node Inspector Sheet Preview */}
                <div className="p-2.5 rounded-xl bg-[#121118] border border-[#D4AF37]/25 flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className="w-7 h-7 rounded-lg bg-[#D4AF37]/20 border border-[#D4AF37]/40 flex items-center justify-center text-xs">
                      🎙️
                    </div>
                    <div>
                      <span className="text-[8px] font-mono text-zinc-400 uppercase block">Trénerov komentár</span>
                      <span className="text-[10px] font-bold text-white">„Silnejší tlak do stojnej nohy na 1“</span>
                    </div>
                  </div>
                  <span className="text-[8px] font-mono text-[#FFE088] bg-[#D4AF37]/15 px-2 py-0.5 rounded-full font-bold">
                    00:14 HD
                  </span>
                </div>
              </div>
            )}

            {/* ═════════ TAB 2: VIDEO DUEL & MOTION ANALYSIS ═════════ */}
            {activeTab === 'video' && (
              <div className="h-full flex flex-col justify-between animate-fadeIn space-y-2">
                <div className="flex justify-between items-center border-b border-zinc-800/90 pb-2">
                  <div>
                    <span className="text-[9px] font-mono text-[#E11D48] uppercase tracking-wider font-bold">
                      Side-by-Side Dual Analysis
                    </span>
                    <h4 className="text-xs font-serif font-bold text-white">Slo-Mo Rozbor Postúry</h4>
                  </div>
                  <button
                    onClick={() => setShowBodyAngles(!showBodyAngles)}
                    className="text-[8.5px] font-mono px-2 py-0.5 rounded-full bg-[#E11D48]/20 text-[#E11D48] border border-[#E11D48]/50 font-bold"
                  >
                    {showBodyAngles ? '📐 Uhly: ZAPNUTÉ' : 'Uhly: VYPNUTÉ'}
                  </button>
                </div>

                {/* Dual Split Videos */}
                <div className="grid grid-cols-2 gap-2 h-44">
                  {/* Left: Your Training Recording */}
                  <div className="rounded-xl bg-[#121118] border border-zinc-800 p-2 flex flex-col justify-between relative overflow-hidden">
                    <span className="text-[8px] font-bold text-[#D4AF37] uppercase tracking-wider">
                      Váš tréning (Trnava)
                    </span>

                    {/* Posture Overlay */}
                    <div className="relative my-auto flex flex-col items-center">
                      <div className="w-9 h-9 rounded-full border border-dashed border-[#D4AF37]/50 flex items-center justify-center text-xs">
                        💃
                      </div>
                      {showBodyAngles && (
                        <div className="mt-1 px-1.5 py-0.5 rounded bg-black/70 border border-[#E11D48] text-[7.5px] text-[#E11D48] font-mono font-bold">
                          Uhol chrbtice: 14°
                        </div>
                      )}
                    </div>
                    <span className="text-[8px] font-mono text-zinc-500">00:04.12 • 120 FPS</span>
                  </div>

                  {/* Right: Master / Coach Reference */}
                  <div className="rounded-xl bg-[#180a0e] border border-[#E11D48]/40 p-2 flex flex-col justify-between relative overflow-hidden">
                    <span className="text-[8px] font-bold text-[#FFE088] uppercase tracking-wider">
                      Vzor / Majstri Sveta
                    </span>

                    {/* Posture Overlay */}
                    <div className="relative my-auto flex flex-col items-center">
                      <div className="w-9 h-9 rounded-full border border-[#FFE088]/50 bg-[#E11D48]/20 flex items-center justify-center text-xs text-[#FFE088]">
                        🏆
                      </div>
                      {showBodyAngles && (
                        <div className="mt-1 px-1.5 py-0.5 rounded bg-black/70 border border-emerald-500 text-[7.5px] text-emerald-400 font-mono font-bold">
                          Ideálna vertikála: 0°
                        </div>
                      )}
                    </div>
                    <span className="text-[8px] font-mono text-zinc-500">00:04.12 • 120 FPS</span>
                  </div>
                </div>

                {/* Common Scrubber Slider */}
                <div className="p-2.5 rounded-xl bg-zinc-900/80 border border-zinc-800 space-y-1.5">
                  <div className="flex justify-between text-[8px] text-zinc-400 font-mono">
                    <span>Frame {videoScrub * 3}</span>
                    <span className="text-[#FFE088] font-bold">Spoločný Frame-Scrubber</span>
                    <span>120 FPS</span>
                  </div>
                  <input
                    type="range"
                    min="0"
                    max="100"
                    value={videoScrub}
                    onChange={(e) => setVideoScrub(Number(e.target.value))}
                    className="w-full accent-[#D4AF37] h-1.5 bg-zinc-800 rounded-lg cursor-pointer"
                  />
                  <div className="flex justify-between items-center pt-1 text-[8px] text-zinc-400">
                    <button
                      onClick={() => setVideoScrub((p) => Math.max(0, p - 5))}
                      className="px-2 py-0.5 rounded bg-white/5 hover:bg-white/10"
                    >
                      ◀ 1 Frame
                    </button>
                    <span className="font-mono text-white text-[9px]">00:04.{videoScrub}</span>
                    <button
                      onClick={() => setVideoScrub((p) => Math.min(100, p + 5))}
                      className="px-2 py-0.5 rounded bg-white/5 hover:bg-white/10"
                    >
                      1 Frame ▶
                    </button>
                  </div>
                </div>
              </div>
            )}

            {/* ═════════ TAB 3: METRONÓM & PITCH TRAINER ═════════ */}
            {activeTab === 'metronome' && (
              <div className="h-full flex flex-col justify-between items-center text-center py-1 animate-fadeIn space-y-2">
                <div>
                  <span className="text-[8.5px] font-mono uppercase text-[#D4AF37] tracking-widest block">
                    Syntetický Audio Engine (0ms Lag)
                  </span>
                  <h4 className="text-xs font-serif font-bold text-white">Slow Waltz Metronóm</h4>
                </div>

                {/* Pulsating Metronome Dial */}
                <div
                  onClick={() => setIsPlayingMetronome(!isPlayingMetronome)}
                  className={`relative w-36 h-36 rounded-full border-4 transition-all flex flex-col items-center justify-center cursor-pointer ${
                    isPlayingMetronome
                      ? 'border-[#FFE088] shadow-[0_0_35px_rgba(212,175,55,0.4)] scale-105'
                      : 'border-[#D4AF37]/30 hover:border-[#D4AF37]/60'
                  }`}
                >
                  {/* Beat indicator ring */}
                  <div
                    className={`absolute inset-1.5 rounded-full border-2 border-dashed transition-all duration-200 ${
                      isPlayingMetronome
                        ? currentBeat === 1
                          ? 'border-[#FFE088] scale-110 shadow-lg'
                          : 'border-[#D4AF37]/50'
                        : 'border-zinc-800'
                    }`}
                  />
                  <span className="text-3xl font-mono font-black text-white">{tempoMPM}</span>
                  <span className="text-[9px] font-bold tracking-widest text-[#FFE088] uppercase">
                    MPM • 3/4
                  </span>
                  <span className="text-[8px] text-zinc-400 mt-0.5 font-mono">
                    {tempoMPM * 3} BPM
                  </span>

                  {/* Play / Pause Pill */}
                  <div className="mt-1 px-2.5 py-0.5 rounded-full bg-white/10 text-[8px] font-bold text-[#FFE088]">
                    {isPlayingMetronome ? '⏸ Pauza' : '▶ Spustiť'}
                  </div>
                </div>

                {/* Interactive Beat Visualizer Bar */}
                <div className="flex gap-2 justify-center">
                  {[1, 2, 3].map((b) => (
                    <div
                      key={b}
                      className={`w-9 h-6 rounded-lg flex items-center justify-center font-mono text-[10px] font-bold transition-all ${
                        isPlayingMetronome && currentBeat === b
                          ? 'bg-[#FFE088] text-black scale-110 shadow-md'
                          : 'bg-zinc-900 text-zinc-500 border border-zinc-800'
                      }`}
                    >
                      {b}
                    </div>
                  ))}
                </div>

                {/* Speed Pitch Box */}
                <div className="w-full p-2 rounded-xl bg-[#121118] border border-zinc-800 text-left">
                  <div className="flex justify-between text-[9px] text-zinc-400 font-bold mb-1">
                    <span>Tréningový posuvník tempa:</span>
                    <span className="text-[#FFE088] font-mono">{tempoMPM} MPM</span>
                  </div>
                  <input
                    type="range"
                    min="24"
                    max="34"
                    value={tempoMPM}
                    onChange={(e) => setTempoMPM(Number(e.target.value))}
                    className="w-full accent-[#D4AF37] h-1.5 bg-zinc-800 rounded-lg cursor-pointer"
                  />
                  <div className="flex justify-between text-[7.5px] text-zinc-500 font-mono mt-0.5">
                    <span>80% (Technika)</span>
                    <span className="text-[#FFE088]">100% (Súťaž 29)</span>
                    <span>105% (Kondícia)</span>
                  </div>
                </div>
              </div>
            )}

            {/* ═════════ TAB 4: PLÁN, REŽIM & KSIS RADAR ═════════ */}
            {activeTab === 'planner' && (
              <div className="h-full flex flex-col justify-between animate-fadeIn space-y-2">
                {/* Internal Subtab Switcher */}
                <div className="flex p-0.5 rounded-xl bg-zinc-900 border border-zinc-800">
                  <button
                    onClick={() => setPlannerSubTab('regime')}
                    className={`flex-1 py-1 rounded-lg text-[9px] font-bold transition-all ${
                      plannerSubTab === 'regime'
                        ? 'bg-[#FFE088] text-black shadow-sm'
                        : 'text-zinc-400 hover:text-white'
                    }`}
                  >
                    Môj Režim
                  </button>
                  <button
                    onClick={() => setPlannerSubTab('ksis')}
                    className={`flex-1 py-1 rounded-lg text-[9px] font-bold transition-all ${
                      plannerSubTab === 'ksis'
                        ? 'bg-[#FFE088] text-black shadow-sm'
                        : 'text-zinc-400 hover:text-white'
                    }`}
                  >
                    Súťaže KSIS
                  </button>
                </div>

                {plannerSubTab === 'regime' ? (
                  <div className="space-y-2">
                    {/* Today Cadence Card with 1-Tap RSVP */}
                    <div className="p-3 rounded-2xl bg-gradient-to-br from-[#1a1208] to-[#0e0a05] border border-[#D4AF37]/50 shadow-md">
                      <div className="flex justify-between items-center text-[9px] font-mono text-[#D4AF37] mb-1">
                        <span className="font-bold">DNES 18:00</span>
                        <span className="text-zinc-400">Sála 1</span>
                      </div>
                      <h4 className="text-xs font-serif font-bold text-white">Vedený tréning Štandard</h4>
                      
                      <div className="flex items-center gap-1.5 my-2">
                        <span className="w-2 h-2 rounded-full bg-emerald-400" />
                        <span className="text-[8.5px] text-emerald-300 font-semibold">
                          Partnerka potvrdila účasť
                        </span>
                      </div>

                      {/* 1-Tap RSVP Action Buttons */}
                      <div className="flex gap-2 pt-1">
                        <button
                          onClick={() => setRsvpState('attending')}
                          className={`flex-1 py-1.5 rounded-xl text-[9px] font-bold transition-all ${
                            rsvpState === 'attending'
                              ? 'bg-gradient-to-r from-[#FFF2CC] via-[#FFE088] to-[#D4AF37] text-black shadow-[0_0_10px_rgba(212,175,55,0.4)]'
                              : 'bg-zinc-800 text-zinc-400 hover:text-white'
                          }`}
                        >
                          ✓ Idem
                        </button>
                        <button
                          onClick={() => setRsvpState('skipped')}
                          className={`flex-1 py-1.5 rounded-xl text-[9px] font-bold transition-all ${
                            rsvpState === 'skipped'
                              ? 'bg-red-500/20 text-red-300 border border-red-500'
                              : 'bg-zinc-800 text-zinc-400 hover:text-white'
                          }`}
                        >
                          ✕ Vynechávam
                        </button>
                      </div>
                    </div>

                    {/* Post-Training Debrief Teaser */}
                    <div className="p-2.5 rounded-xl bg-[#121118] border border-zinc-800 flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <div className="w-6 h-6 rounded-full bg-[#E11D48]/20 text-[#E11D48] flex items-center justify-center text-[10px]">
                          🎙️
                        </div>
                        <div>
                          <span className="text-[8px] font-mono text-zinc-400 block">Po tréningu (19:30)</span>
                          <span className="text-[9px] font-bold text-white">Hlasový rozbor do profilu</span>
                        </div>
                      </div>
                      <span className="text-[8px] text-[#FFE088] font-mono">15s diktát</span>
                    </div>
                  </div>
                ) : (
                  <div className="space-y-2">
                    {/* Official KSIS Competition Card */}
                    <div className="p-3 rounded-2xl bg-gradient-to-br from-[#0c141d] to-[#070b10] border border-blue-500/40 shadow-md">
                      <div className="flex items-center gap-1.5 text-[8.5px] font-semibold text-emerald-400 mb-1">
                        <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" />
                        <span>Oficiálne prihlásení na KSIS</span>
                      </div>
                      <h4 className="text-xs font-serif font-bold text-white">Grand Prix Žilina 2026</h4>
                      <p className="text-[8.5px] text-zinc-400 font-mono mt-0.5">Štartovné číslo: #42</p>

                      <div className="flex items-center gap-2 mt-2">
                        <span className="text-[8px] font-mono bg-blue-950 text-blue-300 px-2 py-0.5 rounded-full border border-blue-800">
                          ⏱ O 11 dní
                        </span>
                        <span className="text-[8px] font-mono bg-zinc-800 text-zinc-300 px-2 py-0.5 rounded-full">
                          Dospelí B ŠTT
                        </span>
                      </div>
                    </div>

                    {/* Class Promotion Point Radar */}
                    <div className="p-2.5 rounded-xl bg-zinc-900/70 border border-zinc-800 text-[9px]">
                      <div className="flex justify-between items-center font-mono text-zinc-400 mb-1">
                        <span>Postup do Triedy A:</span>
                        <span className="text-[#FFE088] font-bold">145 / 200 b.</span>
                      </div>
                      <div className="w-full h-1.5 bg-zinc-800 rounded-full overflow-hidden">
                        <div className="h-full bg-gradient-to-r from-[#FFE088] to-[#D4AF37] w-[72%]" />
                      </div>
                      <span className="text-[7.5px] text-zinc-500 block mt-1">Ešte 55 bodov a 1 finále</span>
                    </div>
                  </div>
                )}
              </div>
            )}

          </div>

          {/* ── Native iOS Tab Bar (Crisp SVG SF Symbols) ── */}
          <div className="pt-2 pb-5 px-6 border-t border-zinc-900 bg-[#09090d]/95 flex justify-between items-center text-[10px] text-zinc-500">
            {/* Tab 1: Home */}
            <div
              onClick={() => setActiveTab('canvas')}
              className={`flex flex-col items-center gap-0.5 cursor-pointer transition-colors ${
                activeTab === 'canvas' ? 'text-[#FFE088]' : 'hover:text-zinc-300'
              }`}
            >
              <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
              </svg>
              <span className="text-[7.5px] font-medium">Domov</span>
            </div>

            {/* Tab 2: Canvas / Parket */}
            <div
              onClick={() => setActiveTab('video')}
              className={`flex flex-col items-center gap-0.5 cursor-pointer transition-colors ${
                activeTab === 'video' ? 'text-[#FFE088]' : 'hover:text-zinc-300'
              }`}
            >
              <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <rect x="3" y="3" width="18" height="18" rx="2" />
                <path d="M7 7h10M7 12h10M7 17h6" />
              </svg>
              <span className="text-[7.5px] font-medium">Parket</span>
            </div>

            {/* Tab 3: Plán & Súťaže (NEW TAB) */}
            <div
              onClick={() => setActiveTab('planner')}
              className={`flex flex-col items-center gap-0.5 cursor-pointer transition-colors ${
                activeTab === 'planner' ? 'text-[#FFE088]' : 'hover:text-zinc-300'
              }`}
            >
              <div className="relative">
                <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <rect x="3" y="4" width="18" height="18" rx="2" />
                  <path d="M16 2v4M8 2v4M3 10h18" />
                </svg>
                <span className="absolute -top-0.5 -right-0.5 w-1.5 h-1.5 rounded-full bg-[#FFE088]" />
              </div>
              <span className="text-[7.5px] font-bold">Plán</span>
            </div>

            {/* Tab 4: Profil */}
            <div
              onClick={() => setActiveTab('metronome')}
              className={`flex flex-col items-center gap-0.5 cursor-pointer transition-colors ${
                activeTab === 'metronome' ? 'text-[#FFE088]' : 'hover:text-zinc-300'
              }`}
            >
              <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
                <circle cx="12" cy="7" r="4" />
              </svg>
              <span className="text-[7.5px] font-medium">Profil</span>
            </div>
          </div>

          {/* Native Home Indicator Line */}
          <div className="absolute bottom-1.5 left-1/2 -translate-x-1/2 w-28 h-1 bg-zinc-600 rounded-full" />
        </div>
      </div>

      {/* Interactive Hint Under Phone */}
      <p className="text-[11px] font-mono text-zinc-500 mt-4 flex items-center gap-2">
        <span className="w-2 h-2 rounded-full bg-[#FFE088] animate-pulse" />
        Vyskúšajte kliknúť na jednotlivé moduly alebo figúry na parkete
      </p>
    </div>
  )
}
