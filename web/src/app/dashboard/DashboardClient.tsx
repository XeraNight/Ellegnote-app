'use client'

import { useState } from 'react'
import { signOut } from '../actions'

type Routine = {
  id: string
  name: string
  dance_name: string
  dance_category: string
  updated_at: string
  last_modified_by?: string
}

type Figure = {
  id: string
  name: string
  dance_name: string
  rhythm: string
  technique_notes: string
  is_custom: boolean
}

type Props = {
  user: { email: string; id: string }
  routines: Routine[]
  figures: Figure[]
}

type Tab = 'routines' | 'figures'

export default function DashboardClient({ user, routines, figures }: Props) {
  const [tab, setTab] = useState<Tab>('routines')
  const [search, setSearch] = useState('')

  const filteredRoutines = routines.filter(r =>
    r.name.toLowerCase().includes(search.toLowerCase()) ||
    r.dance_name.toLowerCase().includes(search.toLowerCase())
  )

  const filteredFigures = figures.filter(f =>
    f.name.toLowerCase().includes(search.toLowerCase()) ||
    f.dance_name.toLowerCase().includes(search.toLowerCase())
  )

  return (
    <div className="min-h-screen bg-[#0f0f10] text-white">
      {/* ── Top Bar ─────────────────────────────────────────── */}
      <header className="sticky top-0 z-50 bg-[#0f0f10]/80 backdrop-blur-xl border-b border-[#1e1e22]">
        <div className="max-w-5xl mx-auto px-4 py-3 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-[#c9a96e] to-[#8b6340] flex items-center justify-center text-lg shadow">
              💃
            </div>
            <div>
              <h1 className="text-sm font-bold text-white leading-none">Ellegnote</h1>
              <p className="text-[10px] text-[#666] leading-none mt-0.5">{user.email}</p>
            </div>
          </div>

          <form action={signOut}>
            <button
              type="submit"
              className="text-xs text-[#888] hover:text-[#c9a96e] transition-colors px-3 py-1.5 rounded-lg hover:bg-[#1a1a1c]"
            >
              Odhlásiť
            </button>
          </form>
        </div>
      </header>

      <main className="max-w-5xl mx-auto px-4 py-6">
        {/* ── Search ─────────────────────────────────────────── */}
        <div className="relative mb-5">
          <svg
            className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-[#555]"
            fill="none" stroke="currentColor" viewBox="0 0 24 24"
          >
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
              d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
          <input
            type="search"
            placeholder="Hľadaj zostavy alebo figúry…"
            value={search}
            onChange={e => setSearch(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 bg-[#1a1a1c] border border-[#2a2a2e] rounded-xl text-sm text-white placeholder-[#555] focus:outline-none focus:ring-2 focus:ring-[#c9a96e]/50 transition-all"
          />
        </div>

        {/* ── Tabs ───────────────────────────────────────────── */}
        <div className="flex gap-1 bg-[#1a1a1c] p-1 rounded-xl mb-6">
          {(['routines', 'figures'] as Tab[]).map(t => (
            <button
              key={t}
              onClick={() => { setTab(t); setSearch('') }}
              className={`flex-1 py-2 rounded-lg text-sm font-medium transition-all ${
                tab === t
                  ? 'bg-gradient-to-r from-[#c9a96e] to-[#b8884a] text-white shadow'
                  : 'text-[#888] hover:text-white'
              }`}
            >
              {t === 'routines' ? `🗂 Zostavy (${routines.length})` : `📋 Figúry (${figures.length})`}
            </button>
          ))}
        </div>

        {/* ── Routines Tab ────────────────────────────────────── */}
        {tab === 'routines' && (
          <div className="space-y-3">
            {filteredRoutines.length === 0 ? (
              <EmptyState message="Žiadne zostavy" />
            ) : (
              filteredRoutines.map(r => (
                <RoutineCard key={r.id} routine={r} />
              ))
            )}
          </div>
        )}

        {/* ── Figures Tab ─────────────────────────────────────── */}
        {tab === 'figures' && (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
            {filteredFigures.length === 0 ? (
              <div className="col-span-full"><EmptyState message="Žiadne figúry" /></div>
            ) : (
              filteredFigures.map(f => (
                <FigureCard key={f.id} figure={f} />
              ))
            )}
          </div>
        )}
      </main>
    </div>
  )
}

// ── Routine Card ────────────────────────────────────────────
function RoutineCard({ routine }: { routine: Routine }) {
  const date = new Date(routine.updated_at).toLocaleDateString('sk-SK', {
    day: 'numeric', month: 'short', year: 'numeric',
  })

  return (
    <div className="bg-[#1a1a1c] border border-[#2a2a2e] rounded-xl p-4 hover:border-[#c9a96e]/30 transition-all group">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <h3 className="font-semibold text-white truncate group-hover:text-[#c9a96e] transition-colors">
            {routine.name}
          </h3>
          <p className="text-[#888] text-sm mt-0.5">
            {routine.dance_name}
            {routine.dance_category ? ` · ${routine.dance_category}` : ''}
          </p>
        </div>
        <span className="shrink-0 text-xs text-[#555] mt-0.5">{date}</span>
      </div>
      {routine.last_modified_by && (
        <p className="text-xs text-[#555] mt-2">
          Upravil: {routine.last_modified_by}
        </p>
      )}
    </div>
  )
}

// ── Figure Card ─────────────────────────────────────────────
function FigureCard({ figure }: { figure: Figure }) {
  return (
    <div className="bg-[#1a1a1c] border border-[#2a2a2e] rounded-xl p-4 hover:border-[#c9a96e]/30 transition-all">
      <div className="flex items-start justify-between gap-2 mb-2">
        <h3 className="font-semibold text-white text-sm leading-tight">{figure.name}</h3>
        {figure.is_custom && (
          <span className="shrink-0 text-[10px] px-1.5 py-0.5 bg-[#c9a96e]/15 text-[#c9a96e] rounded-md border border-[#c9a96e]/20">
            vlastná
          </span>
        )}
      </div>
      <p className="text-[#888] text-xs">{figure.dance_name} · {figure.rhythm}</p>
      {figure.technique_notes && (
        <p className="text-[#666] text-xs mt-2 line-clamp-2">{figure.technique_notes}</p>
      )}
    </div>
  )
}

function EmptyState({ message }: { message: string }) {
  return (
    <div className="text-center py-16 text-[#555]">
      <div className="text-4xl mb-3 opacity-30">🗂</div>
      <p className="text-sm">{message}</p>
    </div>
  )
}
