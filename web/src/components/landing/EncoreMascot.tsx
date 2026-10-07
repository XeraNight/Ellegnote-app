'use client'

import React, { useState, useEffect, useRef } from 'react'

interface MascotProps {
  isPlayingMetronome?: boolean
  currentBeat?: number
  onPlayClick?: () => void
}

const coachQuotes = [
  '„Ahoj tanečník! 👋 Vyskúšaj si náš metronóm naživo!“',
  '„Počuješ ten akcent na 1? Zdvihni rám a ideme!“',
  '„Špička-päta (T-H), žiadne flákanie na parkete!“',
  '„Skús prepnúť na Viedenský valčík (58 MPM) – to je rýchlosť!“',
  '„LOD smeruje vpravo, nezrážaj ostatné páry!“',
  '„Krásny C-Shape Sway, presne takto sa vyhráva finále!“',
]

export default function EncoreMascot({
  isPlayingMetronome = false,
  currentBeat = 1,
  onPlayClick,
}: MascotProps) {
  const [quoteIndex, setQuoteIndex] = useState(0)
  const [isHovered, setIsHovered] = useState(false)
  const [hasSpun, setHasSpun] = useState(false)
  const [showBubble, setShowBubble] = useState(true)
  const audioCtxRef = useRef<AudioContext | null>(null)

  // Play a cheerful cheerful chime/click on interaction
  const playChime = () => {
    try {
      const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof window.AudioContext }).webkitAudioContext
      if (!audioCtxRef.current && AudioCtx) {
        audioCtxRef.current = new AudioCtx()
      }
      if (audioCtxRef.current) {
        if (audioCtxRef.current.state === 'suspended') {
          audioCtxRef.current.resume()
        }
        const ctx = audioCtxRef.current
        const osc = ctx.createOscillator()
        const gain = ctx.createGain()
        osc.type = 'triangle'
        osc.frequency.setValueAtTime(587.33, ctx.currentTime) // D5
        osc.frequency.exponentialRampToValueAtTime(880, ctx.currentTime + 0.1) // A5
        gain.gain.setValueAtTime(0.08, ctx.currentTime)
        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.18)
        osc.connect(gain)
        gain.connect(ctx.destination)
        osc.start()
        osc.stop(ctx.currentTime + 0.19)
      }
    } catch {
      // Audio autoplay policy fallback
    }
  }

  const handleMascotClick = () => {
    playChime()
    setHasSpun(true)
    setTimeout(() => setHasSpun(false), 600)
    setQuoteIndex((prev) => (prev + 1) % coachQuotes.length)
    setShowBubble(true)
    if (onPlayClick) {
      onPlayClick()
    }
  }

  // Auto-hide speech bubble on mobile after initial show, reopen on hover
  useEffect(() => {
    const timer = setTimeout(() => {
      if (!isHovered) {
        setShowBubble(false)
      }
    }, 8000)
    return () => clearTimeout(timer)
  }, [isHovered])

  return (
    <div
      className="relative select-none flex flex-col items-center group cursor-pointer"
      onMouseEnter={() => {
        setIsHovered(true)
        setShowBubble(true)
      }}
      onMouseLeave={() => setIsHovered(false)}
      onClick={handleMascotClick}
      aria-label="Encore tanečný maskot Allegro"
    >
      {/* ── Discord-Style Interactive Speech Bubble ── */}
      <div
        className={`absolute -top-16 md:-top-20 right-0 sm:-right-8 md:-right-16 z-30 transition-all duration-300 pointer-events-auto ${
          showBubble || isHovered
            ? 'opacity-100 translate-y-0 scale-100'
            : 'opacity-0 translate-y-2 scale-95 pointer-events-none'
        }`}
      >
        <div className="relative bg-[#18181D] border border-[#FFE088]/40 text-white text-xs px-3.5 py-2 rounded-2xl shadow-[0_10px_25px_rgba(0,0,0,0.8),0_0_15px_rgba(212,175,55,0.2)] max-w-[210px] sm:max-w-[240px] text-left">
          <p className="font-sans text-[11px] font-semibold text-zinc-100 leading-snug">
            {coachQuotes[quoteIndex]}
          </p>
          <span className="text-[9px] text-[#FFE088] font-mono font-bold block mt-1 tracking-wide">
            ★ ALLEGRO • Tanečný Buddy
          </span>
          {/* Bubble Arrow Tail */}
          <div className="absolute -bottom-2 left-8 w-3 h-3 bg-[#18181D] border-r border-b border-[#FFE088]/40 rotate-45" />
        </div>
      </div>

      {/* ── Allegro Character Body with Waving Arm & Beat Bounce ── */}
      <div
        className={`relative w-20 h-24 sm:w-24 sm:h-28 transition-transform duration-300 ${
          hasSpun ? 'animate-[spin_0.6s_cubic-bezier(0.34,1.56,0.64,1)]' : ''
        } ${isHovered ? 'scale-110' : 'scale-100'}`}
        style={{
          transform: isPlayingMetronome
            ? `translateY(${currentBeat === 1 ? -6 : -2}px)`
            : undefined,
          transition: 'transform 0.15s cubic-bezier(0.2, 0.8, 0.2, 1)',
        }}
      >
        {/* Soft Golden Halo when beat hits or on hover */}
        <div
          className={`absolute inset-0 rounded-full bg-[#FFE088]/20 blur-xl transition-opacity duration-200 ${
            isPlayingMetronome && currentBeat === 1 ? 'opacity-100' : isHovered ? 'opacity-60' : 'opacity-20'
          }`}
        />

        {/* Mascot SVG Vector Illustration */}
        <svg
          viewBox="0 0 100 120"
          className="w-full h-full drop-shadow-[0_12px_20px_rgba(0,0,0,0.8)] overflow-visible"
        >
          <defs>
            {/* Gold Velvet Shimmer Gradient */}
            <linearGradient id="mascotGold" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#FFF2CC" />
              <stop offset="50%" stopColor="#FFE088" />
              <stop offset="100%" stopColor="#D4AF37" />
            </linearGradient>

            {/* Tuxedo Body Gradient */}
            <linearGradient id="mascotTux" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#25252D" />
              <stop offset="50%" stopColor="#17171C" />
              <stop offset="100%" stopColor="#0B0B0E" />
            </linearGradient>
          </defs>

          {/* Dancing Shoes */}
          <ellipse cx="38" cy="112" rx="10" ry="4.5" fill="#000000" stroke="#FFE088" strokeWidth="1" />
          <ellipse cx="62" cy="112" rx="10" ry="4.5" fill="#000000" stroke="#FFE088" strokeWidth="1" />

          {/* Main Tuxedo Torso (Round & friendly like Discord Wumpus/Clyde) */}
          <rect
            x="24"
            y="54"
            width="52"
            height="52"
            rx="24"
            fill="url(#mascotTux)"
            stroke="#FFE088"
            strokeWidth="1.5"
          />

          {/* White Shirt Lapel */}
          <polygon points="43,54 57,54 50,72" fill="#F4F4F6" />

          {/* Golden Ballroom Bow Tie */}
          <g transform="translate(50, 68)">
            {/* Left wing */}
            <polygon points="-7,-4 0,0 -7,4" fill="url(#mascotGold)" />
            {/* Right wing */}
            <polygon points="7,-4 0,0 7,4" fill="url(#mascotGold)" />
            {/* Center knot */}
            <circle cx="0" cy="0" r="2.2" fill="#FFE088" />
          </g>

          {/* Mascot Head */}
          <circle
            cx="50"
            cy="36"
            r="24"
            fill="url(#mascotTux)"
            stroke="#FFE088"
            strokeWidth="1.8"
          />

          {/* Left Dancing Wing/Arm (resting stylishly on hip) */}
          <path
            d="M 25 66 C 14 72, 16 88, 26 84"
            fill="none"
            stroke="#FFE088"
            strokeWidth="3.5"
            strokeLinecap="round"
          />

          {/* ── Discord-Style Animated Waving Right Hand ── */}
          <g
            className="origin-[75px_65px] animate-[wave_1.6s_ease-in-out_infinite]"
            style={{
              transformOrigin: '75px 65px',
            }}
          >
            {/* Arm */}
            <path
              d="M 75 66 C 88 56, 92 42, 88 32"
              fill="none"
              stroke="#FFE088"
              strokeWidth="3.5"
              strokeLinecap="round"
            />
            {/* White Dancing Glove Hand */}
            <circle cx="87" cy="28" r="6" fill="#F5F5F5" stroke="#FFE088" strokeWidth="1" />
            <circle cx="89" cy="24" r="2.5" fill="#F5F5F5" />
            <circle cx="85" cy="23" r="2.5" fill="#F5F5F5" />
            <circle cx="82" cy="25" r="2.5" fill="#F5F5F5" />
          </g>

          {/* Eyes (Cute, expressive & friendly) */}
          <g>
            {/* Left Eye */}
            <ellipse cx="41" cy="34" rx="4.5" ry="6" fill="#FFFFFF" />
            <circle
              cx={isHovered ? 42 : 41}
              cy={isHovered ? 33 : 34}
              r="2.8"
              fill="#0B0B0E"
            />
            <circle cx="43" cy="32" r="1.2" fill="#FFFFFF" />

            {/* Right Eye (winks on click/spin) */}
            {hasSpun ? (
              <path
                d="M 54 36 Q 59 31 64 36"
                fill="none"
                stroke="#FFE088"
                strokeWidth="2"
                strokeLinecap="round"
              />
            ) : (
              <>
                <ellipse cx="59" cy="34" rx="4.5" ry="6" fill="#FFFFFF" />
                <circle
                  cx={isHovered ? 60 : 59}
                  cy={isHovered ? 33 : 34}
                  r="2.8"
                  fill="#0B0B0E"
                />
                <circle cx="61" cy="32" r="1.2" fill="#FFFFFF" />
              </>
            )}
          </g>

          {/* Cheerful Smile */}
          <path
            d="M 44 44 Q 50 49 56 44"
            fill="none"
            stroke="#FFE088"
            strokeWidth="2"
            strokeLinecap="round"
          />

          {/* Rosy Cheeks */}
          <circle cx="34" cy="41" r="2.5" fill="#E11D48" opacity="0.35" />
          <circle cx="66" cy="41" r="2.5" fill="#E11D48" opacity="0.35" />

          {/* Top Hat / Crown Feature */}
          <g transform="translate(50, 14)">
            <ellipse cx="0" cy="0" rx="14" ry="2.5" fill="#000000" stroke="#FFE088" strokeWidth="1" />
            <path
              d="M -9 0 L -8 -11 L 8 -11 L 9 0 Z"
              fill="#18181D"
              stroke="#FFE088"
              strokeWidth="1.2"
            />
            <line x1="-8.5" y1="-2.5" x2="8.5" y2="-2.5" stroke="#FFE088" strokeWidth="1.8" />
          </g>
        </svg>

        {/* Click indicator badge */}
        <div className="absolute -bottom-1 left-1/2 -translate-x-1/2 px-2 py-0.5 rounded-full bg-black/80 border border-[#FFE088]/40 text-[8px] font-mono text-[#FFE088] font-bold whitespace-nowrap shadow-md group-hover:scale-105 transition-transform">
          {isHovered ? 'Klikni ma! ✨' : 'Allegro'}
        </div>
      </div>
    </div>
  )
}
