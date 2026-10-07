'use client'

import React, { useState, useEffect } from 'react'
import Link from 'next/link'

export default function FloatingDownloadBar() {
  const [visible, setVisible] = useState(false)

  useEffect(() => {
    const handleScroll = () => {
      // Appear when user scrolls past the hero section (~450px)
      setVisible(window.scrollY > 450)
    }
    window.addEventListener('scroll', handleScroll, { passive: true })
    return () => window.removeEventListener('scroll', handleScroll)
  }, [])

  if (!visible) return null

  return (
    <div className="fixed bottom-5 left-1/2 -translate-x-1/2 z-50 w-full max-w-sm px-4 animate-scale-up pointer-events-auto md:hidden">
      <div className="p-2 rounded-full bg-[#121216]/95 border border-[#FFE088]/30 shadow-[0_15px_40px_rgba(0,0,0,0.9),0_0_25px_rgba(212,175,55,0.20)] backdrop-blur-2xl flex items-center justify-between gap-3">
        
        {/* Left: Mini App Icon & Tag */}
        <div className="flex items-center gap-2.5 pl-2.5">
          <div className="w-8 h-8 rounded-full bg-gradient-to-br from-[#FFE088] to-[#D4AF37] p-0.5 shadow-md flex items-center justify-center shrink-0">
            <span className="text-[10px] font-black text-black">E</span>
          </div>
          <div className="text-left hidden xs:block">
            <span className="text-xs font-bold text-white block leading-tight">Encore</span>
            <span className="text-[9px] text-[#FFE088] font-mono leading-none">WDSF & SZTŠ Ready</span>
          </div>
        </div>

        {/* Right: Direct CTA Button */}
        <Link
          href="/download/ios"
          className="px-5 py-2 rounded-full bg-gradient-to-r from-[#FFF2CC] via-[#FFE088] to-[#D4AF37] text-black font-bold text-xs flex items-center gap-1.5 shadow-md hover:brightness-110 active:scale-95 transition-all shrink-0"
        >
          <svg className="w-3.5 h-3.5 fill-current" viewBox="0 0 24 24">
            <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.37c.61-.75 1.04-1.8 1.01-2.87-.96.04-2.09.64-2.74 1.4-.57.65-1.06 1.73-.93 2.76 1.07.08 2.06-.54 2.66-1.29z" />
          </svg>
          <span>Stiahnuť</span>
        </Link>

      </div>
    </div>
  )
}
