import React from 'react'

export default function BentoFeatures() {
  return (
    <section id="features" className="py-24 relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      {/* Section Header */}
      <div className="text-center max-w-3xl mx-auto mb-16 space-y-3">
        <span className="text-xs font-mono font-bold uppercase tracking-[0.25em] text-[#FFE088] bg-[#D4AF37]/10 px-4 py-1.5 rounded-full border border-[#D4AF37]/25">
          Architektúra pre šampiónov
        </span>
        <h2 className="text-3xl sm:text-5xl font-serif font-black tracking-tight text-white">
          Navrhnuté pre tréningy, kempy aj súťažné finále
        </h2>
        <p className="text-sm sm:text-base text-zinc-400">
          Zabudnite na papierové zošity a stovky neprehľadných videí v galérii. Encore prepája choreografiu, video rozbor, rytmus a súťažné dáta do jedného dokonale zosúladeného celku.
        </p>
      </div>

      {/* Bento Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        
        {/* Card 1: 2D Parket (Large 2-column) */}
        <div className="md:col-span-2 rounded-3xl p-8 bg-gradient-to-br from-[#14131c] via-[#0d0c13] to-[#070709] border border-[#D4AF37]/30 shadow-2xl relative overflow-hidden flex flex-col justify-between group hover:border-[#D4AF37]/60 transition-all">
          <div className="absolute top-0 right-0 w-80 h-80 bg-[#D4AF37]/10 rounded-full blur-3xl pointer-events-none group-hover:scale-125 transition-transform" />
          
          <div className="space-y-3 z-10 max-w-xl">
            <span className="text-[11px] font-mono font-bold uppercase tracking-wider text-[#D4AF37]">
              Choreografia & Priestor
            </span>
            <h3 className="text-2xl sm:text-3xl font-serif font-bold text-white">
              Nekonečný 2D Parket s Bezierovými krivkami
            </h3>
            <p className="text-xs sm:text-sm text-zinc-300 leading-relaxed">
              Zaznamenajte svoju zostavu presne tak, ako sa tancuje v sále. Definujte smer pohybu (Line of Dance), uhly nášľapov, rytmické doby (SQQ, 1 2 3) a prepojte jednotlivé figúry plynulými krivkami. Partner aj tréner vidia každý detail.
            </p>
          </div>

          <div className="mt-8 pt-6 border-t border-zinc-800/80 grid grid-cols-3 gap-4 text-center z-10">
            <div>
              <span className="text-xl sm:text-2xl font-mono font-bold text-[#FFE088]">3000 pt</span>
              <span className="text-[10px] text-zinc-400 block mt-0.5">Plynulý Parket</span>
            </div>
            <div>
              <span className="text-xl sm:text-2xl font-mono font-bold text-[#FFE088]">10 Tancov</span>
              <span className="text-[10px] text-zinc-400 block mt-0.5">Štandard & Latina</span>
            </div>
            <div>
              <span className="text-xl sm:text-2xl font-mono font-bold text-[#FFE088]">WDSF</span>
              <span className="text-[10px] text-zinc-400 block mt-0.5">Knižnica figúr</span>
            </div>
          </div>
        </div>

        {/* Card 2: Video Vault & Slo-Mo */}
        <div className="rounded-3xl p-8 bg-gradient-to-br from-[#1a0a10] via-[#100508] to-[#070709] border border-[#E11D48]/30 shadow-2xl relative overflow-hidden flex flex-col justify-between group hover:border-[#E11D48]/60 transition-all">
          <div className="space-y-3 z-10">
            <span className="text-[11px] font-mono font-bold uppercase tracking-wider text-[#E11D48]">
              Technická Analýza
            </span>
            <h3 className="text-2xl font-serif font-bold text-white">
              Video Duel & Slo-Mo 120/240 FPS
            </h3>
            <p className="text-xs sm:text-sm text-zinc-300 leading-relaxed">
              Pustite si svoj záznam a video majstra sveta alebo trénera vedľa seba. Jediný spoločný posuvník času a krokovanie po snímkach odhalí každú chybu v nášľape či držaní tela.
            </p>
          </div>

          <div className="mt-6 p-3 rounded-2xl bg-black/40 border border-[#E11D48]/20 flex items-center justify-between text-xs z-10">
            <span className="text-zinc-400 font-mono">Scrubbing po snímkach</span>
            <span className="text-[#E11D48] font-bold">Side-by-Side</span>
          </div>
        </div>

        {/* Card 3: Metronome & Speed Trainer */}
        <div className="rounded-3xl p-8 bg-gradient-to-br from-[#151310] via-[#0d0b07] to-[#070709] border border-[#D4AF37]/30 shadow-2xl relative overflow-hidden flex flex-col justify-between group hover:border-[#D4AF37]/60 transition-all">
          <div className="space-y-3 z-10">
            <span className="text-[11px] font-mono font-bold uppercase tracking-wider text-[#FFE088]">
              Rytmus & Svalová Pamäť
            </span>
            <h3 className="text-2xl font-serif font-bold text-white">
              Syntetický PCM Metronóm & Pitch Trainer
            </h3>
            <p className="text-xs sm:text-sm text-zinc-300 leading-relaxed">
              Žiadne MP3 zvuky ani sekanie. Klik metronómu generuje audio engine priamo v RAM. Spomaľte skladbu na 80 % pre dokonalé zvládnutie techniky bez zmeny tóniny, alebo zrýchlite na 105 % pre kondičný finálový tréning.
            </p>
          </div>

          <div className="mt-6 p-3 rounded-2xl bg-black/40 border border-[#D4AF37]/20 flex items-center justify-between text-xs z-10">
            <span className="text-zinc-400 font-mono">0 ms Bluetooth Lag</span>
            <span className="text-[#FFE088] font-bold">80 % – 110 % Pitch</span>
          </div>
        </div>

        {/* Card 4: SZTŠ / ksis.eu Radar */}
        <div className="rounded-3xl p-8 bg-gradient-to-br from-[#10131a] via-[#080a10] to-[#070709] border border-blue-500/30 shadow-2xl relative overflow-hidden flex flex-col justify-between group hover:border-blue-500/60 transition-all">
          <div className="space-y-3 z-10">
            <span className="text-[11px] font-mono font-bold uppercase tracking-wider text-blue-400">
              Súťažný Rebríček
            </span>
            <h3 className="text-2xl font-serif font-bold text-white">
              SZTŠ & ksis.eu Výkonnostný Radar
            </h3>
            <p className="text-xs sm:text-sm text-zinc-300 leading-relaxed">
              Zadajte číslo páru a Encore automaticky načíta Vaše finálové umiestnenia, postupové body a rozstrely. Presne viete, koľko bodov chýba do postupu do vyššej výkonnostnej triedy.
            </p>
          </div>

          <div className="mt-6 p-3 rounded-2xl bg-black/40 border border-blue-500/20 flex items-center justify-between text-xs z-10">
            <span className="text-zinc-400 font-mono">Oficiálne body SZTŠ</span>
            <span className="text-blue-300 font-bold">Triedy D ➔ S</span>
          </div>
        </div>

        {/* Card 5: Apple Wallet & Live Activities */}
        <div className="rounded-3xl p-8 bg-gradient-to-br from-[#121118] via-[#0c0b10] to-[#070709] border border-[#D4AF37]/30 shadow-2xl relative overflow-hidden flex flex-col justify-between group hover:border-[#D4AF37]/60 transition-all">
          <div className="space-y-3 z-10">
            <span className="text-[11px] font-mono font-bold uppercase tracking-wider text-[#D4AF37]">
              Apple Ekosystém
            </span>
            <h3 className="text-2xl font-serif font-bold text-white">
              Apple Wallet Preukaz & Dynamic Island
            </h3>
            <p className="text-xs sm:text-sm text-zinc-300 leading-relaxed">
              Váš oficiálny digitálny tanečný preukaz priamo v Apple Peňaženke s QR kódom na rýchle prepojenie s partnerom. Počas tréningu beží metronóm v Dynamic Islande a na zamknutej ploche.
            </p>
          </div>

          <div className="mt-6 p-3 rounded-2xl bg-black/40 border border-[#D4AF37]/20 flex items-center justify-between text-xs z-10">
            <span className="text-zinc-400 font-mono">Apple Wallet certifikát</span>
            <span className="text-[#FFE088] font-bold">Live Activity</span>
          </div>
        </div>

      </div>
    </section>
  )
}
