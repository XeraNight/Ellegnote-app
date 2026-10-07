'use client'

import React, { useState, useEffect, useRef } from 'react'
import EncoreMascot from './EncoreMascot'

type MockupTab = 'canvas' | 'video' | 'metronome' | 'planner'

const nodeDetails: Record<number, { title: string; timing: string; comment: string; length: string }> = {
  1: {
    title: 'Natural Spin Turn',
    timing: '1 2 3 • T-H • Rotácia 3/8 R',
    comment: '„Silnejší tlak do stojnej nohy na 1, udržať hlavu vľavo.“',
    length: '00:14 HD',
  },
  2: {
    title: 'Turning Lock to Right',
    timing: '1& 2 3 • C-Shape Sway • T-T-TH',
    comment: '„Neponáhľať syncopáciu na &, predĺžiť výdych cez bok.“',
    length: '00:09 HD',
  },
  3: {
    title: 'Weave from Promenade Position',
    timing: '1 2 3 4 5 6 • Prechod do slowfoxu',
    comment: '„Rovnomerná dĺžka krokov na 2 a 3, nevypadávať z rámu.“',
    length: '00:18 HD',
  },
}

const dancePresets = [
  { name: 'Waltz', mpm: 29 },
  { name: 'Tango', mpm: 32 },
  { name: 'V. Waltz', mpm: 58 },
  { name: 'Slowfox', mpm: 29 },
  { name: 'Quickstep', mpm: 50 },
]

export default function InteractivePhoneMockup() {
  const [activeTab, setActiveTab] = useState<MockupTab>('canvas')
  const [selectedNode, setSelectedNode] = useState<number>(1)
  const [isPlayingMetronome, setIsPlayingMetronome] = useState<boolean>(false)
  const [tempoMPM, setTempoMPM] = useState<number>(29)
  const [currentBeat, setCurrentBeat] = useState<number>(1)
  const [soundEnabled, setSoundEnabled] = useState<boolean>(true)
  const [videoScrub, setVideoScrub] = useState<number>(45)
  const [isPlayingVideo, setIsPlayingVideo] = useState<boolean>(false)
  const [showBodyAngles, setShowBodyAngles] = useState<boolean>(true)
  const [rsvpState, setRsvpState] = useState<'idle' | 'attending' | 'skipped'>('attending')
  const [plannerSubTab, setPlannerSubTab] = useState<'regime' | 'ksis'>('regime')
  const [dynamicIslandExpanded, setDynamicIslandExpanded] = useState<boolean>(false)

  // Web Audio Context reference (persistent to prevent audio node leakage)
  const audioCtxRef = useRef<AudioContext | null>(null)

  const getAudioContext = () => {
    if (typeof window === 'undefined') return null
    if (!audioCtxRef.current) {
      const AudioCtx =
        window.AudioContext ||
        (window as unknown as { webkitAudioContext: typeof window.AudioContext }).webkitAudioContext
      if (AudioCtx) {
        audioCtxRef.current = new AudioCtx()
      }
    }
    if (audioCtxRef.current && audioCtxRef.current.state === 'suspended') {
      audioCtxRef.current.resume().catch(() => {})
    }
    return audioCtxRef.current
  }

  // Woodblock metronome sound synthesis
  const playMetronomeTick = (isAccent: boolean) => {
    if (!soundEnabled) return
    try {
      const ctx = getAudioContext()
      if (!ctx) return
      const now = ctx.currentTime

      const osc = ctx.createOscillator()
      const gain = ctx.createGain()

      osc.type = 'triangle'
      osc.frequency.setValueAtTime(isAccent ? 960 : 540, now)
      osc.frequency.exponentialRampToValueAtTime(isAccent ? 340 : 220, now + 0.04)

      gain.gain.setValueAtTime(isAccent ? 0.22 : 0.12, now)
      gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.048)

      osc.connect(gain)
      gain.connect(ctx.destination)

      osc.start(now)
      osc.stop(now + 0.05)
    } catch {
      // Audio autoplay policy fallback
    }
  }

  // Tactile Discord-style UI click sound
  const playUiClick = () => {
    try {
      const ctx = getAudioContext()
      if (!ctx) return
      const now = ctx.currentTime
      const osc = ctx.createOscillator()
      const gain = ctx.createGain()
      osc.type = 'sine'
      osc.frequency.setValueAtTime(750, now)
      gain.gain.setValueAtTime(0.04, now)
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.03)
      osc.connect(gain)
      gain.connect(ctx.destination)
      osc.start(now)
      osc.stop(now + 0.035)
    } catch {}
  }

  // 3D Parallax tilt effect on mouse hover
  const frameRef = useRef<HTMLDivElement>(null)
  const [tilt, setTilt] = useState<{ x: number; y: number }>({ x: 0, y: 0 })

  const handleMouseMove = (e: React.MouseEvent<HTMLDivElement>) => {
    if (!frameRef.current) return
    const rect = frameRef.current.getBoundingClientRect()
    const x = e.clientX - rect.left - rect.width / 2
    const y = e.clientY - rect.top - rect.height / 2
    setTilt({
      x: (y / (rect.height / 2)) * -5,
      y: (x / (rect.width / 2)) * 5,
    })
  }

  const handleMouseLeave = () => {
    setTilt({ x: 0, y: 0 })
  }

  // Smooth Video Scrubber Playback Simulator
  useEffect(() => {
    let interval: NodeJS.Timeout | null = null
    if (isPlayingVideo) {
      interval = setInterval(() => {
        setVideoScrub((prev) => (prev >= 100 ? 0 : prev + 2))
      }, 75)
    }
    return () => {
      if (interval) clearInterval(interval)
    }
  }, [isPlayingVideo])

  // Audio Context Metronome Engine (Synthetic PCM Web Audio)
  useEffect(() => {
    let interval: NodeJS.Timeout | null = null
    if (isPlayingMetronome) {
      const intervalMs = (60 / (tempoMPM * 3)) * 1000
      interval = setInterval(() => {
        setCurrentBeat((prev) => {
          const next = prev >= 3 ? 1 : prev + 1
          playMetronomeTick(next === 1)
          return next
        })
      }, intervalMs)
    } else {
      setCurrentBeat(1)
    }
    return () => {
      if (interval) clearInterval(interval)
    }
  }, [isPlayingMetronome, tempoMPM, soundEnabled])


  return (
    <div className="w-full flex flex-col items-center">
      
      {/* ── App Store & Google Play Live Preview Badge ── */}
      <div className="flex flex-col items-center gap-2 mb-6 text-center">
        <div className="inline-flex flex-wrap items-center justify-center gap-2 px-4 py-1.5 rounded-full bg-[#121216] border border-[#FFE088]/30 shadow-lg text-[11px] font-mono text-[#FFE088]">
          <span className="flex text-[#FFE088]">★★★★★</span>
          <span className="font-bold">4.9 v App Store & Google Play</span>
          <span className="text-zinc-600 hidden sm:inline">•</span>
          <span className="text-zinc-300">Len pre Mobil & Tablet (iPhone, iPad, Android)</span>
        </div>
        <p className="text-xs text-zinc-400 max-w-lg">
          Interaktívna ukážka priamo v prehliadači — kliknite na moduly, spustite reálny metronóm so zvukom alebo preskúmajte parket:
        </p>
      </div>

      {/* ── Top Module Selector Pill Bar ────────────────────────────── */}
      <div className="flex flex-wrap justify-center items-center gap-2 mb-10 p-1.5 rounded-full bg-[#121216] border border-[#FFE088]/20 shadow-[0_10px_30px_rgba(0,0,0,0.8)] max-w-2xl">
        <button
          onClick={() => {
            playUiClick()
            setActiveTab('canvas')
          }}
          className={`btn-discord-pill px-5 py-2.5 text-xs font-bold transition-all flex items-center gap-2 ${
            activeTab === 'canvas'
              ? 'bg-gradient-to-r from-[#FFF2CC] via-[#FFE088] to-[#D4AF37] text-black shadow-[0_0_20px_rgba(212,175,55,0.4)]'
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
          onClick={() => {
            playUiClick()
            setActiveTab('video')
          }}
          className={`btn-discord-pill px-5 py-2.5 text-xs font-bold transition-all flex items-center gap-2 ${
            activeTab === 'video'
              ? 'bg-gradient-to-r from-[#FFF2CC] via-[#FFE088] to-[#D4AF37] text-black shadow-[0_0_20px_rgba(212,175,55,0.4)]'
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
          onClick={() => {
            playUiClick()
            setActiveTab('metronome')
          }}
          className={`btn-discord-pill px-5 py-2.5 text-xs font-bold transition-all flex items-center gap-2 ${
            activeTab === 'metronome'
              ? 'bg-gradient-to-r from-[#FFF2CC] via-[#FFE088] to-[#D4AF37] text-black shadow-[0_0_20px_rgba(212,175,55,0.4)]'
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
          onClick={() => {
            playUiClick()
            setActiveTab('planner')
          }}
          className={`btn-discord-pill px-5 py-2.5 text-xs font-bold transition-all flex items-center gap-2 ${
            activeTab === 'planner'
              ? 'bg-gradient-to-r from-[#FFF2CC] via-[#FFE088] to-[#D4AF37] text-black shadow-[0_0_20px_rgba(212,175,55,0.4)]'
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

      {/* ── Interactive Playground: Phone Frame + Discord-Style Mascot Allegro ── */}
      <div className="relative w-full max-w-4xl flex flex-col lg:flex-row items-center justify-center gap-8 lg:gap-14">

      {/* ── Realistic iPhone 16 Pro Titanium Chassis ─────────────────── */}
      <div
        ref={frameRef}
        onMouseMove={handleMouseMove}
        onMouseLeave={handleMouseLeave}
        style={{
          transform: `perspective(1000px) rotateX(${tilt.x}deg) rotateY(${tilt.y}deg)`,
          transition: 'transform 0.15s ease-out',
        }}
        className="relative w-[320px] sm:w-[370px] aspect-[9/19.5] rounded-[54px] p-3.5 bg-[#18181B] shadow-[0_30px_90px_rgba(0,0,0,0.95),0_0_40px_rgba(212,175,55,0.15)] border-[3.5px] border-[#27272A] cursor-pointer"
      >
        {/* Hardware Buttons */}
        <div className="absolute -left-[6px] top-28 w-[3.5px] h-7 bg-[#27272A] rounded-l-md" />
        <div className="absolute -left-[6px] top-40 w-[3.5px] h-12 bg-[#27272A] rounded-l-md" />
        <div className="absolute -left-[6px] top-56 w-[3.5px] h-12 bg-[#27272A] rounded-l-md" />
        <div className="absolute -right-[6px] top-36 w-[3.5px] h-16 bg-[#27272A] rounded-r-md" />

        {/* Specular Edge Sheen */}
        <div className="absolute inset-0 rounded-[50px] border border-[#FFE088]/20 pointer-events-none" />

        {/* ── OLED Display Screen (Pure Obsidian #050505) ───────────── */}
        <div className="relative w-full h-full rounded-[44px] bg-[#050505] overflow-hidden flex flex-col justify-between border border-black text-[#F5F5F5] select-none shadow-inner">
          
          {/* Dynamic Physical Glass Glare Reflection */}
          <div
            className="absolute inset-0 rounded-[44px] pointer-events-none z-30 transition-opacity duration-300"
            style={{
              background: `linear-gradient(${125 + tilt.y * 4}deg, rgba(255,255,255,0.06) 0%, rgba(255,255,255,0.01) 45%, transparent 70%)`,
            }}
          />

          {/* Status Bar & Dynamic Island */}
          <div className="pt-3.5 px-6 flex justify-between items-center text-[11px] font-medium text-zinc-400 z-40 relative">
            <span className="font-semibold tracking-tight">9:41</span>

            {/* Dynamic Island */}
            <div
              onClick={() => setDynamicIslandExpanded(!dynamicIslandExpanded)}
              className={`transition-all duration-300 bg-black border border-zinc-800 flex items-center justify-between cursor-pointer ${
                dynamicIslandExpanded
                  ? 'h-10 w-56 px-3 rounded-2xl bg-[#121216] border-[#FFE088]/30 shadow-lg'
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
                  <span className="w-1.5 h-1.5 rounded-full bg-[#FFE088]" />
                </>
              )}
            </div>

            <div className="flex items-center gap-1.5 text-[10px] font-mono text-zinc-400">
              <span>5G</span>
              <div className="w-4 h-2 rounded-sm border border-zinc-500 p-0.5 flex items-center">
                <div className="w-full h-full bg-[#FFE088] rounded-2xs" />
              </div>
            </div>
          </div>

          {/* Screen Content Container */}
          <div className="flex-1 px-4 py-2.5 flex flex-col justify-between overflow-hidden relative">
            
            {/* ═════════ TAB 1: 2D PARKET CANVAS ═════════ */}
            {activeTab === 'canvas' && (
              <div className="h-full flex flex-col justify-between animate-fadeIn space-y-2">
                <div className="flex items-center justify-between border-b border-zinc-800/80 pb-2">
                  <div>
                    <span className="text-[9px] font-mono uppercase text-[#D4AF37] tracking-wider">
                      Waltz • 3/4 • 29 MPM
                    </span>
                    <h4 className="text-xs font-serif font-bold text-white flex items-center gap-1.5">
                      Súťažná Variácia 2026
                      <span className="text-[9px] text-zinc-500 font-normal">#01</span>
                    </h4>
                  </div>
                  <div className="flex items-center gap-1 bg-[#121216] border border-[#FFE088]/30 px-2 py-0.5 rounded-full text-[9px] text-[#FFE088] font-mono">
                    <span>LOD ↗</span>
                  </div>
                </div>

                {/* Parquet Simulation Area */}
                <div className="relative h-60 rounded-2xl bg-[#0A0A0A] border border-white/10 p-2.5 overflow-hidden flex flex-col justify-between shadow-inner">
                  {/* Subtle parquet lines */}
                  <div className="absolute inset-0 opacity-15 bg-[radial-gradient(#D4AF37_1px,transparent_1px)] [background-size:14px_14px]" />
                  <div className="absolute top-2 right-2 text-[8px] font-mono text-zinc-600 uppercase tracking-widest">
                    Parket 3000pt
                  </div>

                  {/* Bezier Path SVG */}
                  <svg className="absolute inset-0 w-full h-full pointer-events-none" viewBox="0 0 300 240">
                    <defs>
                      <linearGradient id="goldCurve" x1="0%" y1="0%" x2="100%" y2="100%">
                        <stop offset="0%" stopColor="#FFE088" />
                        <stop offset="50%" stopColor="#D4AF37" />
                        <stop offset="100%" stopColor="#AA820A" />
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
                    onClick={() => {
                      playUiClick()
                      setSelectedNode(1)
                    }}
                    className={`relative z-10 self-start p-2 rounded-xl transition-all cursor-pointer max-w-[155px] ${
                      selectedNode === 1
                        ? 'bg-[#141418] border-2 border-[#FFE088] shadow-[0_0_15px_rgba(212,175,55,0.35)] scale-105'
                        : 'bg-[#121216] border border-white/10'
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
                    onClick={() => {
                      playUiClick()
                      setSelectedNode(2)
                    }}
                    className={`relative z-10 self-center p-2 rounded-xl transition-all cursor-pointer max-w-[155px] ${
                      selectedNode === 2
                        ? 'bg-[#141418] border-2 border-[#FFE088] shadow-[0_0_15px_rgba(212,175,55,0.35)] scale-105'
                        : 'bg-[#121216] border border-white/10'
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
                      <span className="bg-[#141418] text-[#FFE088] px-1 rounded border border-[#FFE088]/20">
                        C-Shape Sway
                      </span>
                    </div>
                  </div>

                  {/* Figure Node 3 */}
                  <div
                    onClick={() => {
                      playUiClick()
                      setSelectedNode(3)
                    }}
                    className={`relative z-10 self-end p-2 rounded-xl transition-all cursor-pointer max-w-[155px] ${
                      selectedNode === 3
                        ? 'bg-[#141418] border-2 border-[#FFE088] shadow-[0_0_15px_rgba(212,175,55,0.35)] scale-105'
                        : 'bg-[#121216] border border-white/10'
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

                {/* Node Inspector Sheet Preview - Dynamic to selected node */}
                {(() => {
                  const currentDetail = nodeDetails[selectedNode] || nodeDetails[1]
                  return (
                    <div className="p-2.5 rounded-xl bg-[#121216] border border-[#FFE088]/25 flex items-center justify-between transition-all">
                      <div className="flex items-center gap-2.5">
                        <div className="w-7 h-7 rounded-lg bg-[#D4AF37]/15 border border-[#FFE088]/30 flex items-center justify-center text-xs text-[#FFE088] shrink-0">
                          <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                            <path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z" />
                            <path d="M19 10v2a7 7 0 0 1-14 0v-2" />
                          </svg>
                        </div>
                        <div className="text-left">
                          <div className="flex items-center gap-1.5">
                            <span className="text-[9.5px] font-bold text-white leading-none">{currentDetail.title}</span>
                            <span className="text-[7.5px] font-mono text-[#FFE088]">{currentDetail.timing}</span>
                          </div>
                          <span className="text-[8.5px] text-zinc-300 block mt-0.5 line-clamp-1 italic">
                            {currentDetail.comment}
                          </span>
                        </div>
                      </div>
                      <span className="text-[8px] font-mono text-[#FFE088] bg-[#D4AF37]/15 px-2 py-0.5 rounded-full font-bold shrink-0">
                        {currentDetail.length}
                      </span>
                    </div>
                  )
                })()}
              </div>
            )}

            {/* ═════════ TAB 2: VIDEO DUEL & MOTION ANALYSIS ═════════ */}
            {activeTab === 'video' && (
              <div className="h-full flex flex-col justify-between animate-fadeIn space-y-2">
                <div className="flex justify-between items-center border-b border-zinc-800/80 pb-2">
                  <div>
                    <span className="text-[9px] font-mono text-[#D4AF37] uppercase tracking-wider font-bold">
                      Side-by-Side Dual Analysis
                    </span>
                    <h4 className="text-xs font-serif font-bold text-white">Slo-Mo Rozbor Postúry</h4>
                  </div>
                  <button
                    onClick={() => setShowBodyAngles(!showBodyAngles)}
                    className="text-[8.5px] font-mono px-2 py-0.5 rounded-full bg-[#121216] text-[#FFE088] border border-[#FFE088]/30 font-bold"
                  >
                    {showBodyAngles ? 'Uhly: ZAPNUTÉ' : 'Uhly: VYPNUTÉ'}
                  </button>
                </div>

                {/* Dual Split Videos */}
                <div className="grid grid-cols-2 gap-2 h-44">
                  {/* Left: Your Training Recording */}
                  <div className="rounded-xl bg-[#121216] border border-white/10 p-2 flex flex-col justify-between relative overflow-hidden">
                    <span className="text-[8px] font-bold text-[#FFE088] uppercase tracking-wider font-mono">
                      Váš tréning
                    </span>

                    {/* Posture Overlay */}
                    <div className="relative my-auto flex flex-col items-center">
                      <div className="w-9 h-9 rounded-full border border-dashed border-[#FFE088]/50 flex items-center justify-center text-xs text-[#FFE088]">
                        <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                          <circle cx="12" cy="7" r="4" />
                          <path d="M5.5 21v-2a6.5 6.5 0 0 1 13 0v2" />
                        </svg>
                      </div>
                      {showBodyAngles && (
                        <div className="mt-1 px-1.5 py-0.5 rounded bg-black/80 border border-[#FFE088]/60 text-[7.5px] text-[#FFE088] font-mono font-bold">
                          Uhol chrbtice: 14°
                        </div>
                      )}
                    </div>
                    <span className="text-[8px] font-mono text-zinc-500">00:04.{videoScrub} • 120 FPS</span>
                  </div>

                  {/* Right: Master / Coach Reference */}
                  <div className="rounded-xl bg-[#121216] border border-[#FFE088]/35 p-2 flex flex-col justify-between relative overflow-hidden">
                    <span className="text-[8px] font-bold text-[#FFE088] uppercase tracking-wider font-mono">
                      Vzor / Tréner
                    </span>

                    {/* Posture Overlay */}
                    <div className="relative my-auto flex flex-col items-center">
                      <div className="w-9 h-9 rounded-full border border-[#FFE088]/50 bg-[#D4AF37]/15 flex items-center justify-center text-xs text-[#FFE088]">
                        <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                          <circle cx="12" cy="8" r="4" />
                          <path d="M6 21v-2a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v2" />
                        </svg>
                      </div>
                      {showBodyAngles && (
                        <div className="mt-1 px-1.5 py-0.5 rounded bg-black/80 border border-[#FFE088]/80 text-[7.5px] text-[#FFE088] font-mono font-bold">
                          Ideálna vertikála: 0°
                        </div>
                      )}
                    </div>
                    <span className="text-[8px] font-mono text-zinc-500">00:04.{videoScrub} • 120 FPS</span>
                  </div>
                </div>

                {/* Common Scrubber Slider */}
                <div className="p-2.5 rounded-xl bg-[#121216] border border-white/10 space-y-1.5">
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
                      className="px-2 py-0.5 rounded bg-white/5 hover:bg-white/10 font-mono"
                    >
                      ◀ 1 Frame
                    </button>
                    <button
                      onClick={() => setIsPlayingVideo(!isPlayingVideo)}
                      className="px-2.5 py-0.5 rounded-full bg-[#FFE088] text-black font-mono font-bold flex items-center gap-1 shadow-sm hover:brightness-110 active:scale-95 transition-all"
                    >
                      {isPlayingVideo ? '⏸ Pauza' : '▶ Prehrať'}
                    </button>
                    <button
                      onClick={() => setVideoScrub((p) => Math.min(100, p + 5))}
                      className="px-2 py-0.5 rounded bg-white/5 hover:bg-white/10 font-mono"
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
                <div className="flex items-center justify-between w-full px-1 border-b border-zinc-800/80 pb-1.5">
                  <div className="text-left">
                    <span className="text-[8.5px] font-mono uppercase text-[#D4AF37] tracking-widest block">
                      Syntetický Audio Engine
                    </span>
                    <h4 className="text-xs font-serif font-bold text-white">Ballroom Tanečný Metronóm</h4>
                  </div>
                  <button
                    onClick={(e) => {
                      e.stopPropagation()
                      playUiClick()
                      setSoundEnabled(!soundEnabled)
                    }}
                    className={`text-[8px] font-mono px-2 py-0.5 rounded-full border transition-all ${
                      soundEnabled
                        ? 'bg-[#18181D] text-[#FFE088] border-[#FFE088]/40 shadow-sm'
                        : 'bg-zinc-800 text-zinc-400 border-zinc-700'
                    }`}
                  >
                    {soundEnabled ? 'Zvuk: 🔊' : 'Zvuk: 🔇'}
                  </button>
                </div>

                {/* Pulsating Metronome Dial */}
                <div
                  onClick={() => {
                    playUiClick()
                    getAudioContext()
                    setIsPlayingMetronome(!isPlayingMetronome)
                  }}
                  className={`relative w-36 h-36 rounded-full border-4 transition-all flex flex-col items-center justify-center cursor-pointer ${
                    isPlayingMetronome
                      ? 'border-[#FFE088] shadow-[0_0_35px_rgba(212,175,55,0.35)] scale-105'
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
                    {isPlayingMetronome ? '⏸ Pauza' : '▶ Spustiť zvuk'}
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
                          : 'bg-[#141418] text-zinc-500 border border-white/5'
                      }`}
                    >
                      {b}
                    </div>
                  ))}
                </div>

                {/* Dance Quick Tempo Presets */}
                <div className="flex flex-wrap gap-1 justify-center pt-0.5">
                  {dancePresets.map((dance) => (
                    <button
                      key={dance.name}
                      onClick={() => {
                        playUiClick()
                        setTempoMPM(dance.mpm)
                      }}
                      className={`px-2 py-0.5 rounded-full text-[8px] font-mono transition-all ${
                        tempoMPM === dance.mpm
                          ? 'bg-[#FFE088] text-black font-bold shadow-sm'
                          : 'bg-[#141418] text-zinc-400 hover:text-white border border-white/5'
                      }`}
                    >
                      {dance.name} {dance.mpm}
                    </button>
                  ))}
                </div>

                {/* Speed Pitch Box */}
                <div className="w-full p-2 rounded-xl bg-[#121216] border border-white/10 text-left">
                  <div className="flex justify-between text-[9px] text-zinc-400 font-bold mb-1">
                    <span>Tréningový posuvník tempa:</span>
                    <span className="text-[#FFE088] font-mono">{tempoMPM} MPM</span>
                  </div>
                  <input
                    type="range"
                    min="24"
                    max="60"
                    value={tempoMPM}
                    onChange={(e) => setTempoMPM(Number(e.target.value))}
                    className="w-full accent-[#D4AF37] h-1.5 bg-zinc-800 rounded-lg cursor-pointer"
                  />
                  <div className="flex justify-between text-[7.5px] text-zinc-500 font-mono mt-0.5">
                    <span>80% (Technika)</span>
                    <span className="text-[#FFE088]">100% (Súťaž)</span>
                    <span>105% (Kondícia)</span>
                  </div>
                </div>
              </div>
            )}

            {/* ═════════ TAB 4: PLÁN, REŽIM & KSIS RADAR ═════════ */}
            {activeTab === 'planner' && (
              <div className="h-full flex flex-col justify-between animate-fadeIn space-y-2">
                {/* Internal Subtab Switcher */}
                <div className="flex p-0.5 rounded-xl bg-[#121216] border border-white/10">
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
                    <div className="p-3 rounded-2xl bg-[#121216] border border-[#FFE088]/30 shadow-md">
                      <div className="flex justify-between items-center text-[9px] font-mono text-[#D4AF37] mb-1">
                        <span className="font-bold">DNES 18:00</span>
                        <span className="text-zinc-400">Sála 1</span>
                      </div>
                      <h4 className="text-xs font-serif font-bold text-white">Vedený tréning Štandard</h4>
                      
                      <div className="flex items-center gap-1.5 my-2">
                        <span className={`w-1.5 h-1.5 rounded-full ${rsvpState === 'attending' ? 'bg-[#FFE088]' : 'bg-zinc-500'}`} />
                        <span className="text-[8.5px] text-zinc-300 font-semibold font-mono">
                          {rsvpState === 'attending'
                            ? 'Partnerka potvrdila účasť • Pár kompletný'
                            : rsvpState === 'skipped'
                            ? 'Vynechané • Notifikácia trénerovi odoslaná'
                            : 'Čaká sa na potvrdenie účasti'}
                        </span>
                      </div>

                      {/* 1-Tap RSVP Action Buttons */}
                      <div className="flex gap-2 pt-1">
                        <button
                          onClick={() => setRsvpState('attending')}
                          className={`flex-1 py-1.5 rounded-xl text-[9px] font-bold transition-all ${
                            rsvpState === 'attending'
                              ? 'bg-gradient-to-r from-[#FFF2CC] via-[#FFE088] to-[#D4AF37] text-black shadow-[0_0_10px_rgba(212,175,55,0.35)]'
                              : 'bg-zinc-800 text-zinc-400 hover:text-white'
                          }`}
                        >
                          ✓ Idem
                        </button>
                        <button
                          onClick={() => setRsvpState('skipped')}
                          className={`flex-1 py-1.5 rounded-xl text-[9px] font-bold transition-all ${
                            rsvpState === 'skipped'
                              ? 'bg-zinc-800 text-zinc-200 border border-zinc-600'
                              : 'bg-zinc-800/60 text-zinc-400 hover:text-white'
                          }`}
                        >
                          ✕ Vynechávam
                        </button>
                      </div>
                    </div>

                    {/* Post-Training Debrief Teaser */}
                    <div className="p-2.5 rounded-xl bg-[#121216] border border-white/10 flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <div className="w-6 h-6 rounded-full bg-[#D4AF37]/15 text-[#FFE088] flex items-center justify-center text-[10px]">
                          <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                            <path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z" />
                            <path d="M19 10v2a7 7 0 0 1-14 0v-2" />
                          </svg>
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
                    <div className="p-3 rounded-2xl bg-[#121216] border border-[#FFE088]/30 shadow-md">
                      <div className="flex items-center gap-1.5 text-[8.5px] font-semibold text-[#FFE088] mb-1 font-mono">
                        <span className="w-1.5 h-1.5 rounded-full bg-[#FFE088]" />
                        <span>Oficiálne prihlásení na KSIS</span>
                      </div>
                      <h4 className="text-xs font-serif font-bold text-white">Grand Prix Žilina 2026</h4>
                      <p className="text-[8.5px] text-zinc-400 font-mono mt-0.5">Štartovné číslo: #42</p>

                      <div className="flex items-center gap-2 mt-2">
                        <span className="text-[8px] font-mono bg-[#141418] text-[#FFE088] px-2 py-0.5 rounded-full border border-[#FFE088]/20">
                          ⏱ O 11 dní
                        </span>
                        <span className="text-[8px] font-mono bg-zinc-800 text-zinc-300 px-2 py-0.5 rounded-full">
                          Dospelí B ŠTT
                        </span>
                      </div>
                    </div>

                    {/* Class Promotion Point Radar */}
                    <div className="p-2.5 rounded-xl bg-[#121216] border border-white/10 text-[9px]">
                      <div className="flex justify-between items-center font-mono text-zinc-400 mb-1">
                        <span>Postup do Triedy A:</span>
                        <span className="text-[#FFE088] font-bold">145 / 200 b.</span>
                      </div>
                      <div className="w-full h-1.5 bg-zinc-800 rounded-full overflow-hidden">
                        <div className="h-full bg-gradient-to-r from-[#FFE088] to-[#D4AF37] w-[72%]" />
                      </div>
                      <span className="text-[7.5px] text-zinc-500 block mt-1 font-mono">Ešte 55 bodov a 1 finále</span>
                    </div>
                  </div>
                )}
              </div>
            )}

          </div>

          {/* ── Native iOS Tab Bar (Crisp SVG SF Symbols) ── */}
          <div className="pt-2 pb-5 px-6 border-t border-white/10 bg-[#0A0A0A] flex justify-between items-center text-[10px] text-zinc-500">
            {/* Tab 1: 2D Parket Canvas */}
            <div
              onClick={() => setActiveTab('canvas')}
              className={`flex flex-col items-center gap-0.5 cursor-pointer transition-colors ${
                activeTab === 'canvas' ? 'text-[#FFE088]' : 'hover:text-zinc-300'
              }`}
            >
              <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <rect x="3" y="3" width="18" height="18" rx="2" />
                <path d="M3 9h18M9 21V9" />
              </svg>
              <span className="text-[7.5px] font-medium font-sans">Parket</span>
            </div>

            {/* Tab 2: Video Duel */}
            <div
              onClick={() => setActiveTab('video')}
              className={`flex flex-col items-center gap-0.5 cursor-pointer transition-colors ${
                activeTab === 'video' ? 'text-[#FFE088]' : 'hover:text-zinc-300'
              }`}
            >
              <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <rect x="2" y="2" width="20" height="20" rx="3" />
                <path d="M12 2v20M7 7l10 10" />
              </svg>
              <span className="text-[7.5px] font-medium font-sans">Video</span>
            </div>

            {/* Tab 3: Plán & Súťaže KSIS */}
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
              <span className="text-[7.5px] font-bold font-sans">Plán</span>
            </div>

            {/* Tab 4: Metronóm */}
            <div
              onClick={() => setActiveTab('metronome')}
              className={`flex flex-col items-center gap-0.5 cursor-pointer transition-colors ${
                activeTab === 'metronome' ? 'text-[#FFE088]' : 'hover:text-zinc-300'
              }`}
            >
              <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <circle cx="12" cy="12" r="9" />
                <path d="M12 7v5l3 3" />
              </svg>
              <span className="text-[7.5px] font-medium font-sans">Metronóm</span>
            </div>
          </div>

          {/* Native Home Indicator Line */}
          <div className="absolute bottom-1.5 left-1/2 -translate-x-1/2 w-28 h-1 bg-zinc-600 rounded-full" />
        </div>
      </div>

      {/* ── Discord-Style Mascot Allegro Side Panel Companion ── */}
      <div className="flex flex-col items-center lg:items-start text-center lg:text-left gap-3 max-w-xs shrink-0 animate-fadeIn">
        <EncoreMascot
          isPlayingMetronome={isPlayingMetronome}
          currentBeat={currentBeat}
          onPlayClick={() => {
            playUiClick()
            getAudioContext()
            setIsPlayingMetronome((prev) => !prev)
          }}
        />
        
        <div className="bg-[#121216] border border-[#FFE088]/20 p-3.5 rounded-2xl shadow-xl backdrop-blur-md">
          <div className="flex items-center gap-2 mb-1 justify-center lg:justify-start">
            <span className="w-2 h-2 rounded-full bg-[#FFE088] animate-pulse" />
            <span className="text-[10px] font-mono text-[#FFE088] font-bold uppercase tracking-wider">
              Tanečný Asistent Allegro
            </span>
          </div>
          <p className="text-xs text-zinc-300 leading-snug">
            Kliknutím na Allegra získate ďalší trénerský pokyn, alebo spustite metronóm v telefóne a sledujte, ako drží rytmus.
          </p>
          <div className="mt-2.5 pt-2 border-t border-white/10 flex items-center justify-between text-[10px] font-mono text-zinc-400">
            <span>Doba: <strong className="text-[#FFE088]">{currentBeat} / 3</strong></span>
            <span>Tempo: <strong className="text-white">{tempoMPM} MPM</strong></span>
          </div>
        </div>
      </div>

      </div>

      {/* Interactive Hint Under Phone */}
      <p className="text-[11px] font-mono text-zinc-400 mt-6 flex items-center gap-2">
        <span className="w-2 h-2 rounded-full bg-[#FFE088] animate-pulse" />
        Skutočný Web Audio syntetizátor • Kliknite na moduly, figúry alebo tempo pre živú zvukovú odozvu
      </p>
    </div>
  )
}
