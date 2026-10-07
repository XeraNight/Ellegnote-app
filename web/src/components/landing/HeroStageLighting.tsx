'use client'

import React, { useEffect, useState, useRef } from 'react'

export default function HeroStageLighting() {
  const [mounted, setMounted] = useState(false)
  const [mousePos, setMousePos] = useState({ x: 50, y: 25 })
  const targetPos = useRef({ x: 50, y: 25 })
  const animFrame = useRef<number | null>(null)

  useEffect(() => {
    setMounted(true)

    const handleMouseMove = (e: MouseEvent) => {
      // Calculate cursor position as percentage of window
      const x = (e.clientX / window.innerWidth) * 100
      const y = (e.clientY / window.innerHeight) * 100
      targetPos.current = { x, y }
    }

    // Smooth lerp for buttery 60 FPS spotlight movement
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
      window.removeEventListener('mousemove', handleMouseMove)
      if (animFrame.current) cancelAnimationFrame(animFrame.current)
    }
  }, [])

  return (
    <div className="fixed inset-0 pointer-events-none z-0 overflow-hidden">
      {/* ── 1. Base Carmine Velvet Ambient (Ballroom Theatre Velvet Backdrop) ── */}
      <div
        className="absolute top-0 left-1/2 -translate-x-1/2 w-full max-w-[1500px] h-[750px] transition-opacity duration-1000"
        style={{
          background:
            'radial-gradient(ellipse 85% 65% at 50% -10%, rgba(102, 3, 18, 0.24) 0%, rgba(41, 5, 10, 0.12) 45%, transparent 75%)',
        }}
      />

      {/* ── 2. Interactive Follow-Spotlight (Tracks cursor smoothly like Stripe/Apple stage) ── */}
      <div
        className="absolute w-[900px] h-[600px] -translate-x-1/2 -translate-y-1/2 transition-opacity duration-500 will-change-transform"
        style={{
          left: mounted ? `${mousePos.x}%` : '50%',
          top: mounted ? `${Math.min(mousePos.y, 65)}%` : '25%',
          background:
            'radial-gradient(circle 380px at center, rgba(255, 224, 136, 0.09) 0%, rgba(212, 175, 55, 0.03) 50%, transparent 80%)',
          filter: 'blur(30px)',
        }}
      />

      {/* ── 3. Fixed Center Stage Spotlight Beam ── */}
      <div
        className="absolute top-0 left-1/2 -translate-x-1/2 w-[1200px] h-[550px]"
        style={{
          background:
            'radial-gradient(ellipse 70% 50% at 50% 0%, rgba(212, 175, 55, 0.08) 0%, transparent 70%)',
        }}
      />
    </div>
  )
}
