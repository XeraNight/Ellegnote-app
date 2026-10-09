# E-mail pre SZTŠ: prístup k verejným údajom KSIS (návrh 9. 10. 2026)

**Komu:** `szts@szts.sk`, všeobecný kontakt SZTŠ z výročnej správy 2024. Pred odoslaním ho over na szts.sk.
Kto spravuje KSIS, som verejne nenašiel, preto e-mail prosí o preposlanie.

**Doplň:** telefón (ak chceš). Vetu o bezplatnom prehľade nechaj, len ak súhlasíš s rozdelením
v `docs/V1_PAYWALL_FEATURES_PLAN.md` (KSIS prehľad zadarmo, automatika v Plus).

---

**Predmet:** Encore: prístup k verejným údajom z KSIS

Dobrý deň,

volám sa Jakub Kalina, tancujem za TK Ellegance Košice (Dospelí D) a popri škole robím aplikáciu Encore
pre iPhone. Je to tréningový denník pre tanečníkov a trénerov (zostavy, videá, poznámky z lekcií) a čoskoro
bude v App Store.

Chcel by som do nej pridať prehľad súťaží. Pár by si po prepojení svojho čísla videl triedu, body, finále,
históriu výsledkov a krížiky od porotcov. V deň súťaže by videl aj to, či postúpil do ďalšieho kola.
Všetko sú to údaje, ktoré KSIS už verejne zobrazuje, nič iné nepotrebujeme.

KSIS však chráni Cloudflare a náš server nepustí. Chcel by som vás preto poprosiť o súhlas a o jednu z dvoch
možností: pravidlo v Cloudflare, ktoré pustí naše požiadavky s kľúčom od vás, alebo export údajov
v akejkoľvek podobe.

KSIS by sme nezaťažovali. Posielali by sme najviac jednu požiadavku za sekundu, každú stránku by sme načítali
raz pre všetkých používateľov a vždy by sme sa podpísali menom aplikácie a kontaktom. Údaje uvidí len samotný
pár. Nebudeme ich predávať ani ďalej zverejňovať, servery máme v EÚ a pri výsledkoch uvedieme, že oficiálnym
zdrojom je SZTŠ. Základný prehľad výsledkov bude v aplikácii zadarmo. Ak máte nejaké podmienky, rád sa im
prispôsobím.

Pri skúšaní som si všimol dve nezrovnalosti pri súťaži 12094 (Košice GP 2026, Dospelí D ŠTT):
- záložka Skating má v súhrne finále inak 4. a 5. miesto ako výsledková listina,
- v hodnotení chýba porotca D, hoci jeho krížiky sú asi započítané v Sume.

Ak vás to zaujíma, pošlem podrobnosti.

Ak KSIS spravuje niekto iný, budem vďačný za preposlanie. Aplikáciu vám rád ukážem.

Ďakujem,
Jakub Kalina
jakubkalina05@gmail.com
[telefón]

---

## Poznámky (do e-mailu nepatria)

- **Neposielaj** číslo preukazu ani heslá.
- **Ak odpovedia áno:** povedz mi, akú možnosť zvolili. Kľúč od nich vložíš do Supabase → Edge Functions →
  Secrets ako `KSIS_ACCESS_KEY`, nikdy nie do kódu.
- **Zdroje kontaktu:**
  - [Výročná správa SZTŠ 2024](https://szts.sk/wp-content/uploads/2025/06/2024_SZTS_vyrocna-sprava-oprava-final.pdf)
  - [Stanovy SZTŠ 2024](https://szts.sk/wp-content/uploads/2024/06/Stanovy-SZTS-2024.pdf)
