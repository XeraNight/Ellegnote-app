import Link from 'next/link'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Zásady ochrany osobných údajov | Encore',
  description: 'Zásady ochrany osobných údajov pre aplikáciu Encore – Dance Routine Studio.',
}

export default function PrivacyPolicyPage() {
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
            href="/support"
            className="text-xs font-semibold uppercase tracking-widest text-zinc-400 hover:text-[#D4AF37] transition"
          >
            Podpora & Kontakt →
          </Link>
        </div>

        <article className="space-y-10 text-zinc-300 leading-relaxed text-sm sm:text-base">
          <div>
            <span className="text-xs font-semibold tracking-widest uppercase text-[#D4AF37] block mb-2">
              Právne informácie & Ochrana súkromia
            </span>
            <h1 className="text-3xl sm:text-4xl font-serif font-bold text-white tracking-tight">
              Zásady ochrany osobných údajov (Privacy Policy)
            </h1>
            <p className="text-xs text-zinc-500 mt-2">
              Posledná aktualizácia: 14. septembra 2026
            </p>
          </div>

          <section className="space-y-3">
            <h2 className="text-lg font-semibold text-white">1. Prehľad a náš záväzok</h2>
            <p>
              Aplikácia <strong>Encore</strong> (a sprievodná webová platforma Encore Studio) je prémiový nástroj určený pre tanečníkov, trénerov a choreografov na tvorbu a vizualizáciu tanečných zostáv, prácu s metronómom a tréningovými materiálmi.
            </p>
            <p>
              Vaše súkromie berieme s najvyššou vážnosťou. Naším základným princípom je, že Vaše tanečné zostavy, choreografie, tréningové videá a poznámky patria výhradne Vám a nikdy ich nepredávame tretím stranám na reklamné účely.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="text-lg font-semibold text-white">2. Aké údaje spracúvame</h2>
            <ul className="list-disc pl-5 space-y-2 text-zinc-300">
              <li>
                <strong>Údaje účtu:</strong> Pri registrácii prostredníctvom e-mailu, Sign in with Apple alebo Google spracúvame Váš e-mail, voliteľné meno a identifikátor profilu.
              </li>
              <li>
                <strong>Tanečné dáta a zostavy:</strong> Názvy tancov, figúry, počty taktov, poznámky, usporiadanie uzlov na canvase a metronómové nastavenia, ktoré si do aplikácie sami uložíte.
              </li>
              <li>
                <strong>Fotografie a videá:</strong> Ak aplikácii udelíte povolenie, Encore pristupuje ku kamere a knižnici fotiek výhradne za účelom nahrávania a priraďovania tréningových videí k Vašim vlastným zostavám a nastavenia profilovej fotografie.
              </li>
              <li>
                <strong>Mikrofón a hlasový prepis:</strong> Povolenie k mikrofónu a rozpoznávaniu reči (Speech Recognition) slúži výlučne na zaznamenávanie tréningových hlasových poznámok trénera a ich lokálny prepis do textu.
              </li>
            </ul>
          </section>

          <section className="space-y-3">
            <h2 className="text-lg font-semibold text-white">3. Úložisko a zabezpečenie dát</h2>
            <p>
              Vaše dáta sú bezpečne uložené na cloudovej infraštruktúre platformy Supabase s uplatnením šifrovania počas prenosu (TLS/HTTPS) a Row Level Security (RLS), ktorá zaisťuje autorizovaný prístup k záznamom. Lokálna kópia na Vašom iOS zariadení je chránená bezpečnostným mechanizmom Apple iOS Sandbox a Keychain.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="text-lg font-semibold text-white">4. Zmazanie účtu a práva používateľa (GDPR)</h2>
            <p>
              V súlade s pravidlami Apple App Store a európskym nariadením GDPR máte plné právo kedykoľvek požiadať o trvalé vymazanie svojich údajov:
            </p>
            <div className="bg-[#121118] border border-[#D4AF37]/20 rounded-xl p-5 my-3">
              <h3 className="text-white font-medium mb-1">Ako zmazať účet priamo v aplikácii:</h3>
              <p className="text-zinc-400 text-sm">
                V aplikácii Encore otvorte <strong>Profil</strong> → prejdite do sekcie <strong>Údržba a Dáta</strong> → zvoľte <strong>Zmazať účet a osobné dáta</strong>. Týmto krokom sa okamžite a trvalo vymažú Vaše prihlasovacie údaje, relácie a profil z databázy.
              </p>
            </div>
            <p>
              Prípadne môžete o vymazanie údajov požiadať zaslaním e-mailu na adresu uvedenú na stránke podpory.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="text-lg font-semibold text-white">5. Kontakt</h2>
            <p>
              V prípade otázok týkajúcich sa ochrany osobných údajov nás kontaktujte prostredníctvom našej stránky podpory na{' '}
              <Link href="/support" className="text-[#D4AF37] underline hover:opacity-80">
                encore.support
              </Link>.
            </p>
          </section>
        </article>

        <footer className="mt-16 pt-8 border-t border-zinc-900 text-center text-xs text-zinc-600">
          © {new Date().getFullYear()} Encore Studio. Všetky práva vyhradené.
        </footer>
      </div>
    </main>
  )
}
