'use client'

import React, { useEffect, useState } from 'react'
import { useSearchParams, useParams } from 'next/navigation'
import Image from 'next/image'

export default function UserCardLandingPage() {
  const params = useParams()
  const searchParams = useSearchParams()

  const id = (params?.id as string) || ''
  const name = searchParams.get('name') || 'Jakub Kalina'
  const club = searchParams.get('club') || 'Individuálny'

  const [isIPhone, setIsIPhone] = useState(false)
  const [redirecting, setRedirecting] = useState(true)

  const appSchemeUrl = `encore://friend/add?id=${encodeURIComponent(id)}&name=${encodeURIComponent(name)}&club=${encodeURIComponent(club)}`
  const appStoreUrl = `https://apps.apple.com/search?term=Encore+Dance`

  useEffect(() => {
    const ua = navigator.userAgent || ''
    const isIOSDevice = /iPhone|iPad|iPod/i.test(ua)
    setIsIPhone(isIOSDevice)

    if (isIOSDevice) {
      // 1. Skús hneď otvoriť apku Encore, ak je nainštalovaná
      window.location.href = appSchemeUrl

      // 2. Ak apka nie je nainštalovaná (stránka zostala aktívna), presmeruj rovno do App Store
      const timeout = setTimeout(() => {
        window.location.href = appStoreUrl
      }, 600)

      return () => clearTimeout(timeout)
    } else {
      setRedirecting(false)
    }
  }, [appSchemeUrl, appStoreUrl])

  return (
    <main className="min-h-screen bg-[#070709] text-white flex flex-col items-center justify-center p-4 selection:bg-[#D4AF37] selection:text-black">
      {/* Ambient Ruby Lighting */}
      <div className="fixed inset-0 pointer-events-none overflow-hidden">
        <div className="absolute top-1/4 left-1/2 -translate-x-1/2 w-[480px] h-[340px] bg-[#9E081A] opacity-25 blur-[120px] rounded-full" />
      </div>

      <div className="relative z-10 w-full max-w-md flex flex-col items-center gap-6">
        {/* Top Status Header */}
        <div className="flex flex-col items-center text-center gap-1.5">
          <span className="text-[11px] font-black tracking-[0.2em] text-[#D4AF37] uppercase">
            Encore Dance Pass
          </span>
          <h1 className="text-2xl font-serif font-black tracking-tight">
            {name}
          </h1>
          {club && (
            <span className="text-xs text-stone-400 font-medium">
              Tanečný klub: {club}
            </span>
          )}
        </div>

        {/* Luxury Member Card Preview (Exact Match to User Reference Image) */}
        <div className="w-full aspect-[1.72] rounded-2xl p-6 relative overflow-hidden shadow-2xl border border-[#D4AF37]/40 flex flex-col justify-between"
             style={{
               background: 'linear-gradient(135deg, #9E081A 0%, #660312 45%, #2E000A 100%)',
               boxShadow: '0 20px 50px -10px rgba(158, 8, 26, 0.45), 0 0 30px rgba(212, 175, 55, 0.2)'
             }}>
          {/* Subtle sheen layer */}
          <div className="absolute inset-0 pointer-events-none bg-gradient-to-tr from-transparent via-white/10 to-transparent" />

          {/* Top Row: QR Code Container in Top Right */}
          <div className="flex justify-end items-start">
            <div className="bg-white p-1.5 rounded-lg shadow-md flex items-center justify-center">
              <div className="w-12 h-12 relative flex items-center justify-center">
                {/* SVG QR Code Simulation with Center Mark */}
                <svg viewBox="0 0 100 100" className="w-full h-full text-black fill-current">
                  <rect width="100" height="100" fill="white" />
                  <path d="M10,10 h30 v30 h-30 z M15,15 v20 h20 v-20 z M20,20 h10 v10 h-10 z" />
                  <path d="M60,10 h30 v30 h-30 z M65,15 v20 h20 v-20 z M70,20 h10 v10 h-10 z" />
                  <path d="M10,60 h30 v30 h-30 z M15,65 v20 h20 v-20 z M20,70 h10 v10 h-10 z" />
                  <circle cx="50" cy="50" r="12" fill="#9E081A" />
                  <rect x="45" y="45" width="10" height="10" fill="#D4AF37" />
                  <rect x="50" y="20" width="5" height="15" />
                  <rect x="75" y="55" width="15" height="5" />
                  <rect x="55" y="70" width="10" height="10" />
                  <rect x="75" y="75" width="10" height="10" />
                </svg>
              </div>
            </div>
          </div>

          {/* Center: Gold Monogram Logo */}
          <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
            <div className="relative w-16 h-16">
              <Image
                src="/encore_logo.png"
                alt="Encore Logo"
                fill
                className="object-contain filter drop-shadow-[0_4px_12px_rgba(0,0,0,0.6)] brightness-125"
              />
            </div>
          </div>

          {/* Bottom Row: Calligraphic cursive name in Bottom Right */}
          <div className="flex justify-end items-end z-10">
            <span
              className="text-[#E5C158] text-xl font-serif italic tracking-wide drop-shadow-[0_2px_4px_rgba(0,0,0,0.8)]"
              style={{ fontFamily: 'Snell Roundhand, Zapfino, cursive, serif' }}
            >
              {name}
            </span>
          </div>
        </div>

        {/* Redirect Notice & Instant Action Buttons */}
        <div className="w-full flex flex-col gap-3 mt-2">
          {redirecting && isIPhone && (
            <p className="text-center text-xs text-[#D4AF37] animate-pulse">
              Presmerovávam do Encore alebo App Store...
            </p>
          )}

          {/* Direct App Open Button */}
          <a
            href={appSchemeUrl}
            className="w-full py-4 rounded-xl font-black text-sm text-black flex items-center justify-center gap-2 shadow-lg transition active:scale-95"
            style={{
              background: 'linear-gradient(135deg, #FFE088 0%, #D4AF37 100%)',
              boxShadow: '0 4px 20px rgba(212, 175, 55, 0.4)'
            }}
          >
            <svg className="w-4 h-4 fill-current" viewBox="0 0 24 24">
              <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 14.5v-9l6 4.5-6 4.5z" />
            </svg>
            Otvoriť v aplikácii Encore
          </a>

          {/* Fallback to App Store Search */}
          <a
            href={appStoreUrl}
            className="w-full py-3.5 rounded-xl font-bold text-xs text-stone-200 bg-[#141419] border border-[#D4AF37]/30 hover:border-[#D4AF37] flex items-center justify-center gap-2 transition active:scale-95"
          >
            <svg className="w-4 h-4 fill-current text-[#D4AF37]" viewBox="0 0 24 24">
              <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.37c.61-.75 1.04-1.8 1.01-2.87-.96.04-2.09.64-2.74 1.4-.57.65-1.06 1.73-.93 2.76 1.07.08 2.06-.54 2.66-1.29z" />
            </svg>
            Vyhľadať Encore Dance v App Store
          </a>
        </div>

        {/* Footer info */}
        <p className="text-[11px] text-stone-500 text-center max-w-xs">
          Encore je aplikácia pre spoločenských a latinskoamerických tanečníkov. Zdieľaj svoje figúry, tréningy a video rozbory.
        </p>
      </div>
    </main>
  )
}
