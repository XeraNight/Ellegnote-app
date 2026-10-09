'use client'

import React, { useState, useEffect } from 'react'
import Link from 'next/link'
import Image from 'next/image'

export default function LandingNavbar() {
  const [scrolled, setScrolled] = useState(false)
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 20)
    }
    window.addEventListener('scroll', handleScroll)
    return () => window.removeEventListener('scroll', handleScroll)
  }, [])

  return (
    <nav
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
        scrolled
          ? 'bg-[#140206]/95 backdrop-blur-xl border-b border-[#FFE088]/20 shadow-[0_10px_30px_rgba(0,0,0,0.8)] py-3.5'
          : 'bg-transparent py-5'
      }`}
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex items-center justify-between">
        {/* Brand Logo */}
        <Link href="/" className="flex items-center gap-3 group">
          <div className="relative w-9 h-9 sm:w-10 sm:h-10 transition-transform duration-300 group-hover:scale-105">
            <Image
              src="/logo_mark.svg"
              alt="Encore Sculptural Ribbon Mark"
              fill
              className="object-contain drop-shadow-[0_0_15px_rgba(212,175,55,0.45)]"
              priority
            />
          </div>
          <div className="flex flex-col">
            <span className="text-xl sm:text-2xl font-serif font-black tracking-wider bg-gradient-to-r from-[#FFF2CC] via-[#FFE088] to-[#D4AF37] bg-clip-text text-transparent">
              ENCORE
            </span>
            <span className="text-[9px] font-sans font-extrabold uppercase tracking-[0.25em] text-[#D4AF37]/70 -mt-1">
              Dance Studio
            </span>
          </div>
        </Link>

        {/* Desktop Navigation Links */}
        <div className="hidden md:flex items-center gap-8 text-xs font-semibold uppercase tracking-wider text-zinc-300">
          <a href="#canvas" className="hover:text-[#FFE088] transition-colors">
            2D Parket
          </a>
          <a href="#workflow" className="hover:text-[#FFE088] transition-colors">
            Tréning v sále
          </a>
          <a href="#duel" className="hover:text-[#FFE088] transition-colors">
            Video Duel
          </a>
          <a href="#pricing" className="hover:text-[#FFE088] transition-colors">
            Cenník
          </a>
          <Link href="/support" className="hover:text-[#FFE088] transition-colors">
            Podpora
          </Link>
        </div>

        {/* CTA Buttons */}
        <div className="hidden sm:flex items-center gap-3">
          <Link
            href="/download/ios"
            className="px-5 py-2.5 rounded-full text-xs font-bold tracking-wide text-black bg-gradient-to-r from-[#FFF2CC] via-[#FFE088] to-[#D4AF37] hover:brightness-110 shadow-[0_0_20px_rgba(212,175,55,0.35)] active:scale-95 transition-all flex items-center gap-2"
          >
            <svg className="w-4 h-4 fill-current" viewBox="0 0 24 24">
              <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.37c.61-.75 1.04-1.8 1.01-2.87-.96.04-2.09.64-2.74 1.4-.57.65-1.06 1.73-.93 2.76 1.07.08 2.06-.54 2.66-1.29z" />
            </svg>
            <span>Stiahnuť aplikáciu</span>
          </Link>
        </div>

        {/* Mobile Hamburger Toggle */}
        <button
          onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          className="md:hidden p-2 rounded-lg text-zinc-400 hover:text-white hover:bg-white/5 transition"
          aria-label="Toggle navigation menu"
        >
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            {mobileMenuOpen ? (
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12" />
            ) : (
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 6h16M4 12h16M4 18h16" />
            )}
          </svg>
        </button>
      </div>

      {/* Mobile Dropdown Menu */}
      {mobileMenuOpen && (
        <div className="md:hidden bg-[#121216]/95 border-b border-[#FFE088]/20 px-4 pt-4 pb-6 space-y-4 backdrop-blur-2xl animate-fadeIn">
          <div className="flex flex-col gap-3 text-sm font-semibold text-zinc-200">
            <a
              href="#features"
              onClick={() => setMobileMenuOpen(false)}
              className="py-2 border-b border-zinc-800/80 hover:text-[#FFE088]"
            >
              Funkcie
            </a>
            <a
              href="#canvas"
              onClick={() => setMobileMenuOpen(false)}
              className="py-2 border-b border-zinc-800/80 hover:text-[#FFE088]"
            >
              2D Parket
            </a>
            <a
              href="#core-loop"
              onClick={() => setMobileMenuOpen(false)}
              className="py-2 border-b border-zinc-800/80 hover:text-[#FFE088]"
            >
              Prečo Encore
            </a>
            <a
              href="#pricing"
              onClick={() => setMobileMenuOpen(false)}
              className="py-2 border-b border-zinc-800/80 hover:text-[#FFE088]"
            >
              Cenník
            </a>
            <Link
              href="/support"
              onClick={() => setMobileMenuOpen(false)}
              className="py-2 border-b border-zinc-800/80 hover:text-[#FFE088]"
            >
              Podpora & Kontakt
            </Link>
          </div>

          <div className="pt-2 flex flex-col gap-2">
            <Link
              href="/download/ios"
              onClick={() => setMobileMenuOpen(false)}
              className="w-full py-3 rounded-xl text-center font-bold text-xs text-black bg-gradient-to-r from-[#FFF2CC] via-[#FFE088] to-[#D4AF37]"
            >
              Stiahnuť pre iPhone
            </Link>
            <Link
              href="/download/android"
              onClick={() => setMobileMenuOpen(false)}
              className="w-full py-2.5 rounded-xl text-center font-semibold text-xs text-zinc-300 bg-white/5 border border-zinc-800"
            >
              Objaviť pre Android
            </Link>
          </div>
        </div>
      )}
    </nav>
  )
}
