'use client'

import React from 'react'
import { Home, Compass, Video, BookOpen, User } from 'lucide-react'

export type TabId = 'home' | 'canvas' | 'studio' | 'library' | 'profile'

interface LiquidGlassDockProps {
  activeTab: TabId
  onTabChange: (tab: TabId) => void
}

const TABS: { id: TabId; label: string; icon: React.ComponentType<{ className?: string }> }[] = [
  { id: 'home', label: 'Domov', icon: Home },
  { id: 'canvas', label: 'Canvas', icon: Compass },
  { id: 'studio', label: 'Štúdio', icon: Video },
  { id: 'library', label: 'Knižnica', icon: BookOpen },
  { id: 'profile', label: 'Profil', icon: User },
]

export default function LiquidGlassDock({ activeTab, onTabChange }: LiquidGlassDockProps) {
  const activeIndex = TABS.findIndex(t => t.id === activeTab)

  return (
    <nav aria-label="Spodná navigácia aplikácie" className="fixed bottom-6 left-1/2 -translate-x-1/2 z-40 select-none">
      {/* Dock Outer Glow */}
      <div className="absolute inset-0 rounded-full bg-gradient-to-r from-[#D4AF37]/20 via-[#E11D48]/15 to-[#D4AF37]/20 blur-xl opacity-75 pointer-events-none" />

      {/* Dock Glass Pill */}
      <div className="relative px-2.5 py-2 rounded-full bg-[#0d090d]/80 backdrop-blur-2xl border border-white/[0.12] shadow-[0_20px_50px_rgba(0,0,0,0.8),inset_0_1px_1px_rgba(255,255,255,0.25)] flex items-center gap-1">
        {/* Sliding Liquid Glass Lens */}
        <div
          className="absolute top-2 bottom-2 rounded-full bg-gradient-to-b from-white/[0.16] to-white/[0.04] border border-[#D4AF37]/35 shadow-[0_4px_20px_rgba(212,175,55,0.25),inset_0_1px_2px_rgba(255,255,255,0.4)] transition-all duration-300 ease-[cubic-bezier(0.16,1,0.3,1)] pointer-events-none"
          style={{
            width: '68px',
            left: `calc(10px + ${activeIndex} * 72px)`,
          }}
        />

        {/* Tab Buttons */}
        {TABS.map(tab => {
          const isActive = activeTab === tab.id
          const Icon = tab.icon

          return (
            <button
              key={tab.id}
              onClick={() => onTabChange(tab.id)}
              className="relative w-[68px] h-[52px] rounded-full flex flex-col items-center justify-center gap-1 transition-transform duration-200 hover:scale-105 active:scale-95 cursor-pointer z-10 group"
            >
              <Icon
                className={`w-5 h-5 transition-colors duration-200 ${
                  isActive
                    ? 'text-[#FFE088] drop-shadow-[0_0_8px_rgba(255,224,136,0.6)]'
                    : 'text-white/45 group-hover:text-white/80'
                }`}
              />
              <span
                className={`text-[10px] font-bold tracking-tight transition-colors duration-200 ${
                  isActive ? 'text-white font-black' : 'text-white/40 group-hover:text-white/70'
                }`}
              >
                {tab.label}
              </span>
            </button>
          )
        })}
      </div>
    </nav>
  )
}
