import React from 'react'
import Link from 'next/link'

export default function PricingSection() {
  return (
    <section id="pricing" className="py-24 relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      {/* Section Header */}
      <div className="text-center max-w-3xl mx-auto mb-16 space-y-3">
        <span className="text-xs font-mono font-bold uppercase tracking-[0.25em] text-[#FFE088] bg-[#D4AF37]/10 px-4 py-1.5 rounded-full border border-[#D4AF37]/25">
          Transparentné Podmienky
        </span>
        <h2 className="text-3xl sm:text-5xl font-serif font-black tracking-tight text-white">
          Investícia do Vášho tanečného rastu
        </h2>
        <p className="text-sm sm:text-base text-zinc-400">
          Zvoľte si úroveň, ktorá najlepšie zodpovedá Vašim tréningovým cieľom. Všetky nákupy sú bezpečne spravované cez Apple In-App Purchase.
        </p>
      </div>

      {/* Pricing Cards Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 items-stretch">
        
        {/* Tier 1: Free */}
        <div className="rounded-3xl p-8 bg-[#0d0c12]/90 border border-zinc-800 flex flex-col justify-between shadow-xl">
          <div className="space-y-4">
            <span className="text-[11px] font-mono font-bold uppercase tracking-wider text-zinc-400">
              Pre každého tanečníka
            </span>
            <h3 className="text-2xl font-serif font-bold text-white">Encore Free</h3>
            <div className="flex items-baseline gap-1">
              <span className="text-4xl font-mono font-black text-white">0 €</span>
              <span className="text-xs text-zinc-400 font-sans">/ navždy</span>
            </div>
            <p className="text-xs text-zinc-400 leading-relaxed">
              Základný asistent pre evidenciu zostáv a presné počítanie rytmu na každom tréningu.
            </p>

            <ul className="pt-4 border-t border-zinc-800/80 space-y-3 text-xs text-zinc-300">
              <li className="flex items-center gap-2">
                <span className="text-emerald-400">✓</span> 2D Choreografický Parket pre zostavy
              </li>
              <li className="flex items-center gap-2">
                <span className="text-emerald-400">✓</span> Syntetický PCM Metronóm (všetky tance)
              </li>
              <li className="flex items-center gap-2">
                <span className="text-emerald-400">✓</span> 100% offline prístup k uloženým dátam
              </li>
              <li className="flex items-center gap-2">
                <span className="text-emerald-400">✓</span> Základná WDSF knižnica figúr
              </li>
            </ul>
          </div>

          <div className="pt-8">
            <Link
              href="/download/ios"
              className="w-full py-3.5 px-4 rounded-xl text-center font-bold text-xs text-white bg-white/5 hover:bg-white/10 border border-zinc-700 transition block"
            >
              Začať zadarmo
            </Link>
          </div>
        </div>

        {/* Tier 2: Plus (Featured) */}
        <div className="rounded-3xl p-8 bg-gradient-to-b from-[#1f1508] via-[#140e05] to-[#0a0703] border-2 border-[#D4AF37] relative flex flex-col justify-between shadow-[0_0_40px_rgba(212,175,55,0.25)]">
          <div className="absolute -top-3.5 left-1/2 -translate-x-1/2 px-4 py-1 rounded-full bg-gradient-to-r from-[#FFE088] to-[#D4AF37] text-black font-extrabold text-[10px] uppercase tracking-widest shadow-md">
            Najobľúbenejšie pre páry
          </div>

          <div className="space-y-4 pt-2">
            <span className="text-[11px] font-mono font-bold uppercase tracking-wider text-[#D4AF37]">
              Súťažný pár
            </span>
            <h3 className="text-2xl font-serif font-bold text-white">Encore Plus</h3>
            <div className="flex items-baseline gap-1">
              <span className="text-4xl font-mono font-black text-[#FFE088]">4,99 €</span>
              <span className="text-xs text-zinc-400 font-sans">/ mesiac</span>
            </div>
            <p className="text-xs text-zinc-300 leading-relaxed">
              Kompletná video analýza a súťažný radar pre tanečné páry pripravujúce sa na finále.
            </p>

            <ul className="pt-4 border-t border-[#D4AF37]/20 space-y-3 text-xs text-zinc-200">
              <li className="flex items-center gap-2">
                <span className="text-[#FFE088] font-bold">✓</span> Všetko z Encore Free
              </li>
              <li className="flex items-center gap-2">
                <span className="text-[#FFE088] font-bold">✓</span> Neobmedzený Video Vault k figúram
              </li>
              <li className="flex items-center gap-2">
                <span className="text-[#FFE088] font-bold">✓</span> Side-by-Side Dual Video Player (Slo-Mo)
              </li>
              <li className="flex items-center gap-2">
                <span className="text-[#FFE088] font-bold">✓</span> Automatický import bodov SZTŠ z ksis.eu
              </li>
              <li className="flex items-center gap-2">
                <span className="text-[#FFE088] font-bold">✓</span> Realtime cloud synchronizácia s partnerom
              </li>
            </ul>
          </div>

          <div className="pt-8">
            <Link
              href="/download/ios"
              className="w-full py-4 px-4 rounded-xl text-center font-bold text-xs text-black bg-gradient-to-r from-[#FFF2CC] via-[#FFE088] to-[#D4AF37] hover:brightness-110 shadow-lg shadow-[#D4AF37]/30 transition block"
            >
              Odomknúť Encore Plus
            </Link>
          </div>
        </div>

        {/* Tier 3: Studio (User's specific positioning) */}
        <div className="rounded-3xl p-8 bg-[#0d0c12]/90 border border-zinc-800 flex flex-col justify-between shadow-xl relative overflow-hidden">
          <div className="space-y-4">
            <span className="text-[11px] font-mono font-bold uppercase tracking-wider text-[#E11D48]">
              Tréneri & Ambiciózni Tanečníci
            </span>
            <h3 className="text-2xl font-serif font-bold text-white">Encore Studio</h3>
            <div className="flex items-baseline gap-1">
              <span className="text-4xl font-mono font-black text-white">14,99 €</span>
              <span className="text-xs text-zinc-400 font-sans">/ mesiac</span>
            </div>
            
            {/* Highlighted value proposition */}
            <div className="p-3 rounded-xl bg-[#E11D48]/10 border border-[#E11D48]/30">
              <p className="text-xs font-semibold text-[#FFE088] leading-relaxed">
                „Pre trénerov a tanečníkov, ktorí chcú napredovať čo najrýchlejšie a najefektívnejšie.“
              </p>
            </div>

            <ul className="pt-4 border-t border-zinc-800/80 space-y-3 text-xs text-zinc-300">
              <li className="flex items-center gap-2">
                <span className="text-[#E11D48] font-bold">✓</span> Všetko z Encore Plus
              </li>
              <li className="flex items-center gap-2">
                <span className="text-[#E11D48] font-bold">✓</span> Roster a správa viacerých párov a zverencov
              </li>
              <li className="flex items-center gap-2">
                <span className="text-[#E11D48] font-bold">✓</span> Zdieľanie zostáv a seminárov z kempov
              </li>
              <li className="flex items-center gap-2">
                <span className="text-[#E11D48] font-bold">✓</span> VIP Posture Angle Lines analýza držania tela
              </li>
              <li className="flex items-center gap-2">
                <span className="text-[#E11D48] font-bold">✓</span> Digitálny klubový preukaz v Apple Wallet
              </li>
              <li className="flex items-center gap-2">
                <span className="text-[#E11D48] font-bold">✓</span> Prioritná technická podpora trénerského tímu
              </li>
            </ul>
          </div>

          <div className="pt-8">
            <Link
              href="/download/ios"
              className="w-full py-3.5 px-4 rounded-xl text-center font-bold text-xs text-white bg-white/5 hover:bg-white/10 border border-zinc-700 transition block"
            >
              Vyskúšať Encore Studio
            </Link>
          </div>
        </div>

      </div>

      {/* Subscription terms note for Apple Review compliance */}
      <div className="mt-8 text-center text-[11px] text-zinc-500 max-w-2xl mx-auto space-y-1">
        <p>
          Predplatné sa automaticky obnovuje, pokiaľ nie je zrušené aspoň 24 hodín pred koncom aktuálneho obdobia v systémových nastaveniach Apple ID.
        </p>
        <p>
          Podrobné informácie nájdete v našich{' '}
          <Link href="/terms" className="text-[#D4AF37] underline hover:opacity-80">
            Podmienkach používania (EULA)
          </Link>{' '}
          a{' '}
          <Link href="/privacy" className="text-[#D4AF37] underline hover:opacity-80">
            Zásadách ochrany osobných údajov
          </Link>.
        </p>
      </div>
    </section>
  )
}
