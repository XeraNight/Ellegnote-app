import React from 'react'
import Link from 'next/link'
import Image from 'next/image'

export default function LandingFooter() {
  return (
    <footer className="border-t border-[#FFE088]/20 bg-[#050505] text-zinc-400 py-16 text-xs relative z-10 font-sans">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-12">
        
        {/* Top Footer Row */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-8 border-b border-zinc-900 pb-10">
          <div className="space-y-2">
            <div className="flex items-center gap-3">
              <div className="relative w-8 h-8">
                <Image
                  src="/logo_mark.svg"
                  alt="Encore Logo"
                  fill
                  className="object-contain"
                />
              </div>
              <span className="text-xl font-serif font-black tracking-wider bg-gradient-to-r from-[#FFF2CC] via-[#FFE088] to-[#D4AF37] bg-clip-text text-transparent">
                ENCORE
              </span>
            </div>
            <p className="text-xs text-zinc-400 max-w-sm">
              Prémiový tréningový a choreografický asistent pre súťažných tanečníkov spoločenských tancov, páry a trénerov.
            </p>
          </div>

          {/* Quick Legal Links */}
          <div className="flex flex-wrap items-center gap-6 text-xs font-semibold">
            <Link href="/privacy" className="hover:text-[#FFE088] transition">
              Zásady ochrany súkromia
            </Link>
            <Link href="/terms" className="hover:text-[#FFE088] transition">
              Podmienky & EULA
            </Link>
            <Link href="/delete-account" className="hover:text-red-400 transition">
              Zmazanie účtu
            </Link>
            <Link href="/support" className="hover:text-[#FFE088] transition">
              Podpora & Kontakt
            </Link>
            <Link href="/login" className="text-zinc-500 hover:text-white transition">
              Web Štúdio →
            </Link>
          </div>
        </div>

        {/* Middle Disclaimer Row */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 text-[11px] text-zinc-400 leading-relaxed border-b border-zinc-900 pb-8">
          <div>
            <span className="font-bold text-zinc-400 block mb-1 uppercase tracking-wider text-[10px]">
              Zdravotné a tréningové vyhlásenie:
            </span>
            <p>
              Aplikácia Encore je asistenčný vzdelávací nástroj. Orientačné biomechanické analýzy nenahrádzajú certifikovaného trénera, fyzioterapeuta ani lekára. Cvičenie a fyzický tréning vykonávate na vlastnú zodpovednosť.
            </p>
          </div>

          <div>
            <span className="font-bold text-zinc-400 block mb-1 uppercase tracking-wider text-[10px]">
              SZTŠ & Súťažné dáta (ksis.eu):
            </span>
            <p>
              Výpočty postupových bodov a zobrazené finálové výsledky importované zo systému ksis.eu majú informatívny charakter. Jediným oficiálnym a záväzným zdrojom výsledkov zostáva Slovenský zväz tanečného športu (SZTŠ).
            </p>
          </div>
        </div>

        {/* Bottom Copyright */}
        <div className="flex flex-col sm:flex-row justify-between items-center gap-4 text-[11px] text-zinc-400">
          <p>© {new Date().getFullYear()} Encore / Ellegnote. Všetky práva vyhradené.</p>
          <p className="flex items-center gap-2">
            <span>Navrhnuté s noblesou pre tanečnú komunitu</span>
            <span className="text-[#D4AF37]">✦</span>
            <span>Slovensko</span>
          </p>
        </div>

      </div>
    </footer>
  )
}
