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

      {/* ── 4. Discord-Inspired Floating Golden Stage Stars (Twinkling Sparkles) ── */}
      {mounted && (
        <div className="absolute inset-0 overflow-hidden pointer-events-none">
          {/* Top-left star */}
          <div
            className="absolute animate-star-twinkle transition-transform duration-700 ease-out"
            style={{
              top: '18%',
              left: '12%',
              transform: `translate(${(mousePos.x - 50) * -0.2}px, ${(mousePos.y - 25) * -0.2}px)`,
              animationDelay: '0s',
            }}
          >
            <svg width="22" height="22" viewBox="0 0 24 24" fill="#FFE088" className="drop-shadow-[0_0_8px_rgba(255,224,136,0.8)]">
              <path d="M 12 0 L 14 9 L 24 12 L 14 15 L 12 24 L 10 15 L 0 12 L 10 9 Z" />
            </svg>
          </div>

          {/* Top-right star */}
          <div
            className="absolute animate-star-twinkle transition-transform duration-700 ease-out"
            style={{
              top: '22%',
              right: '14%',
              transform: `translate(${(mousePos.x - 50) * 0.25}px, ${(mousePos.y - 25) * -0.15}px)`,
              animationDelay: '1.4s',
            }}
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="#D4AF37" className="drop-shadow-[0_0_8px_rgba(212,175,55,0.8)]">
              <path d="M 12 0 L 14 9 L 24 12 L 14 15 L 12 24 L 10 15 L 0 12 L 10 9 Z" />
            </svg>
          </div>

          {/* Mid-left star (near phone) */}
          <div
            className="absolute animate-star-twinkle transition-transform duration-700 ease-out"
            style={{
              top: '46%',
              left: '18%',
              transform: `translate(${(mousePos.x - 50) * -0.15}px, ${(mousePos.y - 25) * 0.2}px)`,
              animationDelay: '2.2s',
            }}
          >
            <svg width="15" height="15" viewBox="0 0 24 24" fill="#FFE088" className="drop-shadow-[0_0_6px_rgba(255,224,136,0.6)]">
              <path d="M 12 0 L 14 9 L 24 12 L 14 15 L 12 24 L 10 15 L 0 12 L 10 9 Z" />
            </svg>
          </div>

          {/* Mid-right star (near phone/mascot) */}
          <div
            className="absolute animate-star-twinkle transition-transform duration-700 ease-out"
            style={{
              top: '52%',
              right: '16%',
              transform: `translate(${(mousePos.x - 50) * 0.2}px, ${(mousePos.y - 25) * 0.25}px)`,
              animationDelay: '0.8s',
            }}
          >
            <svg width="24" height="24" viewBox="0 0 24 24" fill="#FFF2CC" className="drop-shadow-[0_0_10px_rgba(255,242,204,0.9)]">
              <path d="M 12 0 L 14 9 L 24 12 L 14 15 L 12 24 L 10 15 L 0 12 L 10 9 Z" />
            </svg>
          </div>
        </div>
      )}
    </div>
  )
}
