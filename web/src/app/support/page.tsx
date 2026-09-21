import Link from 'next/link'
import type { Metadata } from 'next'
import { ContactForm } from '@/components/ContactForm'

export const metadata: Metadata = {
  title: 'Zákaznícka podpora & Pomoc | Encore',
  description: 'Technická podpora a často kladené otázky pre aplikáciu Encore Dance Studio.',
}

export default function SupportPage() {
  return (
    <main className="min-h-screen bg-[#060608] text-white px-6 py-16 sm:py-24 font-sans selection:bg-[#D4AF37]/30">
      {/* Ambient background glow */}
      <div className="fixed top-1/4 left-1/2 -translate-x-1/2 w-[600px] h-[600px] bg-[#D4AF37]/10 rounded-full blur-[180px] pointer-events-none" />

      <div className="max-w-3xl mx-auto relative z-10">
        {/* Header navigation */}
        <div className="flex items-center justify-between mb-12 border-b border-[#D4AF37]/15 pb-6">
          <Link
            href="/login"
            className="flex items-center gap-3 text-gold-400 font-serif tracking-wider hover:opacity-80 transition"
          >
            <span className="text-xl font-bold bg-gradient-to-r from-[#F5D77F] via-[#D4AF37] to-[#AA7C11] bg-clip-text text-transparent">
              ENCORE
            </span>
            <span className="text-xs uppercase tracking-widest text-zinc-400 border-l border-zinc-800 pl-3">
              Dance Studio
            </span>
          </Link>

          <Link
            href="/privacy"
            className="text-xs font-semibold uppercase tracking-widest text-zinc-400 hover:text-[#D4AF37] transition"
          >
            Súkromie & Podmienky →
          </Link>
        </div>

        <div className="space-y-12 text-zinc-300">
          <div>
            <span className="text-xs font-semibold tracking-widest uppercase text-[#D4AF37] block mb-2">
              Centrum pomoci & Riešenie problémov
            </span>
            <h1 className="text-3xl sm:text-4xl font-serif font-bold text-white tracking-tight">
              Podpora aplikácie Encore
            </h1>
            <p className="text-sm text-zinc-400 mt-2">
              Sme tu, aby sme Vám pomohli s akoukoľvek otázkou ohľadom zostáv, synchronizácie alebo účtu.
            </p>
          </div>

          {/* ── Contact Form (Formspree via @formspree/react) ──────────────── */}
          <div className="bg-gradient-to-br from-[#16151E] to-[#0D0C13] border border-[#D4AF37]/25 rounded-2xl p-6 sm:p-8 shadow-2xl relative overflow-hidden">
            <div className="absolute top-0 right-0 w-32 h-32 bg-[#D4AF37]/10 rounded-full blur-2xl pointer-events-none" />
            <h2 className="text-xl font-serif font-semibold text-white mb-1">
              Napíšte nám
            </h2>
            <p className="text-sm text-zinc-400 mb-6">
              Vaša správa príde priamo na náš email. Odpovieme do 48 hodín.
            </p>

            <ContactForm />
          </div>

          {/* ── FAQ ─────────────────────────────────────────────────── */}
          <section className="space-y-6">
            <h2 className="text-xl font-serif font-bold text-white">
              Často kladené otázky (FAQ)
            </h2>

            <div className="space-y-4">
              <div className="bg-[#100F16] border border-zinc-800 rounded-xl p-5">
                <h3 className="text-white font-medium mb-1">
                  Ako funguje synchronizácia medzi iPhonom a webom?
                </h3>
                <p className="text-sm text-zinc-400">
                  Akonáhle sa prihlásite do rovnakého účtu v iOS aplikácii aj na webe, Vaše choreografie a zmeny na canvase sa synchronizujú v reálnom čase.
                </p>
              </div>

              <div className="bg-[#100F16] border border-zinc-800 rounded-xl p-5">
                <h3 className="text-white font-medium mb-1">
                  Funguje Encore aj bez internetového pripojenia?
                </h3>
                <p className="text-sm text-zinc-400">
                  Áno! Encore funguje v offline-first režime. Všetky zostavy, metronóm a knižnicu figúr máte k dispozícii aj bez signálu. Po pripojení sa zmeny automaticky synchronizujú.
                </p>
              </div>

              <div className="bg-[#100F16] border border-zinc-800 rounded-xl p-5">
                <h3 className="text-white font-medium mb-1">
                  Ako môžem zmazať účet alebo exportovať dáta?
                </h3>
                <p className="text-sm text-zinc-400">
                  V mobilnej aplikácii: <strong>Profil</strong> → <strong>Údržba a Dáta</strong> → možnosť exportu JSON alebo trvalého zmazania účtu.
                </p>
              </div>
            </div>
          </section>
        </div>

        <footer className="mt-16 pt-8 border-t border-zinc-900 text-center text-xs text-zinc-600">
          © {new Date().getFullYear()} Encore Studio. Všetky práva vyhradené.
        </footer>
      </div>
    </main>
  )
}
