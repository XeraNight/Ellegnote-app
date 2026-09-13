'use client'

import React, { useState } from 'react'
import { RoutineInfo } from '@/components/RealtimeCanvas'
import { Plus, Search, Compass, Calendar, ArrowRight, Sparkles } from 'lucide-react'
import { DropletIcon } from '@/components/icons/DropletIcon'
import { FlameIcon } from '@/components/icons/FlameIcon'

interface CanvasHubViewProps {
  routines: RoutineInfo[]
  onOpenRoutine: (routine: RoutineInfo) => void
  onCreateRoutine: () => void
}

export default function CanvasHubView({
  routines,
  onOpenRoutine,
  onCreateRoutine,
}: CanvasHubViewProps) {
  const [filterCategory, setFilterCategory] = useState<'all' | 'standard' | 'latin'>('all')
  const [searchQuery, setSearchQuery] = useState('')

  const filteredRoutines = routines.filter(r => {
    const matchesCat =
      filterCategory === 'all' ||
      r.dance_category?.toLowerCase() === filterCategory.toLowerCase()
    const matchesSearch =
      r.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.dance_name.toLowerCase().includes(searchQuery.toLowerCase())
    return matchesCat && matchesSearch
  })

  return (
    <div className="w-full max-w-5xl mx-auto px-4 py-8 pb-32 space-y-6 animate-fadeIn">
      {/* ── Top Header & Actions ────────────────────────────────────────── */}
      <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
        <div>
          <div className="inline-flex items-center gap-1.5 px-3 py-0.5 rounded-full bg-[#3B82F6]/15 border border-[#3B82F6]/30 text-[#93C5FD] text-xs font-black uppercase tracking-wider mb-2">
            <Compass className="w-3 h-3" />
            Ballroom Routines Hub
          </div>
          <h2 className="text-3xl font-black text-white tracking-tight">Choreografie na Plátne</h2>
          <p className="text-white/50 text-sm">
            Spravuj svoje tanečné zostavy na 2:3 parkete s LOD navigáciou.
          </p>
        </div>

        <button
          onClick={onCreateRoutine}
          className="flex items-center gap-2 px-5 py-3 rounded-full bg-gradient-to-r from-[#D4AF37] to-[#B8861E] text-black font-black text-xs hover:brightness-110 active:scale-95 transition-all shadow-[0_4px_20px_rgba(212,175,55,0.35)] cursor-pointer shrink-0"
        >
          <Plus className="w-4 h-4" />
          <span>Nová Choreografia</span>
        </button>
      </div>

      {/* ── Search & Filter Controls ────────────────────────────────────── */}
      <div className="flex flex-col sm:flex-row items-center justify-between gap-3 p-2 rounded-2xl bg-[#11070d]/80 border border-white/[0.08] backdrop-blur-xl">
        {/* Search Bar */}
        <div className="relative w-full sm:w-80">
          <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-white/40" />
          <input
            type="text"
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
            placeholder="Hľadať podľa názvu alebo tanca..."
            className="w-full pl-9 pr-4 py-2 rounded-xl bg-white/[0.04] border border-white/[0.06] text-xs text-white placeholder-white/35 focus:outline-none focus:border-[#D4AF37]/50"
          />
        </div>

        {/* Filter Pills */}
        <div className="flex items-center gap-1.5 w-full sm:w-auto overflow-x-auto">
          <button
            onClick={() => setFilterCategory('all')}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all cursor-pointer ${
              filterCategory === 'all'
                ? 'bg-white/20 text-white border border-white/30 shadow'
                : 'bg-white/[0.04] text-white/50 hover:text-white'
            }`}
          >
            Všetky ({routines.length})
          </button>
          <button
            onClick={() => setFilterCategory('standard')}
            className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all cursor-pointer ${
              filterCategory === 'standard'
                ? 'bg-[#3B82F6]/30 text-[#93C5FD] border border-[#3B82F6]/50 shadow'
                : 'bg-white/[0.04] text-white/50 hover:text-white'
            }`}
          >
            <DropletIcon size={14} className="text-[#93C5FD]" />
            <span>Štandard</span>
          </button>
          <button
            onClick={() => setFilterCategory('latin')}
            className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all cursor-pointer ${
              filterCategory === 'latin'
                ? 'bg-[#E11D48]/30 text-[#FDA4AF] border border-[#E11D48]/50 shadow'
                : 'bg-white/[0.04] text-white/50 hover:text-white'
            }`}
          >
            <FlameIcon size={14} className="text-[#FDA4AF]" />
            <span>Latina</span>
          </button>
        </div>
      </div>

      {/* ── Routines Grid ───────────────────────────────────────────────── */}
      {filteredRoutines.length === 0 ? (
        <div className="py-20 text-center rounded-3xl bg-white/[0.02] border border-white/[0.06] space-y-3">
          <Compass className="w-12 h-12 text-white/20 mx-auto" />
          <h3 className="text-base font-bold text-white/70">Žiadne choreografie sa nenašli</h3>
          <p className="text-xs text-white/40 max-w-sm mx-auto">
            Vytvor svoju prvú zostavu pomocou tlačidla vyššie.
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
          {filteredRoutines.map(routine => {
            const isStandard = routine.dance_category?.toLowerCase() === 'standard'
            const accentBg = isStandard ? 'bg-[#3B82F6]/20' : 'bg-[#E11D48]/20'
            const accentText = isStandard ? 'text-[#93C5FD]' : 'text-[#FDA4AF]'
            const accentBorder = isStandard ? 'border-[#3B82F6]/40' : 'border-[#E11D48]/40'

            return (
              <div
                key={routine.id}
                onClick={() => onOpenRoutine(routine)}
                className="group p-5 rounded-3xl bg-gradient-to-b from-[#180a12]/90 to-[#0c0409]/90 border border-white/[0.08] hover:border-[#D4AF37]/50 shadow-xl hover:shadow-[0_12px_35px_rgba(212,175,55,0.15)] transition-all duration-200 cursor-pointer flex flex-col justify-between h-56 relative overflow-hidden"
              >
                {/* Top Row: Category badge with animated Droplet/Flame & LOD Compass Icon */}
                <div className="flex items-center justify-between">
                  <span
                    className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-md text-[10px] font-black uppercase tracking-wider ${accentBg} ${accentText} border ${accentBorder}`}
                  >
                    {isStandard ? (
                      <DropletIcon size={12} className="shrink-0" />
                    ) : (
                      <FlameIcon size={12} className="shrink-0" />
                    )}
                    <span>{routine.dance_name}</span>
                  </span>
                  <span className="text-[11px] font-medium text-white/35 flex items-center gap-1">
                    <Calendar className="w-3 h-3" />
                    {new Date(routine.updated_at).toLocaleDateString('sk-SK')}
                  </span>
                </div>

                {/* Center: Routine Title & Category */}
                <div>
                  <h3 className="text-lg font-black text-white group-hover:text-[#FFE088] transition-colors leading-snug">
                    {routine.name}
                  </h3>
                  <p className="text-xs text-white/50 mt-1">
                    Kategória: {routine.dance_category || 'Štandard'}
                  </p>
                </div>

                {/* Bottom Row: CTA Button */}
                <div className="pt-3 border-t border-white/[0.06] flex items-center justify-between">
                  <span className="text-xs font-bold text-[#D4AF37] flex items-center gap-1">
                    <Sparkles className="w-3.5 h-3.5" />
                    Otvoriť 2:3 Parket
                  </span>
                  <div className="w-8 h-8 rounded-full bg-white/[0.06] group-hover:bg-[#D4AF37] group-hover:text-black flex items-center justify-center text-white/70 transition-all">
                    <ArrowRight className="w-4 h-4" />
                  </div>
                </div>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}
