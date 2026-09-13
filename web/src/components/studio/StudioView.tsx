'use client'

import React, { useState, useRef, useEffect } from 'react'
import {
  Video,
  Play,
  Pause,
  FlipHorizontal,
  Camera,
  Gauge,
  Plus,
  Clock,
  Sparkles,
} from 'lucide-react'
import { RotateCCWIcon } from '@/components/icons/RotateCCWIcon'
import { RepeatIcon } from '@/components/icons/RepeatIcon'

export default function StudioView() {
  const [isPlaying, setIsPlaying] = useState(false)
  const [playbackSpeed, setPlaybackSpeed] = useState<number>(1.0)
  const [isMirrored, setIsMirrored] = useState(false)
  const [isWebcamActive, setIsWebcamActive] = useState(false)
  const [isLooping, setIsLooping] = useState(true)
  const [coachNotes, setCoachNotes] = useState<
    { id: string; time: string; text: string; author: string }[]
  >([
    {
      id: '1',
      time: '0:14',
      text: 'Znížiť ťažisko pred začiatkom Natural Turn a počkať na partnerku.',
      author: 'Tréner Mirko',
    },
    {
      id: '2',
      time: '0:32',
      text: 'Otvoriť hlavu v Promenade Position, udržať ľavý lakeť v horizontále.',
      author: 'Tréner Mirko',
    },
    {
      id: '3',
      time: '0:58',
      text: 'Výborný nášľap na pätu v Chassé from PP, zachovať plynulý swing.',
      author: 'Môj rozbor',
    },
  ])
  const [newNote, setNewNote] = useState('')

  const webcamVideoRef = useRef<HTMLVideoElement>(null)

  // Handle webcam toggle
  useEffect(() => {
    let stream: MediaStream | null = null

    if (isWebcamActive) {
      navigator.mediaDevices
        ?.getUserMedia({ video: true, audio: false })
        .then(s => {
          stream = s
          if (webcamVideoRef.current) {
            webcamVideoRef.current.srcObject = s
          }
        })
        .catch(err => {
          console.warn('Webcam not accessible:', err)
          setIsWebcamActive(false)
        })
    } else {
      if (webcamVideoRef.current && webcamVideoRef.current.srcObject) {
        const s = webcamVideoRef.current.srcObject as MediaStream
        s.getTracks().forEach(t => t.stop())
        webcamVideoRef.current.srcObject = null
      }
    }

    return () => {
      if (stream) {
        stream.getTracks().forEach(t => t.stop())
      }
    }
  }, [isWebcamActive])

  const handleAddCoachNote = () => {
    if (!newNote.trim()) return
    const entry = {
      id: Date.now().toString(),
      time: '0:45',
      text: newNote.trim(),
      author: 'Tanečník',
    }
    setCoachNotes([entry, ...coachNotes])
    setNewNote('')
  }

  return (
    <div className="w-full max-w-5xl mx-auto px-4 py-8 pb-32 space-y-6 animate-fadeIn">
      {/* ── Top Header ────────────────────────────────────────────────── */}
      <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
        <div>
          <div className="inline-flex items-center gap-1.5 px-3 py-0.5 rounded-full bg-[#E11D48]/15 border border-[#E11D48]/30 text-[#FDA4AF] text-xs font-black uppercase tracking-wider mb-2">
            <Video className="w-3 h-3" />
            Dance Mirror & Dual Studio
          </div>
          <h2 className="text-3xl font-black text-white tracking-tight">Tanečné Štúdio</h2>
          <p className="text-white/50 text-sm">
            Porovnávaj svoje video s referenčným majstrom, nahrávaj pokusy cez zrkadlo a spomaľuj
            kroky.
          </p>
        </div>

        {/* Studio Action Controls */}
        <div className="flex items-center gap-2">
          {/* Mirror Flip Toggle */}
          <button
            onClick={() => setIsMirrored(!isMirrored)}
            className={`flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
              isMirrored
                ? 'bg-[#D4AF37] text-black shadow-[0_0_15px_rgba(212,175,55,0.4)]'
                : 'bg-white/[0.06] hover:bg-white/[0.12] text-white/80'
            }`}
          >
            <FlipHorizontal className="w-4 h-4" />
            <span>{isMirrored ? 'Zrkadlo: Zapnuté' : 'Zrkadlo'}</span>
          </button>

          {/* Webcam Record Toggle */}
          <button
            onClick={() => setIsWebcamActive(!isWebcamActive)}
            className={`flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
              isWebcamActive
                ? 'bg-rose-600 text-white animate-pulse shadow-[0_0_15px_rgba(225,29,72,0.5)]'
                : 'bg-white/[0.06] hover:bg-white/[0.12] text-white/80'
            }`}
          >
            <Camera className="w-4 h-4" />
            <span>{isWebcamActive ? 'Kamera aktívna' : 'Zapnúť webkameru'}</span>
          </button>
        </div>
      </div>

      {/* ── Dual Video Player Section ─────────────────────────────────── */}
      <section className="rounded-3xl p-6 bg-[#0f070b]/80 border border-white/[0.1] shadow-2xl backdrop-blur-xl space-y-6">
        {/* Videos Container */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {/* Left: My Practice Video / Webcam */}
          <div className="relative aspect-video rounded-2xl bg-black/60 border border-white/[0.08] overflow-hidden flex flex-col items-center justify-center group shadow-inner">
            {isWebcamActive ? (
              <video
                ref={webcamVideoRef}
                autoPlay
                playsInline
                muted
                className={`w-full h-full object-cover ${isMirrored ? 'scale-x-[-1]' : ''}`}
              />
            ) : (
              <div
                className={`w-full h-full flex flex-col items-center justify-center p-6 text-center bg-gradient-to-br from-[#1c0812] to-[#0a0206] ${
                  isMirrored ? 'scale-x-[-1]' : ''
                }`}
              >
                <div className="w-14 h-14 rounded-full bg-white/[0.06] flex items-center justify-center mb-3">
                  <Video className="w-7 h-7 text-[#D4AF37]" />
                </div>
                <h4 className="text-sm font-bold text-white">Môj tréningový záznam</h4>
                <p className="text-xs text-white/40 mt-1 max-w-xs">
                  Nahraj video zo súboru alebo zapni webkameru vyššie pre živý nácvik.
                </p>
              </div>
            )}

            {/* Label badge */}
            <div className="absolute top-3 left-3 px-2.5 py-1 rounded-md bg-black/70 backdrop-blur-md border border-white/10 text-[10px] font-black uppercase text-white tracking-wider">
              {isWebcamActive ? '🔴 Živá webkamera' : 'Môj pokus'}
            </div>
          </div>

          {/* Right: Master Reference Video */}
          <div className="relative aspect-video rounded-2xl bg-black/60 border border-white/[0.08] overflow-hidden flex flex-col items-center justify-center group shadow-inner">
            <div
              className={`w-full h-full flex flex-col items-center justify-center p-6 text-center bg-gradient-to-br from-[#12081a] to-[#04020a] ${
                isMirrored ? 'scale-x-[-1]' : ''
              }`}
            >
              <div className="w-14 h-14 rounded-full bg-[#D4AF37]/15 border border-[#D4AF37]/30 flex items-center justify-center mb-3">
                <Sparkles className="w-7 h-7 text-[#FFE088]" />
              </div>
              <h4 className="text-sm font-bold text-white">Referenčný vzor (Majster / Idol)</h4>
              <p className="text-xs text-white/40 mt-1 max-w-xs">
                Porovnaj držanie rámu, časovanie a rotáciu v tele so svetovým šampiónom.
              </p>
            </div>

            {/* Label badge */}
            <div className="absolute top-3 left-3 px-2.5 py-1 rounded-md bg-[#D4AF37]/20 backdrop-blur-md border border-[#D4AF37]/30 text-[10px] font-black uppercase text-[#FFE088] tracking-wider">
              ⭐ Referenčný vzor
            </div>
          </div>
        </div>

        {/* ── Playback Controls Bar ───────────────────────────────────── */}
        <div className="p-4 rounded-2xl bg-white/[0.02] border border-white/[0.06] flex flex-wrap items-center justify-between gap-4">
          {/* Play/Pause & Reset */}
          <div className="flex items-center gap-3">
            <button
              onClick={() => setIsPlaying(!isPlaying)}
              className="w-11 h-11 rounded-full bg-gradient-to-r from-[#D4AF37] to-[#B8861E] text-black flex items-center justify-center shadow-lg hover:brightness-110 active:scale-95 transition-all cursor-pointer"
            >
              {isPlaying ? (
                <Pause className="w-5 h-5 fill-black" />
              ) : (
                <Play className="w-5 h-5 fill-black ml-0.5" />
              )}
            </button>
            {/* Restart Video */}
            <button
              onClick={() => setIsPlaying(false)}
              title="Reštartovať video od začiatku"
              className="p-2.5 rounded-full bg-white/[0.05] hover:bg-white/[0.1] text-white/60 hover:text-white transition-colors cursor-pointer group"
            >
              <RotateCCWIcon size={16} />
            </button>

            {/* Repeat / Loop Video */}
            <button
              onClick={() => setIsLooping(!isLooping)}
              title={isLooping ? 'Vypnúť opakovanie (Loop ON)' : 'Zapnúť opakovanie videa (Loop)'}
              className={`p-2.5 rounded-full transition-colors cursor-pointer ${
                isLooping
                  ? 'bg-[#D4AF37]/20 border border-[#D4AF37]/50 text-[#D4AF37]'
                  : 'bg-white/[0.05] hover:bg-white/[0.1] text-white/60 hover:text-white'
              }`}
            >
              <RepeatIcon size={16} />
            </button>

            <span className="text-xs font-mono font-bold text-white/80">00:14 / 01:30</span>
          </div>

          {/* Speed Controls (0.5x, 0.75x, 1x, 1.25x) */}
          <div className="flex items-center gap-1.5 p-1 rounded-xl bg-black/40 border border-white/[0.08]">
            <Gauge className="w-3.5 h-3.5 text-white/40 ml-2 mr-1" />
            {[0.5, 0.75, 1.0, 1.25].map(speed => (
              <button
                key={speed}
                onClick={() => setPlaybackSpeed(speed)}
                className={`px-2.5 py-1 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                  playbackSpeed === speed
                    ? 'bg-[#D4AF37] text-black'
                    : 'text-white/50 hover:text-white'
                }`}
              >
                {speed}x
              </button>
            ))}
          </div>
        </div>
      </section>

      {/* ── Coach Timestamp Notes ─────────────────────────────────────── */}
      <section className="rounded-3xl p-6 bg-[#0f070b]/80 border border-white/[0.1] shadow-2xl backdrop-blur-xl space-y-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Clock className="w-4 h-4 text-[#D4AF37]" />
            <h3 className="text-sm font-black uppercase tracking-wider text-white">
              Technické pripomienky trénera s časovým kódom
            </h3>
          </div>
          <span className="text-xs text-white/40">{coachNotes.length} poznámok</span>
        </div>

        {/* Add Note Row */}
        <div className="flex items-center gap-2">
          <input
            type="text"
            value={newNote}
            onChange={e => setNewNote(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && handleAddCoachNote()}
            placeholder="Pridaj pripomienku k aktuálnemu času (napr. 'Opraviť nášľap dámy')..."
            className="flex-1 px-4 py-2.5 rounded-xl bg-white/[0.04] border border-white/[0.08] text-xs text-white placeholder-white/30 focus:outline-none focus:border-[#D4AF37]/50"
          />
          <button
            onClick={handleAddCoachNote}
            className="flex items-center gap-1 px-4 py-2.5 rounded-xl bg-gradient-to-r from-[#D4AF37] to-[#B8861E] text-black font-bold text-xs hover:brightness-110 active:scale-95 transition-all cursor-pointer shadow-[0_2px_12px_rgba(212,175,55,0.3)]"
          >
            <Plus className="w-3.5 h-3.5" />
            <span>Pridať</span>
          </button>
        </div>

        {/* Notes List */}
        <div className="space-y-2 pt-2">
          {coachNotes.map(n => (
            <div
              key={n.id}
              className="p-3 rounded-xl bg-white/[0.02] hover:bg-white/[0.04] border border-white/[0.06] flex items-start justify-between gap-4 transition-colors"
            >
              <div className="flex items-start gap-3">
                <span className="px-2 py-0.5 rounded bg-[#D4AF37]/20 border border-[#D4AF37]/30 text-[#FFE088] font-mono text-[11px] font-black shrink-0 mt-0.5">
                  {n.time}
                </span>
                <span className="text-xs text-white/80 leading-relaxed">{n.text}</span>
              </div>
              <span className="text-[10px] text-white/35 font-medium shrink-0">{n.author}</span>
            </div>
          ))}
        </div>
      </section>
    </div>
  )
}
