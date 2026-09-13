'use client'

import React from 'react'

export default function EncoreStageBackdrop() {
  return (
    <div className="fixed inset-0 pointer-events-none z-0 overflow-hidden select-none">
      {/* Base deep velvet background */}
      <div className="absolute inset-0 bg-[#080204]" />

      {/* Stage spotlight backdrop image */}
      <div
        className="absolute inset-0 bg-cover bg-center bg-no-repeat opacity-40 mix-blend-screen"
        style={{ backgroundImage: "url('/encore_stage_bg.jpg')" }}
      />

      {/* Overhead stage spotlight cone */}
      <div
        className="absolute top-[-10%] left-1/2 -translate-x-1/2 w-[1200px] h-[750px] pointer-events-none"
        style={{
          background:
            'radial-gradient(ellipse at 50% 0%, rgba(212, 175, 55, 0.15) 0%, rgba(155, 20, 38, 0.08) 45%, transparent 75%)',
          filter: 'blur(40px)',
        }}
      />

      {/* Subtle floor warm reflection */}
      <div
        className="absolute bottom-0 left-1/2 -translate-x-1/2 w-full h-[450px] pointer-events-none"
        style={{
          background:
            'radial-gradient(ellipse at 50% 100%, rgba(120, 10, 20, 0.12) 0%, rgba(5, 5, 8, 0.6) 70%, transparent 100%)',
        }}
      />

      {/* Cinematic Edge Vignette */}
      <div
        className="absolute inset-0 pointer-events-none"
        style={{
          background:
            'radial-gradient(circle at center, transparent 40%, rgba(3, 1, 2, 0.65) 80%, rgba(2, 0, 1, 0.92) 100%)',
        }}
      />
    </div>
  )
}
