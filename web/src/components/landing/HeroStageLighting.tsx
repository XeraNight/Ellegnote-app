'use client'

import React, { useEffect, useState, useRef } from 'react'
import Image from 'next/image'

export default function HeroStageLighting() {
  const [mounted, setMounted] = useState(false)
  const [mousePos, setMousePos] = useState({ x: 50, y: 30 })
  const targetPos = useRef({ x: 50, y: 30 })
  const animFrame = useRef<number | null>(null)

  useEffect(() => {
    const timer = setTimeout(() => setMounted(true), 10)

    const handleMouseMove = (e: MouseEvent) => {
      const x = (e.clientX / window.innerWidth) * 100
      const y = (e.clientY / window.innerHeight) * 100
      targetPos.current = { x, y }
    }

    const animate = () => {
      setMousePos((prev) => ({
        x: prev.x + (targetPos.current.x - prev.x) * 0.05,
        y: prev.y + (targetPos.current.y - prev.y) * 0.05,
      }))
      animFrame.current = requestAnimationFrame(animate)
    }

    window.addEventListener('mousemove', handleMouseMove, { passive: true })
    animFrame.current = requestAnimationFrame(animate)

    return () => {
      clearTimeout(timer)
      window.removeEventListener('mousemove', handleMouseMove)
      if (animFrame.current) cancelAnimationFrame(animFrame.current)
    }
  }, [])

  return (
    <div className="fixed inset-0 pointer-events-none z-0 overflow-hidden" aria-hidden="true">
      {/* ── 1. Theatrical Red Velvet Stage Backdrop (encore_stage_bg.jpg) ── */}
      <div className="absolute inset-0 opacity-45 mix-blend-screen transition-opacity duration-1000">
        <Image
          src="/encore_stage_bg.jpg"
          alt=""
          fill
          priority
          sizes="100vw"
          className="object-cover object-top"
        />
      </div>

      {/* ── 2. Rich Carmine Velvet Color Scrim (WCAG Contrast & Theater Warmth) ── */}
      <div
        className="absolute inset-0"
        style={{
          background:
            'radial-gradient(ellipse 95% 75% at 50% 15%, rgba(102, 3, 18, 0.45) 0%, rgba(35, 4, 10, 0.70) 50%, rgba(18, 2, 6, 0.95) 90%, #140206 100%)',
        }}
      />

      {/* ── 3. Overhead Fixed Golden Stage Beam (Direct Spotlight on Hero Device) ── */}
      <div
        className="absolute top-0 left-1/2 -translate-x-1/2 w-[1400px] h-[750px]"
        style={{
          background:
            'radial-gradient(ellipse 65% 50% at 50% 0%, rgba(255, 224, 136, 0.14) 0%, rgba(212, 175, 55, 0.06) 45%, transparent 75%)',
        }}
      />

      {/* ── 4. Interactive Follow-Spotlight (Smooth 60 FPS Cursor Tracker) ── */}
      <div
        className="absolute w-[900px] h-[650px] -translate-x-1/2 -translate-y-1/2 transition-opacity duration-700 will-change-transform"
        style={{
          left: mounted ? `${mousePos.x}%` : '50%',
          top: mounted ? `${Math.min(mousePos.y, 70)}%` : '30%',
          background:
            'radial-gradient(circle 380px at center, rgba(255, 224, 136, 0.08) 0%, rgba(212, 175, 55, 0.03) 50%, transparent 80%)',
          filter: 'blur(35px)',
        }}
      />

      {/* ── 5. Bottom Stage Floor Linear Falloff (Seamless transition into page body) ── */}
      <div className="absolute inset-x-0 bottom-0 h-96 bg-gradient-to-b from-transparent via-[#140206]/70 to-[#140206]" />
    </div>
  )
}
