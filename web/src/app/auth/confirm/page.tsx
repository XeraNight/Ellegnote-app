'use client'

import React, { useEffect, useState, Suspense } from 'react'
import Image from 'next/image'
import Link from 'next/link'
import { useSearchParams } from 'next/navigation'

function AuthConfirmContent() {
  const searchParams = useSearchParams()
  const [isIOS, setIsIOS] = useState(false)

  const code = searchParams.get('code')
  const type = searchParams.get('type') || 'login'

  const appSchemeUrl = `encore://auth-callback?type=${encodeURIComponent(type)}${code ? `&code=${encodeURIComponent(code)}` : ''}`
  const appStoreUrl = '/download/ios'

  useEffect(() => {
    const ua = navigator.userAgent || ''
    const isApple = /iPhone|iPad|iPod/i.test(ua)
    setIsIOS(isApple)

    if (isApple) {
      // Pokus o automatické otvorenie natívnej aplikácie Encore
      const timer = setTimeout(() => {
        window.location.href = appSchemeUrl
      }, 500)

      return () => clearTimeout(timer)
    }
  }, [appSchemeUrl])

  return (
    <div className="relative z-10 w-full max-w-md flex flex-col items-center text-center gap-6 p-8 rounded-3xl surface-obsidian shadow-2xl backdrop-blur-xl">
      {/* App Logo */}
      <div className="relative w-20 h-20 mb-2">
        <Image
          src="/logo_full.svg"
          alt="Encore Ribbon Logo"
          fill
          className="object-contain drop-shadow-[0_0_25px_rgba(212,175,55,0.4)]"
          priority
        />
      </div>

      {/* Title & Description */}
      <div className="space-y-2">
        <span className="inline-block text-[11px] font-bold tracking-[0.2em] text-[#FFE088] uppercase bg-[#D4AF37]/10 px-3 py-1 rounded-full border border-[#D4AF37]/25">
          Autentifikácia Encore
        </span>
        <h1 className="text-2xl sm:text-3xl font-serif font-black tracking-tight text-white">
          {type === 'recovery' ? 'Obnova hesla' : 'Prihlásenie overené'}
        </h1>
        <p className="text-xs sm:text-sm text-zinc-400">
          {isIOS 
            ? 'Váš účet bol úspešne overený. Otvárame mobilnú aplikáciu Encore...'
            : 'Váš účet je pripravený. Otvorte aplikáciu Encore na svojom iPhone pre pokračovanie v tréningu.'}
        </p>
      </div>

      {/* Action Buttons */}
      <div className="w-full flex flex-col gap-3 mt-4">
        <a
          href={appSchemeUrl}
          className="w-full py-4 px-6 rounded-2xl bg-gradient-to-r from-[#F7E59D] via-[#D4AF37] to-[#AA771C] text-black font-bold text-sm tracking-wide shadow-lg shadow-[#D4AF37]/20 hover:brightness-105 active:scale-[0.99] transition-all flex items-center justify-center gap-2 cursor-pointer"
        >
          <svg className="w-5 h-5 fill-current" viewBox="0 0 24 24">
            <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 14.5v-9l6 4.5-6 4.5z" />
          </svg>
          <span>Otvoriť aplikáciu Encore</span>
        </a>

        <Link
          href={appStoreUrl}
          className="w-full py-3.5 px-4 rounded-xl bg-white/[0.04] hover:bg-white/[0.08] border border-[#D4AF37]/30 text-xs font-semibold text-zinc-300 hover:text-white transition flex items-center justify-center gap-2"
        >
          <svg className="w-4 h-4 fill-current text-[#D4AF37]" viewBox="0 0 24 24">
            <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.37c.61-.75 1.04-1.8 1.01-2.87-.96.04-2.09.64-2.74 1.4-.57.65-1.06 1.73-.93 2.76 1.07.08 2.06-.54 2.66-1.29z" />
          </svg>
          <span>Ešte nemáš aplikáciu? Stiahnuť z App Store</span>
        </Link>
      </div>

      {/* Navigation link */}
      <div className="pt-2 border-t border-zinc-800/80 w-full flex justify-between text-[11px] text-zinc-500">
        <Link href="/" className="hover:text-[#D4AF37] transition">
          ← Domov
        </Link>
        <Link href="/support" className="hover:text-[#D4AF37] transition">
          Potrebujete pomoc?
        </Link>
      </div>
    </div>
  )
}

export default function AuthConfirmPage() {
  return (
    <main className="min-h-screen bg-[#050505] text-[#F5F5F5] flex flex-col items-center justify-center p-4 selection:bg-[#D4AF37] selection:text-black font-sans relative overflow-hidden">
      {/* Ambient theatrical stage lighting */}
      <div className="fixed top-0 left-1/2 -translate-x-1/2 w-[800px] h-[400px] bg-[radial-gradient(ellipse_75%_50%_at_50%_0%,rgba(212,175,55,0.08),transparent_70%)] pointer-events-none" />

      <Suspense fallback={
        <div className="relative z-10 w-full max-w-md flex flex-col items-center justify-center p-8 rounded-3xl surface-obsidian text-center">
          <div className="w-8 h-8 border-2 border-[#D4AF37] border-t-transparent rounded-full animate-spin mb-4" />
          <p className="text-zinc-400 text-sm">Overujem prihlásenie...</p>
        </div>
      }>
        <AuthConfirmContent />
      </Suspense>
    </main>
  )
}
