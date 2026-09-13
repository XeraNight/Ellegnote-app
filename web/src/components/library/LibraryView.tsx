'use client'

import React, { useState } from 'react'
import { FigureItem } from '@/components/RealtimeCanvas'
import { BookOpen, Search, Star, Plus, Footprints, Compass } from 'lucide-react'
import { DropletIcon } from '@/components/icons/DropletIcon'
import { FlameIcon } from '@/components/icons/FlameIcon'

interface LibraryViewProps {
  availableFigures: FigureItem[]
  onAddFigureToRoutine?: (figure: FigureItem) => void
}

const DANCES = [
  { id: 'all', name: 'Všetky tance', category: 'all' },
  { id: 'waltz', name: 'Waltz', category: 'standard' },
  { id: 'tango', name: 'Tango', category: 'standard' },
  { id: 'valcik', name: 'Valčík', category: 'standard' },
  { id: 'slowfox', name: 'Slowfox', category: 'standard' },
  { id: 'quickstep', name: 'Quickstep', category: 'standard' },
  { id: 'samba', name: 'Samba', category: 'latin' },
  { id: 'chacha', name: 'Cha-Cha', category: 'latin' },
  { id: 'rumba', name: 'Rumba', category: 'latin' },
  { id: 'paso', name: 'Paso Doble', category: 'latin' },
  { id: 'jive', name: 'Jive', category: 'latin' },
]

// Fallback high-fidelity dance figures if DB is empty
const DEFAULT_SYLLABUS: (FigureItem & { footwork: string; alignment: string; stars: number })[] = [
  {
    id: 'w1',
    name: 'Natural Turn',
    dance_name: 'Waltz',
    rhythm: '1 2 3',
    technique_notes: 'Pravotočivá otáčka. Začať čelom k stene, stúpanie na konci 1, zníženie na konci 3.',
    footwork: 'HT - T - TH',
    alignment: 'Diagonal to Wall',
    stars: 5,
    is_custom: false,
  },
  {
    id: 'w2',
    name: 'Reverse Turn',
    dance_name: 'Waltz',
    rhythm: '1 2 3',
    technique_notes: 'Ľavotočivá otáčka. Partner vedie dámu do heel turnu na 2. kroku.',
    footwork: 'HT - T - TH',
    alignment: 'Diagonal to Center',
    stars: 4,
    is_custom: false,
  },
  {
    id: 't1',
    name: 'Walks & Progressive Link',
    dance_name: 'Tango',
    rhythm: 'S S Q Q',
    technique_notes: 'Bez stúpania. Ostrý nášľap na päty s okamžitým natočením do Promenade Position.',
    footwork: 'H - H - H - IE of T',
    alignment: 'Along LOD into PP',
    stars: 5,
    is_custom: false,
  },
  {
    id: 't2',
    name: 'Closed Promenade',
    dance_name: 'Tango',
    rhythm: 'S Q Q S',
    technique_notes: 'Návrat z promenádneho postavenia do uzavretého držania na 4. dobe.',
    footwork: 'H - H - H - WF',
    alignment: 'Facing DW',
    stars: 4,
    is_custom: false,
  },
  {
    id: 's1',
    name: 'Feather Step',
    dance_name: 'Slowfox',
    rhythm: 'S Q Q',
    technique_notes: 'Kľúčová slowfoxová figúra. Telo predbieha nohy, plynulý swing bez straty rovnováhy.',
    footwork: 'HT - T - TH',
    alignment: 'Diagonal to Center',
    stars: 4,
    is_custom: false,
  },
  {
    id: 's2',
    name: 'Three Step',
    dance_name: 'Slowfox',
    rhythm: 'S Q Q',
    technique_notes: 'Tri plynulé kroky vpred. Päta - päta - špička s mäkkým znížením na konci.',
    footwork: 'H - H - TH',
    alignment: 'Along LOD',
    stars: 4,
    is_custom: false,
  },
  {
    id: 'r1',
    name: 'Open Hip Twist',
    dance_name: 'Rumba',
    rhythm: '2 3 4 1',
    technique_notes: 'Rotácia v panve na 4 1, natiahnuté stojné nohy, latinský krížový nášľap.',
    footwork: 'B - B - B - BF',
    alignment: 'Facing Partner',
    stars: 5,
    is_custom: false,
  },
  {
    id: 'c1',
    name: 'Cha-Cha Chassé',
    dance_name: 'Cha-Cha',
    rhythm: '4 & 1',
    technique_notes: 'Rýchly rytmický syncopated chassé s ostrým vystretím kolien.',
    footwork: 'B - B - BF',
    alignment: 'Side to LOD',
    stars: 5,
    is_custom: false,
  },
]

export default function LibraryView({ availableFigures, onAddFigureToRoutine }: LibraryViewProps) {
  const [selectedDance, setSelectedDance] = useState('all')
  const [searchQuery, setSearchQuery] = useState('')
  const [ratings, setRatings] = useState<Record<string, number>>({})

  // Merge default high-fidelity syllabus with database figures
  const allFigures = [
    ...DEFAULT_SYLLABUS,
    ...availableFigures.map(f => ({
      ...f,
      footwork: 'T - TH',
      alignment: 'LOD Direction',
      stars: 3,
    })),
  ]

  const filteredFigures = allFigures.filter(fig => {
    const matchesDance =
      selectedDance === 'all' || fig.dance_name.toLowerCase().includes(selectedDance.toLowerCase())
    const matchesSearch =
      fig.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      fig.technique_notes.toLowerCase().includes(searchQuery.toLowerCase())
    return matchesDance && matchesSearch
  })

  const handleSetRating = (figId: string, stars: number) => {
    setRatings(prev => ({ ...prev, [figId]: stars }))
  }

  return (
    <div className="w-full max-w-5xl mx-auto px-4 py-8 pb-32 space-y-6 animate-fadeIn">
      {/* ── Top Header ────────────────────────────────────────────────── */}
      <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
        <div>
          <div className="inline-flex items-center gap-1.5 px-3 py-0.5 rounded-full bg-[#10B981]/15 border border-[#10B981]/30 text-[#6EE7B7] text-xs font-black uppercase tracking-wider mb-2">
            <BookOpen className="w-3 h-3" />
            WDSF & ISTD Syllabus
          </div>
          <h2 className="text-3xl font-black text-white tracking-tight">Knižnica Tanečných Figúr</h2>
          <p className="text-white/50 text-sm">
            Oficiálne figúry štandardných a latinských tancov s nášľapmi, rytmom a hodnotením.
          </p>
        </div>
      </div>

      {/* ── Search & Dance Filters ────────────────────────────────────── */}
      <div className="space-y-3 p-3 rounded-2xl bg-[#11070d]/80 border border-white/[0.08] backdrop-blur-xl">
        {/* Search */}
        <div className="relative w-full">
          <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-white/40" />
          <input
            type="text"
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
            placeholder="Hľadať figúru, technickú poznámku alebo nášľap..."
            className="w-full pl-9 pr-4 py-2.5 rounded-xl bg-white/[0.04] border border-white/[0.06] text-xs text-white placeholder-white/35 focus:outline-none focus:border-[#D4AF37]/50"
          />
        </div>

        {/* Dance Filter Pills */}
        <div className="flex items-center gap-1.5 overflow-x-auto pb-1 scrollbar-none">
          {DANCES.map(d => (
            <button
              key={d.id}
              onClick={() => setSelectedDance(d.id)}
              className={`px-3 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition-all cursor-pointer ${
                selectedDance === d.id
                  ? 'bg-gradient-to-r from-[#D4AF37] to-[#B8861E] text-black shadow-[0_2px_10px_rgba(212,175,55,0.3)]'
                  : 'bg-white/[0.04] hover:bg-white/[0.08] text-white/60 hover:text-white'
              }`}
            >
              {d.name}
            </button>
          ))}
        </div>
      </div>

      {/* ── Figure Cards Grid ─────────────────────────────────────────── */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {filteredFigures.map(fig => {
          const currentRating = ratings[fig.id] !== undefined ? ratings[fig.id] : fig.stars || 4
          const isStandard = [
            'waltz',
            'tango',
            'valcik',
            'slowfox',
            'quickstep',
          ].includes(fig.dance_name.toLowerCase())

          return (
            <div
              key={fig.id}
              className="p-5 rounded-3xl bg-gradient-to-b from-[#180a12]/90 to-[#0c0409]/90 border border-white/[0.08] hover:border-[#D4AF37]/40 shadow-xl transition-all duration-200 flex flex-col justify-between space-y-4 group"
            >
              <div>
                {/* Top Row: Dance Name & Rhythm */}
                <div className="flex items-center justify-between mb-2">
                  <span
                    className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-md text-[10px] font-black uppercase tracking-wider border ${
                      isStandard
                        ? 'bg-[#3B82F6]/20 text-[#93C5FD] border-[#3B82F6]/40'
                        : 'bg-[#E11D48]/20 text-[#FDA4AF] border-[#E11D48]/40'
                    }`}
                  >
                    {isStandard ? (
                      <DropletIcon size={12} className="shrink-0" />
                    ) : (
                      <FlameIcon size={12} className="shrink-0" />
                    )}
                    <span>{fig.dance_name}</span>
                  </span>

                  <span className="px-2 py-0.5 rounded bg-white/[0.05] border border-white/10 text-white/80 font-mono text-[11px] font-bold">
                    {fig.rhythm}
                  </span>
                </div>

                {/* Figure Title */}
                <h3 className="text-lg font-black text-white group-hover:text-[#FFE088] transition-colors">
                  {fig.name}
                </h3>

                {/* Footwork & Alignment Chips */}
                <div className="flex items-center gap-2 mt-2 flex-wrap text-[11px]">
                  <span className="flex items-center gap-1 px-2 py-0.5 rounded-md bg-white/[0.03] border border-white/[0.06] text-white/70">
                    <Footprints className="w-3 h-3 text-[#D4AF37]" />
                    <span>Nášľap: {fig.footwork}</span>
                  </span>
                  <span className="flex items-center gap-1 px-2 py-0.5 rounded-md bg-white/[0.03] border border-white/[0.06] text-white/70">
                    <Compass className="w-3 h-3 text-[#3B82F6]" />
                    <span>{fig.alignment}</span>
                  </span>
                </div>

                {/* Technique notes */}
                <p className="text-xs text-white/60 mt-2.5 leading-relaxed">
                  {fig.technique_notes}
                </p>
              </div>

              {/* Bottom Row: 5-Star Rating & Add Button */}
              <div className="pt-3 border-t border-white/[0.06] flex items-center justify-between">
                {/* Star rating */}
                <div className="flex items-center gap-1">
                  <span className="text-[10px] font-bold text-white/40 mr-1 uppercase">
                    Zvládnutie:
                  </span>
                  {[1, 2, 3, 4, 5].map(star => (
                    <button
                      key={star}
                      onClick={() => handleSetRating(fig.id, star)}
                      className="cursor-pointer text-white/20 hover:text-[#FFE088] transition-colors"
                    >
                      <Star
                        className={`w-3.5 h-3.5 ${
                          star <= currentRating
                            ? 'text-[#D4AF37] fill-[#D4AF37]'
                            : 'text-white/20'
                        }`}
                      />
                    </button>
                  ))}
                </div>

                {/* Add to Routine button */}
                {onAddFigureToRoutine && (
                  <button
                    onClick={() => onAddFigureToRoutine(fig)}
                    className="flex items-center gap-1 px-3 py-1 rounded-xl bg-white/[0.06] hover:bg-[#D4AF37] hover:text-black border border-white/10 text-white/80 text-[11px] font-bold transition-all cursor-pointer"
                  >
                    <Plus className="w-3 h-3" />
                    <span>Pridať na plátno</span>
                  </button>
                )}
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
