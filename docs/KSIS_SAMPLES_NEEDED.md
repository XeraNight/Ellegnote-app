# KSIS: čo ešte potrebujem, prečo a ako to uložiť z iPhonu (9. 10. 2026)

Čítanie **hotových** súťaží je hotové a otestované (`docs/KSIS_AUTO_CONNECT_PLAN.md` §6). Na plné
automatické sledovanie chýbajú tri veci, v tomto poradí dôležitosti:

1. **povolenie od KSIS pre náš server** (bez neho automatika nepôjde vôbec),
2. pár stránok, ktoré sa dajú uložiť kedykoľvek (aj dnes večer),
3. ako vyzerá KSIS **počas** súťaže (krížiky a postup po kolách).

Na všetko stačí **iPhone**, Mac pri sebe netreba (návod v §5).

---

## 1. Najväčšia prekážka: KSIS náš server nepustí

**Test 9. 10. 2026 o 01:21:** server Supabase → `sutaz.php?sutaz_id=12094` → **403 a stránka Cloudflare
„Just a moment…“**. Nie je to chyba v kóde. Cloudflare pred KSIS púšťa ľudí v prehliadači, servery nie.

**Prečo tvoje Safari prejde a server nie:**
- Cloudflare posudzuje každého návštevníka zvlášť.
- **Ty:** človek s bežným prehliadačom na domácom alebo mobilnom internete. Overenie prebehne neviditeľne
  na pozadí, preto ho nevidíš ani pri obnovovaní.
- **Náš server:** počítač v dátovom centre Amazonu v Írsku. Cloudflare ho berie ako robota a zastaví ho
  vždy.

Čo to znamená:
- **nefunguje automatické čítanie zo servera:** ranná obnova, sledovanie v deň súťaže, upozornenia,
- **nefunguje ani súčasné „Importovať výsledok“** v appke (funkcia `ksis-import` číta KSIS tiež zo servera),
- kým to nevyriešime, **paywall nesmie sľubovať nič z KSIS** (App Review 2.1 a 3.1.2;
  `docs/V1_LAUNCH_CHECKLIST.md` C22).

Čo s tým:
- **Požiadať SZTŠ / prevádzkovateľa KSIS o povolenie.** Buď pustia náš server cez Cloudflare (allowlist),
  alebo dajú export dát. Toto je **podmienka** automatického sledovania, nie bonus. E-mail je pripravený
  v `docs/KSIS_SZTS_EMAIL.md`.
- **Upozornenie na zamknutej obrazovke ide len cez server.** iOS appke nedovolí kontrolovať KSIS každé
  2 minúty na pozadí. Kedy appku zobudí, rozhoduje iOS, a býva to oveľa zriedkavejšie. Správa na zamknutú
  obrazovku preto prichádza zo servera (push), a ten potrebuje povolenie od KSIS aj Developer účet.
- **Čo robiť nebudeme:**
  - riešiť overenie robotom,
  - tváriť sa ako prehliadač,
  - meniť IP adresy alebo posielať požiadavky cez mobily používateľov.

  Je to proti vôli KSIS, nespoľahlivé a hrozí, že zablokujú všetkých.
- **Čo ide aj bez povolenia (návrh do v1):** import, ktorý spustí človek.
  1. V appke otvoríš KSIS (overenie prípadne prejdeš ty ako človek) a nalistuješ svoju súťaž.
  2. Ťukneš „Uložiť do denníka“.
  3. Appka prečíta **len tú stránku, ktorú máš otvorenú**, tými istými otestovanými čítačkami. Sama
     nikam nechodí a nič neobnovuje na pozadí.

  Je to presné, no bez automatiky a bez upozornení. **Postavené 9. 10. 2026:**
  - v appke: `KSISBrowserView`, nový Súťažný denník a detail súťaže s krížikmi,
  - na serveri: funkcia `ksis-page`, ktorá stránku prečíta testovanými čítačkami a uloží len tvoj pár.
- **Naživo, keď sa pozeráš (tiež bez povolenia):** v deň súťaže otvoríš v appke svoju kategóriu a stiahneš
  obrazovku nadol, rovnako ako obnovuješ Safari. Appka ukáže prehľadne „1. kolo: postupujete ✓, 28
  krížikov“ a krížiky podľa mien porotcov. Obnovuješ ty, appka sama nie. Na zamknutej obrazovke nič.

---

## 2. Stránky, ktoré sa dajú uložiť kedykoľvek (aj dnes večer)

| # | Stránka | Adresa | Prečo ju potrebujem |
|---|---|---|---|
| 1 | Úvod KSIS | `https://szts.ksis.eu/` | Menu so všetkými odkazmi. Uvidím, kde je zoznam výsledkov a kalendár. |
| 2 | Podujatie | `https://szts.ksis.eu/podujatie.php?pod_id=1088` | Z prihlášky vieme „Dospelí D ŠTT“, ale nie číslo súťaže (`sutaz_id`). Podujatie ich spája. |
| 3 | Kalendár súťaží | `https://szts.ksis.eu/menu.php?akcia=KS` | Odtiaľ appka zistí, aké podujatia budú a kde je zoznam prihlášok. Tak vie sama, že v sobotu tancujete. |
| 4 | Členovia, číslo partnerky | `https://szts.ksis.eu/menu.php?akcia=CZ&cis_pr=95398&aktivne=on` (ak nič neukáže, napíš 95398 do hľadania v zozname členov) | Pár sa podľa jej čísla nenájde. Cez zoznam členov sa partnerka prepojí svojím číslom. |
| 5 | Hodnotenie LAT | `https://szts.ksis.eu/hodnot_sut.php?sutaz_id=12105` | Overím latinské tance a či aj tam chýba porotca. |
| 6 | Zoznam výsledkov súťaží | stránka z menu KSIS, kde je zoznam výsledkov (adresu neviem, preto bod 1) | Aby server našiel stránku vášho páru (`par.php?id=18978`) bez hľadania naslepo. Z čísla páru 95397 sa na ňu priamo dostať nedá. |

---

## 3. Počas súťaže (zajtra Kežmarok alebo ktorákoľvek ďalšia)

**Prečo:** nevieme, ako KSIS vyzerá, kým súťaž beží:
- kedy sa stránka súťaže objaví (pred 1. kolom, alebo až po ňom),
- **za koľko minút po kole** sa objavia krížiky a „Postup“,
- či pribúdajú kolá postupne (1. kolo → semifinále → finále), alebo všetko naraz na konci,
- kedy sa objaví výsledková listina.

Od toho závisí, či má živé sledovanie zmysel, ako často kontrolovať KSIS a čo vám appka môže oznámiť
(„Postupujete do semifinále“).

**Nemusí to byť vaša kategória.** Všetky kategórie majú rovnaké stránky, takže stačí ktorákoľvek, ktorá sa
práve tancuje. Napríklad tá pred vami, kým čakáte, alebo tá po vás. Môže to urobiť aj niekto iný: rodič,
kamarát, tréner.

### Minimum (keď nestíhaš)
1. **Krížiky po 1. kole:**
   - keď sa objavia, ulož stránku **Hodnotenie**,
   - do Poznámok si zapíš, **kedy to kolo skončilo** (napr. „10:42 koniec 1. kola Junior II D ŠTT“).
2. **Po dotancovaní finále (pred vyhlásením):** ulož **Hodnotenie** a **Výsledkovú listinu**.

### Ideálne
| Kedy | Čo uložiť |
|---|---|
| Ráno | Stránku podujatia tohto dňa (zoznam súťaží) |
| Počas 1. kola | Hodnotenie a Výsledkovú listinu tej kategórie. Ak ešte neexistujú, aspoň snímku obrazovky toho, čo KSIS ukáže. |
| Po 1. kole | Každé 2–3 minúty obnov Hodnotenie, a keď sa objavia krížiky, ulož ho |
| Počas finále | Hodnotenie (je tam už postup zo semifinále?) |
| Po finále, pred vyhlásením | Hodnotenie a Výsledkovú listinu |
| Po vyhlásení | Výsledkovú listinu |

**Časy:**
- **Kedy kolo skončilo na parkete** si zapíš do Poznámok, to iPhone nevie.
- **Kedy si stránku uložil**, si iPhone pamätá sám.

**Ako nájsť stránku súťaže:** otvor podujatie dňa (z kalendára alebo výsledkov), ťukni na kategóriu a hore
prepínaj **Výsledková listina** / **Hodnotenie**.

---

## 4. Čo s tým potom urobím

| Keď príde | Postavím |
|---|---|
| Povolenie KSIS, alebo tvoje OK na import z otvorenej stránky (§1) | Serverovú funkciu `ksis-sync`, alebo import z otvorenej stránky KSIS v appke |
| Stránky z §2 | Prepojenie číslom páru aj číslom partnerky, automatické nájdenie histórie s krížikmi, nájdenie súťaží z prihlášok |
| Stránky z §3 | Živé sledovanie: ako často čítať, texty upozornení, testy na skutočnom priebehu súťaže |

Z každej stránky urobím anonymizovanú vzorku do `fixtures/ksis/` (mená vymyslené) a testy. Surové súbory
zostanú len u teba (priečinok `Encore:ksis-samples` je v `.gitignore`).

---

## 5. Ako uložiť stránku na iPhone (Mac netreba)

**Najlepšie: webový archív (presne to, čo KSIS poslal)**
1. Otvor stránku v **Safari**.
2. Ťukni **Zdieľať** (v iOS 26 je v ponuke **•••** vedľa adresy).
3. Hore pod názvom stránky ťukni **Možnosti** → zvoľ **Webový archív** → **Hotovo**.
4. Ťukni **Uložiť do Súborov** → **iCloud Drive** → priečinok **Encore KSIS** (vytvor si ho raz).

**Keď Možnosti nevidíš: snímka celej stránky**
1. Urob snímku obrazovky (bočné tlačidlo + zvýšenie hlasitosti).
2. Ťukni na náhľad vľavo dole → hore zvoľ **Celá stránka** → **Hotovo**.
3. **Uložiť PDF do Súborov** → **Encore KSIS**.

Z PDF viem čítať tiež, len menej presne (nevidím skryté časti stránky).

**Doma:** napíš mi, keď budú súbory v iCloud Drive → Encore KSIS. Na Macu si ich skopírujem a prevediem
sám, nič presúvať nemusíš.

---

## 6. Zistené zo stránky „Skating“ (súťaž 12094)

- **Stránka Skating má v KSIS chybu.**
  - V tangu je prázdny stĺpec porotcu A, vo viedenskom valčíku A a B, v quickstepe B a C.
  - KSIS tie prázdne políčka počíta ako 0, teda ako hlas na 1. miesto. Overené: všetkých 86 čísel
    v stĺpcoch „1, 1-2, 1-3…“ sa presne takto dá prepočítať.
- **Súhrn finále na tejto stránke odporuje oficiálnej Výsledkovej listine.**
  - Páry na 4. a 5. mieste má prehodené.
  - Súčty v nej nesedia so „Sumou“ v Hodnotení: 9,5 / 16 / 15,5 namiesto 10 / 15 / 16.
- **Oficiálne a navzájom zhodné sú** Výsledková listina a Hodnotenie. Appka číta len tie dve, zo Skatingu
  nič.
- **Umiestnenie v jednotlivých tancoch** finále preto appka neukáže: KSIS ho spoľahlivo nezverejňuje
  a bez skrytého porotcu D sa nedá vypočítať. Ukáže umiestnenia od každého zverejneného porotcu, Sumu
  a konečné miesto.
