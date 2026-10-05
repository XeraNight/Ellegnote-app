'use client'

import React, { useState } from 'react'
import Image from 'next/image'

type MockupTab = 'canvas' | 'video' | 'metronome' | 'ksis'

export default function InteractivePhoneMockup() {
  const [activeTab, setActiveTab] = useState<MockupTab>('canvas')

  return (
    <div className="w-full flex flex-col items-center">
      {/* Module Navigation Tabs */}
      <div className="flex flex-wrap justify-center items-center gap-2 mb-8 p-1.5 rounded-full bg-[#121118]/80 border border-[#D4AF37]/25 backdrop-blur-xl max-w-xl">
        <button
          onClick={() => setActiveTab('canvas')}
          className={`px-4 py-2 rounded-full text-xs font-bold transition-all ${
            activeTab === 'canvas'
              ? 'bg-gradient-to-r from-[#FFE088] to-[#D4AF37] text-black shadow-[0_0_15px_rgba(212,175,55,0.4)]'
              : 'text-zinc-400 hover:text-white'
          }`}
        >
          ✨ 2D Parket
        </button>

        <button
          onClick={() => setActiveTab('video')}
          className={`px-4 py-2 rounded-full text-xs font-bold transition-all ${
            activeTab === 'video'
              ? 'bg-gradient-to-r from-[#FFE088] to-[#D4AF37] text-black shadow-[0_0_15px_rgba(212,175,55,0.4)]'
              : 'text-zinc-400 hover:text-white'
          }`}
        >
          🎬 Video Duel
        </button>

        <button
          onClick={() => setActiveTab('metronome')}
          className={`px-4 py-2 rounded-full text-xs font-bold transition-all ${
            activeTab === 'metronome'
              ? 'bg-gradient-to-r from-[#FFE088] to-[#D4AF37] text-black shadow-[0_0_15px_rgba(212,175,55,0.4)]'
              : 'text-zinc-400 hover:text-white'
          }`}
        >
          🎵 Metronóm
        </button>

        <button
          onClick={() => setActiveTab('ksis')}
          className={`px-4 py-2 rounded-full text-xs font-bold transition-all ${
            activeTab === 'ksis'
              ? 'bg-gradient-to-r from-[#FFE088] to-[#D4AF37] text-black shadow-[0_0_15px_rgba(212,175,55,0.4)]'
              : 'text-zinc-400 hover:text-white'
          }`}
        >
          🏆 SZTŠ Radar
        </button>
      </div>

      {/* Realistic Titanium iPhone 16 Pro Frame */}
      <div className="relative w-[310px] sm:w-[350px] aspect-[9/19.5] rounded-[52px] p-3 bg-gradient-to-b from-[#2a2933] via-[#1a1921] to-[#0d0c12] shadow-[0_25px_80px_rgba(0,0,0,0.9),0_0_40px_rgba(212,175,55,0.25)] border-[3px] border-[#3e3b48]">
        {/* Outer Titanium edge sheen */}
        <div className="absolute inset-0 rounded-[49px] border border-[#FFE088]/20 pointer-events-none" />

        {/* Screen Display Container */}
        <div className="relative w-full h-full rounded-[44px] bg-[#07070a] overflow-hidden flex flex-col justify-between border border-black text-white select-none">
          
          {/* ── Status Bar & Dynamic Island ── */}
          <div className="pt-3 px-6 flex justify-between items-center text-[11px] font-medium text-zinc-400 z-30">
            <span>9:41</span>
            {/* Dynamic Island */}
            <div className="h-6 w-28 bg-black rounded-full border border-zinc-800 flex items-center justify-between px-2.5 shadow-md">
              <span className="w-2 h-2 rounded-full bg-[#D4AF37] animate-pulse" />
              <span className="text-[9px] font-mono text-[#FFE088] tracking-wider font-bold">
                {activeTab === 'metronome' ? '29 MPM' : 'ENCORE'}
              </span>
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" />
            </div>
            <div className="flex items-center gap-1.5">
              <span className="text-[10px]">5G</span>
              <span className="text-[10px]">100%</span>
            </div>
          </div>

          {/* ── SCREEN CONTENT BY TAB ── */}
          <div className="flex-1 px-4 py-3 flex flex-col justify-between overflow-hidden">
            
            {/* TAB 1: 2D Parket Canvas */}
            {activeTab === 'canvas' && (
              <div className="h-full flex flex-col justify-between animate-fadeIn">
                <div className="flex items-center justify-between border-b border-zinc-800 pb-2">
                  <div>
                    <span className="text-[10px] font-mono uppercase text-[#D4AF37]">Štandard • 3/4</span>
                    <h4 className="text-sm font-serif font-bold text-white">Slow Waltz Routine</h4>
                  </div>
                  <span className="text-[10px] px-2 py-0.5 rounded-full bg-[#1E40AF]/30 text-blue-300 border border-[#1E40AF]/60 font-semibold">
                    LOD ↗
                  </span>
                </div>

                {/* Parquet Simulation with Nodes & SVG Bezier Lines */}
                <div className="relative h-64 rounded-2xl bg-[#0b0a10] border border-[#D4AF37]/20 p-3 overflow-hidden flex flex-col justify-between">
                  {/* Subtle parquet grid lines */}
                  <div className="absolute inset-0 opacity-15 bg-[radial-gradient(#D4AF37_1px,transparent_1px)] [background-size:16px_16px]" />

                  {/* Bezier connection path simulation */}
                  <svg className="absolute inset-0 w-full h-full pointer-events-none" viewBox="0 0 300 240">
                    <path
                      d="M 50 50 Q 150 70 120 130 T 230 190"
                      fill="none"
                      stroke="#D4AF37"
                      strokeWidth="2.5"
                      strokeDasharray="4 4"
                    />
                  </svg>

                  {/* Node 1 */}
                  <div className="relative z-10 self-start p-2 rounded-xl bg-[#16151f] border border-[#FFE088]/40 shadow-lg max-w-[150px]">
                    <div className="flex items-center justify-between text-[9px] text-[#FFE088] font-bold">
                      <span>#01</span>
                      <span className="font-mono">1 2 3</span>
                    </div>
                    <p className="text-[11px] font-bold text-white leading-tight mt-0.5">Natural Spin Turn</p>
                    <span className="text-[8px] text-zinc-400 block">Nášľap: Päta - Špička</span>
                  </div>

                  {/* Node 2 */}
                  <div className="relative z-10 self-center p-2 rounded-xl bg-[#16151f] border border-[#FFE088]/40 shadow-lg max-w-[150px]">
                    <div className="flex items-center justify-between text-[9px] text-[#FFE088] font-bold">
                      <span>#02</span>
                      <span className="font-mono">1 2 3</span>
                    </div>
                    <p className="text-[11px] font-bold text-white leading-tight mt-0.5">Turning Lock to R</p>
                    <span className="text-[8px] text-zinc-400 block">Náklon: C-Shape Sway</span>
                  </div>

                  {/* Node 3 */}
                  <div className="relative z-10 self-end p-2 rounded-xl bg-[#16151f] border border-[#FFE088]/40 shadow-lg max-w-[150px]">
                    <div className="flex items-center justify-between text-[9px] text-[#FFE088] font-bold">
                      <span>#03</span>
                      <span className="font-mono">1 2 3</span>
                    </div>
                    <p className="text-[11px] font-bold text-white leading-tight mt-0.5">Weave from PP</p>
                    <span className="text-[8px] text-zinc-400 block">Smer: Diagonálne do stredu</span>
                  </div>
                </div>

                {/* Bottom Canvas Controls */}
                <div className="flex items-center justify-between pt-2 text-[10px] text-zinc-400">
                  <span>Zoom: 100%</span>
                  <span className="text-[#FFE088] font-semibold">12 Figúr v zostave</span>
                </div>
              </div>
            )}

            {/* TAB 2: Video Duel & Slo-Mo */}
            {activeTab === 'video' && (
              <div className="h-full flex flex-col justify-between animate-fadeIn space-y-2">
                <div className="flex justify-between items-center border-b border-zinc-800 pb-2">
                  <h4 className="text-xs font-serif font-bold text-white">Side-by-Side Video Duel</h4>
                  <span className="text-[9px] font-mono text-[#E11D48] bg-[#E11D48]/15 px-2 py-0.5 rounded-full font-bold">
                    SLO-MO 120 FPS
                  </span>
                </div>

                {/* Split Dual Screen */}
                <div className="grid grid-cols-2 gap-2 h-48">
                  {/* Left: Your couple */}
                  <div className="rounded-xl bg-[#121118] border border-zinc-800 p-2 flex flex-col justify-between relative overflow-hidden">
                    <span className="text-[9px] font-bold text-[#D4AF37] uppercase">Vlastný tréning</span>
                    <div className="my-auto text-center">
                      <div className="w-8 h-8 rounded-full bg-white/10 mx-auto flex items-center justify-center text-xs">
                        ▶
                      </div>
                      <span className="text-[9px] text-zinc-400 block mt-1">Uhol ramena: 14°</span>
                    </div>
                    <span className="text-[8px] font-mono text-zinc-500">00:04.12</span>
                  </div>

                  {/* Right: Master / Coach reference */}
                  <div className="rounded-xl bg-[#180a0e] border border-[#E11D48]/30 p-2 flex flex-col justify-between relative overflow-hidden">
                    <span className="text-[9px] font-bold text-[#FFE088] uppercase">Vzor / Tréner</span>
                    <div className="my-auto text-center">
                      <div className="w-8 h-8 rounded-full bg-[#E11D48]/30 mx-auto flex items-center justify-center text-xs text-[#FFE088]">
                        ✓
                      </div>
                      <span className="text-[9px] text-emerald-400 block mt-1">Ideálna línia: 0°</span>
                    </div>
                    <span className="text-[8px] font-mono text-zinc-500">00:04.12</span>
                  </div>
                </div>

                {/* Common Scrubber */}
                <div className="p-2.5 rounded-xl bg-zinc-900/80 border border-zinc-800">
                  <div className="flex justify-between text-[9px] text-zinc-400 font-mono mb-1">
                    <span>Frame 144</span>
                    <span className="text-[#FFE088]">Spoločný posuvník času</span>
                    <span>120 FPS</span>
                  </div>
                  <div className="w-full h-1.5 rounded-full bg-zinc-800 relative">
                    <div className="w-2/5 h-full rounded-full bg-gradient-to-r from-[#FFE088] to-[#D4AF37]" />
                  </div>
                </div>
              </div>
            )}

            {/* TAB 3: Metronóm & Pitch Trainer */}
            {activeTab === 'metronome' && (
              <div className="h-full flex flex-col justify-between items-center text-center py-2 animate-fadeIn">
                <span className="text-[10px] font-mono uppercase text-[#D4AF37] tracking-widest">
                  Syntetický PCM Engine (0ms Lag)
                </span>

                {/* Dial Circle */}
                <div className="relative w-36 h-36 rounded-full border-4 border-[#D4AF37]/30 flex flex-col items-center justify-center shadow-[0_0_30px_rgba(212,175,55,0.2)]">
                  <div className="absolute inset-1 rounded-full border border-dashed border-[#FFE088]/40 animate-spin [animation-duration:12s]" />
                  <span className="text-3xl font-mono font-black text-white">29</span>
                  <span className="text-[9px] font-bold tracking-widest text-[#FFE088] uppercase">
                    MPM • Slowfox
                  </span>
                  <span className="text-[8px] text-zinc-400 mt-0.5">116 BPM</span>
                </div>

                {/* Speed Pitch Box */}
                <div className="w-full p-2.5 rounded-xl bg-[#121118] border border-zinc-800">
                  <div className="flex justify-between text-[10px] text-zinc-400 font-bold mb-1">
                    <span>Tempo Trainer:</span>
                    <span className="text-[#FFE088]">90% Rýchlosť (-10%)</span>
                  </div>
                  <div className="flex justify-between text-[8px] text-zinc-500 font-mono">
                    <span>80% (Technika)</span>
                    <span>100% (Súťaž)</span>
                    <span>105% (Kondícia)</span>
                  </div>
                </div>
              </div>
            )}

            {/* TAB 4: SZTŠ Bodovací Radar */}
            {activeTab === 'ksis' && (
              <div className="h-full flex flex-col justify-between animate-fadeIn space-y-2">
                <div className="flex justify-between items-center border-b border-zinc-800 pb-2">
                  <div>
                    <span className="text-[9px] font-mono text-zinc-400 uppercase">ksis.eu sync</span>
                    <h4 className="text-xs font-serif font-bold text-white">SZTŠ Výkonnostný Radar</h4>
                  </div>
                  <span className="text-[10px] font-bold text-[#D4AF37] bg-[#D4AF37]/10 px-2 py-0.5 rounded-full border border-[#D4AF37]/30">
                    Trieda B
                  </span>
                </div>

                {/* Point Progress Card */}
                <div className="p-3 rounded-2xl bg-gradient-to-br from-[#1a1208] to-[#0d0905] border border-[#D4AF37]/40 shadow-md">
                  <div className="flex justify-between items-end mb-2">
                    <div>
                      <span className="text-[9px] text-zinc-400 block uppercase">Postupové body</span>
                      <span className="text-2xl font-mono font-bold text-white">145 <span className="text-xs text-zinc-500 font-normal">/ 200</span></span>
                    </div>
                    <div className="text-right">
                      <span className="text-[9px] text-zinc-400 block uppercase">Finále</span>
                      <span className="text-base font-mono font-bold text-[#FFE088]">4 <span className="text-xs text-zinc-500 font-normal">/ 5</span></span>
                    </div>
                  </div>
                  {/* Progress bar */}
                  <div className="w-full h-2 rounded-full bg-zinc-800 overflow-hidden">
                    <div className="h-full bg-gradient-to-r from-[#FFE088] via-[#D4AF37] to-[#AA771C] w-[72%]" />
                  </div>
                  <span className="text-[8px] text-[#FFE088] font-semibold mt-1.5 block text-center">
                    Ešte 55 bodov a 1 finále do Triedy A
                  </span>
                </div>

                {/* Recent Competitions */}
                <div className="space-y-1.5">
                  <span className="text-[9px] text-zinc-400 font-bold uppercase tracking-wider block">Posledné turnaje</span>
                  <div className="p-2 rounded-xl bg-zinc-900/60 border border-zinc-800 flex justify-between items-center text-[10px]">
                    <span className="font-semibold text-white">Grand Prix Žilina</span>
                    <span className="text-emerald-400 font-bold font-mono">2. Miesto (Finále)</span>
                  </div>
                  <div className="p-2 rounded-xl bg-zinc-900/60 border border-zinc-800 flex justify-between items-center text-[10px]">
                    <span className="font-semibold text-white">Pohár Trnavy</span>
                    <span className="text-zinc-300 font-mono">4. Miesto (+28 b.)</span>
                  </div>
                </div>
              </div>
            )}

          </div>

          {/* ── Native iOS Tab Bar ── */}
          <div className="pt-2 pb-5 px-6 border-t border-zinc-900/90 bg-[#09090d]/95 flex justify-between items-center text-[10px] text-zinc-500">
            <div className={`flex flex-col items-center gap-0.5 ${activeTab === 'canvas' ? 'text-[#FFE088]' : ''}`}>
              <span className="text-xs">📐</span>
              <span className="text-[8px] font-semibold">Parket</span>
            </div>
            <div className={`flex flex-col items-center gap-0.5 ${activeTab === 'video' ? 'text-[#FFE088]' : ''}`}>
              <span className="text-xs">🎬</span>
              <span className="text-[8px] font-semibold">Video</span>
            </div>
            <div className={`flex flex-col items-center gap-0.5 ${activeTab === 'metronome' ? 'text-[#FFE088]' : ''}`}>
              <span className="text-xs">🎵</span>
              <span className="text-[8px] font-semibold">Metronóm</span>
            </div>
            <div className={`flex flex-col items-center gap-0.5 ${activeTab === 'ksis' ? 'text-[#FFE088]' : ''}`}>
              <span className="text-xs">🏆</span>
              <span className="text-[8px] font-semibold">SZTŠ</span>
            </div>
          </div>

          {/* Home indicator bar */}
          <div className="absolute bottom-1.5 left-1/2 -translate-x-1/2 w-28 h-1 bg-zinc-600 rounded-full" />
        </div>
      </div>
    </div>
  )
}
