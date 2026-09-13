'use client'

import React, { useState, useEffect } from 'react'
import { Search, Compass, BookOpen, Video, Plus, User, LogOut } from 'lucide-react'
import { RoutineInfo } from '@/components/RealtimeCanvas'

interface CommandPaletteProps {
  isOpen: boolean
  onClose: () => void
  routines: RoutineInfo[]
  onOpenRoutine: (routine: RoutineInfo) => void
  onNavigateTab: (tab: 'canvas' | 'studio' | 'library' | 'profile') => void
  onCreateRoutine: () => void
  onSignOut: () => void
}

export default function CommandPalette({
  isOpen,
  onClose,
  routines,
  onOpenRoutine,
  onNavigateTab,
  onCreateRoutine,
  onSignOut,
}: CommandPaletteProps) {
  const [query, setQuery] = useState('')

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault()
        if (isOpen) onClose()
        else setQuery('')
      } else if (e.key === 'Escape' && isOpen) {
        onClose()
      }
    }
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [isOpen, onClose])

  if (!isOpen) return null

  const filteredRoutines = routines.filter(
    r =>
      r.name.toLowerCase().includes(query.toLowerCase()) ||
      r.dance_name.toLowerCase().includes(query.toLowerCase())
  )

  return (
    <div
      onClick={onClose}
      className="fixed inset-0 z-50 bg-black/75 backdrop-blur-md flex items-start justify-center pt-24 px-4 select-none animate-fadeIn"
    >
      <div
        onClick={e => e.stopPropagation()}
        className="w-full max-w-xl rounded-3xl bg-[#12070f]/95 border border-[#D4AF37]/35 shadow-[0_25px_70px_rgba(0,0,0,0.85)] overflow-hidden"
      >
        {/* Search Input Bar */}
        <div className="p-4 border-b border-white/[0.08] flex items-center gap-3">
          <Search className="w-5 h-5 text-[#D4AF37]" />
          <input
            autoFocus
            type="text"
            value={query}
            onChange={e => setQuery(e.target.value)}
            placeholder="Hľadaj akciu, choreografiu alebo tanec..."
            className="w-full bg-transparent text-sm text-white placeholder-white/40 focus:outline-none font-medium"
          />
          <kbd className="px-2 py-0.5 rounded bg-white/10 text-[10px] font-mono text-white/50 border border-white/10">
            ESC
          </kbd>
        </div>

        {/* Results List */}
        <div className="max-h-96 overflow-y-auto p-2 space-y-1">
          {/* Quick Actions */}
          <div className="px-3 py-1.5 text-[10px] font-black uppercase tracking-widest text-[#D4AF37]">
            Rýchle akcie
          </div>

          <button
            onClick={() => {
              onCreateRoutine()
              onClose()
            }}
            className="w-full p-3 rounded-2xl hover:bg-white/[0.06] flex items-center gap-3 text-xs text-white/90 text-left transition-colors cursor-pointer"
          >
            <div className="w-7 h-7 rounded-xl bg-[#D4AF37]/20 flex items-center justify-center text-[#FFE088]">
              <Plus className="w-4 h-4" />
            </div>
            <div>
              <div className="font-bold">Vytvoriť novú choreografiu</div>
              <div className="text-[11px] text-white/40">Otvoriť sprievodcu novou zostavou</div>
            </div>
          </button>

          <button
            onClick={() => {
              onNavigateTab('studio')
              onClose()
            }}
            className="w-full p-3 rounded-2xl hover:bg-white/[0.06] flex items-center gap-3 text-xs text-white/90 text-left transition-colors cursor-pointer"
          >
            <div className="w-7 h-7 rounded-xl bg-rose-500/20 flex items-center justify-center text-rose-300">
              <Video className="w-4 h-4" />
            </div>
            <div>
              <div className="font-bold">Tanečné Štúdio (Dual Video)</div>
              <div className="text-[11px] text-white/40">Zrkadlový režim a video porovnávač</div>
            </div>
          </button>

          <button
            onClick={() => {
              onNavigateTab('library')
              onClose()
            }}
            className="w-full p-3 rounded-2xl hover:bg-white/[0.06] flex items-center gap-3 text-xs text-white/90 text-left transition-colors cursor-pointer"
          >
            <div className="w-7 h-7 rounded-xl bg-emerald-500/20 flex items-center justify-center text-emerald-300">
              <BookOpen className="w-4 h-4" />
            </div>
            <div>
              <div className="font-bold">Knižnica Figúr (Syllabus)</div>
              <div className="text-[11px] text-white/40">Katalóg figúr s nášľapmi a hodnotením</div>
            </div>
          </button>

          {/* Routines Matches */}
          {filteredRoutines.length > 0 && (
            <>
              <div className="px-3 pt-3 pb-1.5 text-[10px] font-black uppercase tracking-widest text-[#D4AF37]">
                Choreografie ({filteredRoutines.length})
              </div>
              {filteredRoutines.map(routine => (
                <button
                  key={routine.id}
                  onClick={() => {
                    onOpenRoutine(routine)
                    onClose()
                  }}
                  className="w-full p-3 rounded-2xl hover:bg-white/[0.06] flex items-center justify-between text-xs text-white text-left transition-colors cursor-pointer"
                >
                  <div className="flex items-center gap-3">
                    <Compass className="w-4 h-4 text-[#3B82F6]" />
                    <span className="font-bold">{routine.name}</span>
                  </div>
                  <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-white/10 text-[#FFE088]">
                    {routine.dance_name}
                  </span>
                </button>
              ))}
            </>
          )}

          {/* User Settings */}
          <div className="px-3 pt-3 pb-1.5 text-[10px] font-black uppercase tracking-widest text-white/40">
            Účet
          </div>

          <button
            onClick={() => {
              onNavigateTab('profile')
              onClose()
            }}
            className="w-full p-3 rounded-2xl hover:bg-white/[0.06] flex items-center gap-3 text-xs text-white/90 text-left transition-colors cursor-pointer"
          >
            <User className="w-4 h-4 text-white/60" />
            <span>Môj profil tanečníka & Párovanie partnera</span>
          </button>

          <button
            onClick={() => {
              onSignOut()
              onClose()
            }}
            className="w-full p-3 rounded-2xl hover:bg-rose-500/20 flex items-center gap-3 text-xs text-rose-300 text-left transition-colors cursor-pointer"
          >
            <LogOut className="w-4 h-4" />
            <span>Odhlásiť sa</span>
          </button>
        </div>
      </div>
    </div>
  )
}
