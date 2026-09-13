'use client'

import React, { useState, useEffect } from 'react'
import { signOut } from '../actions'
import EncoreStageBackdrop from '@/components/layout/EncoreStageBackdrop'
import EncoreHeader from '@/components/layout/EncoreHeader'
import LiquidGlassDock, { TabId } from '@/components/layout/LiquidGlassDock'
import HomeView from '@/components/home/HomeView'
import CanvasHubView from '@/components/canvas/CanvasHubView'
import StudioView from '@/components/studio/StudioView'
import LibraryView from '@/components/library/LibraryView'
import ProfileView from '@/components/profile/ProfileView'
import RealtimeCanvas, { RoutineInfo, FigureItem } from '@/components/RealtimeCanvas'
import CommandPalette from '@/components/modals/CommandPalette'
import QRCodeModal from '@/components/modals/QRCodeModal'
import { createClient } from '@/lib/supabase/client'
import { X, Plus, Sparkles } from 'lucide-react'
import { DropletIcon } from '@/components/icons/DropletIcon'
import { FlameIcon } from '@/components/icons/FlameIcon'

type Props = {
  user: { email: string; id: string }
  routines: RoutineInfo[]
  figures: FigureItem[]
}

const DANCE_OPTIONS = [
  { name: 'Waltz', category: 'standard' },
  { name: 'Tango', category: 'standard' },
  { name: 'Valčík', category: 'standard' },
  { name: 'Slowfox', category: 'standard' },
  { name: 'Quickstep', category: 'standard' },
  { name: 'Samba', category: 'latin' },
  { name: 'Cha-Cha', category: 'latin' },
  { name: 'Rumba', category: 'latin' },
  { name: 'Paso Doble', category: 'latin' },
  { name: 'Jive', category: 'latin' },
]

export default function DashboardClient({ user, routines: initialRoutines, figures }: Props) {
  const supabase = createClient()
  const [routinesList, setRoutinesList] = useState<RoutineInfo[]>(initialRoutines)
  const [activeTab, setActiveTab] = useState<TabId>('home')
  const [activeCanvasRoutine, setActiveCanvasRoutine] = useState<RoutineInfo | null>(null)

  // Modals
  const [isCommandPaletteOpen, setIsCommandPaletteOpen] = useState(false)
  const [isQRCodeOpen, setIsQRCodeOpen] = useState(false)
  const [isCreateRoutineOpen, setIsCreateRoutineOpen] = useState(false)

  // Create Routine Form State
  const [newRoutineName, setNewRoutineName] = useState('')
  const [selectedDance, setSelectedDance] = useState(DANCE_OPTIONS[0])
  const [isCreating, setIsCreating] = useState(false)

  // Global Keyboard Shortcut: Cmd+K / Ctrl+K
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault()
        setIsCommandPaletteOpen(prev => !prev)
      }
    }
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [])

  // Create Routine Handler
  const handleCreateRoutineSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!newRoutineName.trim() || isCreating) return
    setIsCreating(true)

    const newRoutine: RoutineInfo = {
      id: crypto.randomUUID(),
      name: newRoutineName.trim(),
      dance_name: selectedDance.name,
      dance_category: selectedDance.category,
      updated_at: new Date().toISOString(),
      last_modified_by: user.email,
    }

    // Try saving to Supabase
    try {
      const { data, error } = await supabase
        .from('routines')
        .insert({
          id: newRoutine.id,
          name: newRoutine.name,
          dance_name: newRoutine.dance_name,
          dance_category: newRoutine.dance_category,
          user_id: user.id,
          updated_at: newRoutine.updated_at,
        })
        .select()
        .single()

      if (!error && data) {
        setRoutinesList([data, ...routinesList])
        setActiveCanvasRoutine(data)
      } else {
        // Fallback local update
        setRoutinesList([newRoutine, ...routinesList])
        setActiveCanvasRoutine(newRoutine)
      }
    } catch (err) {
      console.warn('Error inserting routine:', err)
      setRoutinesList([newRoutine, ...routinesList])
      setActiveCanvasRoutine(newRoutine)
    }

    setIsCreating(false)
    setIsCreateRoutineOpen(false)
    setNewRoutineName('')
  }

  return (
    <div className="min-h-screen bg-[#060204] text-white selection:bg-[#D4AF37]/30 font-sans relative overflow-x-hidden">
      {/* ── 1. Velvet Theatre Stage Backdrop & Spotlight ─────────────── */}
      <EncoreStageBackdrop />

      {/* ── 2. Glass Pinned Header with Animated Logo ─────────────────── */}
      <EncoreHeader
        userEmail={user.email}
        onOpenCommandPalette={() => setIsCommandPaletteOpen(true)}
        onOpenQRCode={() => setIsQRCodeOpen(true)}
        onSignOut={() => signOut()}
      />

      {/* ── 3. Main Views Container (5 Tabs) ──────────────────────────── */}
      <main className="relative z-10">
        {activeTab === 'home' && (
          <HomeView
            routines={routinesList}
            userEmail={user.email}
            onOpenRoutine={routine => setActiveCanvasRoutine(routine)}
            onNavigateTab={tab => setActiveTab(tab)}
            onCreateRoutine={() => setIsCreateRoutineOpen(true)}
          />
        )}

        {activeTab === 'canvas' && (
          <CanvasHubView
            routines={routinesList}
            onOpenRoutine={routine => setActiveCanvasRoutine(routine)}
            onCreateRoutine={() => setIsCreateRoutineOpen(true)}
          />
        )}

        {activeTab === 'studio' && <StudioView />}

        {activeTab === 'library' && (
          <LibraryView
            availableFigures={figures}
            onAddFigureToRoutine={() => {
              // If there's an active routine, open it; otherwise open first routine
              const targetRoutine = activeCanvasRoutine || routinesList[0]
              if (targetRoutine) {
                setActiveCanvasRoutine(targetRoutine)
              } else {
                setIsCreateRoutineOpen(true)
              }
            }}
          />
        )}

        {activeTab === 'profile' && (
          <ProfileView
            userEmail={user.email}
            routinesCount={routinesList.length}
            figuresCount={figures.length}
            onOpenQRCode={() => setIsQRCodeOpen(true)}
          />
        )}
      </main>

      {/* ── 4. iOS 18 Liquid Glass Floating Dock ──────────────────────── */}
      <LiquidGlassDock activeTab={activeTab} onTabChange={tab => setActiveTab(tab)} />

      {/* ── 5. Fullscreen Realtime Ballroom Canvas Overlay ─────────────── */}
      {activeCanvasRoutine && (
        <RealtimeCanvas
          routine={activeCanvasRoutine}
          user={user}
          availableFigures={figures}
          onClose={() => setActiveCanvasRoutine(null)}
        />
      )}

      {/* ── 6. Command Palette (Cmd+K) ────────────────────────────────── */}
      <CommandPalette
        isOpen={isCommandPaletteOpen}
        onClose={() => setIsCommandPaletteOpen(false)}
        routines={routinesList}
        onOpenRoutine={routine => setActiveCanvasRoutine(routine)}
        onNavigateTab={tab => setActiveTab(tab)}
        onCreateRoutine={() => setIsCreateRoutineOpen(true)}
        onSignOut={() => signOut()}
      />

      {/* ── 7. QR Code Modal ─────────────────────────────────────────── */}
      <QRCodeModal
        isOpen={isQRCodeOpen}
        onClose={() => setIsQRCodeOpen(false)}
        userEmail={user.email}
      />

      {/* ── 8. Create Routine Modal ───────────────────────────────────── */}
      {isCreateRoutineOpen && (
        <div
          onClick={() => setIsCreateRoutineOpen(false)}
          className="fixed inset-0 z-50 bg-black/80 backdrop-blur-md flex items-center justify-center p-4 select-none animate-fadeIn"
        >
          <div
            onClick={e => e.stopPropagation()}
            className="w-full max-w-md rounded-3xl p-6 bg-gradient-to-b from-[#1b0812]/95 to-[#0b0307]/95 border border-[#D4AF37]/40 shadow-[0_25px_70px_rgba(0,0,0,0.9)] space-y-5"
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-xl bg-[#D4AF37]/20 flex items-center justify-center text-[#FFE088]">
                  <Plus className="w-4 h-4" />
                </div>
                <h3 className="text-lg font-black text-white">Nová Choreografia</h3>
              </div>
              <button
                onClick={() => setIsCreateRoutineOpen(false)}
                className="p-1.5 rounded-full bg-white/[0.06] hover:bg-white/[0.12] text-white/60 hover:text-white"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleCreateRoutineSubmit} className="space-y-4">
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-white/60 uppercase tracking-wider">
                  Názov zostavy
                </label>
                <input
                  autoFocus
                  type="text"
                  value={newRoutineName}
                  onChange={e => setNewRoutineName(e.target.value)}
                  placeholder="Napr. Súťažná choreografia 2026..."
                  className="w-full px-4 py-3 rounded-xl bg-white/[0.04] border border-white/[0.08] focus:border-[#D4AF37]/50 text-sm text-white placeholder-white/30 outline-none font-medium"
                />
              </div>

              <div className="space-y-1.5">
                <label className="text-xs font-bold text-white/60 uppercase tracking-wider">
                  Výber tanca
                </label>
                <div className="grid grid-cols-2 gap-2 max-h-48 overflow-y-auto pr-1">
                  {DANCE_OPTIONS.map(d => (
                    <button
                      key={d.name}
                      type="button"
                      onClick={() => setSelectedDance(d)}
                      className={`p-2.5 rounded-xl text-xs font-bold text-left transition-all border cursor-pointer ${
                        selectedDance.name === d.name
                          ? 'bg-[#D4AF37]/20 border-[#D4AF37] text-[#FFE088]'
                          : 'bg-white/[0.02] border-white/[0.06] text-white/60 hover:text-white hover:bg-white/[0.05]'
                      }`}
                    >
                      <div className="flex items-center justify-between">
                        <span>{d.name}</span>
                        {d.category === 'standard' ? (
                          <DropletIcon size={12} className="text-[#93C5FD]" />
                        ) : (
                          <FlameIcon size={12} className="text-[#FDA4AF]" />
                        )}
                      </div>
                      <div className="text-[10px] text-white/40 uppercase mt-0.5">
                        {d.category === 'standard' ? 'Štandard' : 'Latina'}
                      </div>
                    </button>
                  ))}
                </div>
              </div>

              <button
                type="submit"
                disabled={!newRoutineName.trim() || isCreating}
                className="w-full py-3 rounded-full bg-gradient-to-r from-[#D4AF37] to-[#B8861E] text-black font-black text-xs hover:brightness-110 active:scale-95 transition-all shadow-[0_4px_16px_rgba(212,175,55,0.4)] disabled:opacity-30 disabled:pointer-events-none cursor-pointer flex items-center justify-center gap-2"
              >
                <Sparkles className="w-4 h-4" />
                <span>{isCreating ? 'Vytváram zostavu...' : 'Vytvoriť a Otvoriť Plátno'}</span>
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}
