# Automatické prepojenie s KSIS: zistenia a návrh (8. 10. 2026)

Cieľ: tanečník sa prepojí jedným krokom (meno) a appka potom sama ukazuje triedu, body, finále,
históriu výsledkov a krížiky. Bez zadávania čísel súťaží. Spoľahlivo a férovo voči KSIS.

## 1. Čo KSIS verejne ukazuje
Overené v prehliadači 8. 10. 2026. Pozeral som iba štruktúru stránok, nie údaje konkrétnych ľudí.

| Stránka | Adresa | Čo obsahuje |
|---|---|---|
| Zoznam členov | `menu.php?akcia=CZ` | Č.pr (osobné číslo z preukazu), Meno, Klub, Sekcia, trieda ŠTT a LAT, roly (rozhodca, funkcionár, sčitateľ, tréner), Stav. Vyhľadávanie podľa textu, filter „aktívni“. |
| Zoznam párov | `menu.php?akcia=CZP` | Č.pr páru, Partner, Partnerka, Klub, Vek. kategória, ŠTT, LAT, Stav. Filtre: text, aktívne, vek. kategória, trieda ŠTT/LAT. |
| Detail páru | `detail_paru.php?cp=<Č.pr páru>` | Pre ŠTT aj LAT aktuálneho roka: **Trieda, Body, Finále, Posledná zmena** |
| Stránka páru | `par.php?id=<interné ID>` | Trieda s bodmi a finále (napr. „C (238/14F)“) + **celá história**: Dátum, Podujatie, Súťaž, Počet párov, Umiestnenie, Body, Body po |
| Výsledky súťaže | `sutaz.php?sutaz_id=…` | Umiestnenie, Č.p., Pár (odkaz na stránku páru), Klub, Body, Celkom; kolá (Finále, Semifinále…) |
| Hodnotenie porotcov | `hodnot_sut.php?sutaz_id=…` | Po kolách a tancoch **krížiky od každého porotcu**, Suma, Umiestnenie, **Postup** |
| Kalendár, podujatia | `menu.php?akcia=KS`, `podujatie.php?pod_id=…` | Termíny a zoznam súťaží podujatia |

Dôležité:
- **Interné ID stránky páru nie je to isté ako Č.pr** zo zoznamu. Získa sa z odkazu na pár vo výsledkoch
  súťaže, kde pár štartoval.
- **KSIS je za ochranou Cloudflare a náš server nepustí.** Test 9. 10. 2026: 403 „Just a moment…“.
  Automatika potrebuje povolenie od SZTŠ / KSIS (`docs/KSIS_SAMPLES_NEEDED.md` §1).
- „Dancer ID“ v Encore (DNC-…) je náš kód. S KSIS nemá nič spoločné.

## 2. Najjednoduchší postup pre tanečníka
1. Súťaže → **„Prepoj sa s KSIS“** → napíšeš priezvisko (voliteľne osobné číslo z preukazu, ak je
   viac rovnakých mien).
2. Server vyhľadá aktívne páry s týmto menom a ukáže 1–3 karty: partner a partnerka, klub,
   vek. kategória, triedy ŠTT a LAT.
3. Ťukneš na svoj pár a potvrdíš, že partner(ka) súhlasí so zobrazením spoločných výsledkov (súhlas už
   v appke je).
4. **Hneď vidíš triedu, body a finále pre ŠTT aj LAT** z detailu páru, teda skutočné čísla z KSIS.
5. **História a krížiky na pozadí:**
   - server nájde interné ID páru vo výsledkoch posledných súťaží,
   - načíta celú históriu zo stránky páru,
   - ku každej súťaži doplní krížiky po kolách a informáciu, či pár postúpil.
6. **Obnova:** raz denne, po súťažnom víkende a tlačidlom „Obnoviť“. Nové výsledky sa doplnia samy.

Potrebné je len **meno** (osobné číslo iba pri zhode mien). Hranice „koľko chýba na postup“ prídu
z aktuálneho súťažného poriadku (článok 9) so zdrojom a rokom. Do vtedy appka ukazuje len čísla z KSIS.

## 3. Živé výsledky počas súťaže („postupujeme?“)
Stĺpec **Postup** v hodnotení porotcov ukazuje, kto postúpil z kola. **Treba overiť na živej súťaži**
(najbližšia v kalendári KSIS), či ho KSIS zverejňuje priebežne, alebo až po skončení. To je podmienka
z `docs/KSIS_PHASE2_NOTES.md`.
- **Ak priebežne:** v deň súťaže appka sleduje tvoj pár každé 2–3 minúty a ukáže „Postupujete do
  semifinále“. Upozornenie na zamknutej obrazovke (push) potrebuje Developer účet.
- **Ak až po skončení:** výsledok a krížiky ukážeme hneď po zverejnení.

## 4. Spoľahlivosť a férovosť
- **Šetrnosť:** najviac 1 požiadavka za sekundu. Výsledky súťaže sa stiahnu **raz pre všetkých**
  používateľov a uložia na serveri, nie zvlášť pre každého.
- **Poctivé označenie** „EncoreApp (kontakt)“ už je.
- **Dohoda so SZTŠ je pre spoľahlivosť najdôležitejšia.** Ochrana Cloudflare nás môže kedykoľvek
  zablokovať. Požiadať o povolenie (allowlist) alebo o export dát. Šablóna e-mailu je
  v `LEGAL_AND_COMPLIANCE_CHECKLIST.md` §5.3, treba doplniť túto konkrétnu žiadosť.
- **Zmena stránky KSIS:** testy parsera nad uloženými vzorkami HTML (urobím ich z tvojho páru s tvojím
  súhlasom). Pri zlyhaní sa v logoch ukáže presná príčina.
- **Údaje partnera:** výsledky sú verejné, no stále sú to osobné údaje. Zobrazujú sa len páru a jeho
  trénerom, so súhlasom partnera.

## 5. Čo bude treba (všetko ukážem pred nasadením)
1. SQL: k `user_couples` doplniť interné ID stránky páru a posledný stav tried; tabuľka výsledkov
   súťaží zdieľaná pre všetkých (aby sa KSIS nečítal opakovane).
2. Serverová funkcia `ksis-sync`: vyhľadanie páru, detail, história, hodnotenie porotcov.
3. Plán obnovy (cron raz denne).
4. Nová obrazovka „Prepoj sa s KSIS“ a karta páru v Súťažnom denníku (štýl §1A).
5. Žiadosť SZTŠ.


---

## 6. Overené na vašom páre (9. 10. 2026, so súhlasom)

- **Číslo páru = osobné číslo partnera.** Pár 95397 sa nájde v zozname párov cez `cis_pr=95397`.
  Partnerkino číslo 95398 je v zozname členov, ale pár sa podľa neho nenájde. Preto: číslo partnerky →
  jej meno zo zoznamu členov → pár podľa mena.
- **Hľadanie podľa priezviska** v zozname párov funguje (`hladany_text`).
- **Detail páru** má hodnoty v pomenovaných poliach (`vyk_STT`, `body_STT`, `finale_STT`, `dpz_STT`,
  rovnako `_LAT`, plus mená, klub, vek. kategória). Čítanie je teda spoľahlivé.
- **Stránka výsledkov páru** má interné číslo **18978** (iné ako 95397). Nájde sa z odkazu na pár vo
  výsledkoch súťaží jeho vekovej kategórie a triedy. „Č.p.“ vo výsledkoch je len štartové číslo
  (u vás 61).
- **„89/5F“** vo výsledkoch sedí s detailom páru (89 bodov, 5 finále).
- **Hodnotenie porotcov:**
  - po kolách (1. kolo, semifinále…) a tancoch reťazec krížikov podľa porotcov `A…F`
    (napr. `X.XXXX` = porotca B nedal krížik), potom Suma, Umiestnenie a **Postup** (`Y` / `-`),
  - vo finále namiesto krížikov umiestnenia od každého porotcu (napr. `331426`) a súčet podľa skatingu,
  - na stránke súťaže sú porotcovia ako „A – meno (mesto)“, takže pri krížiku vieme ukázať meno porotcu.
- **Prihlášky na súťaže:** v kalendári je pri každom podujatí `zoznam_prihl.php` so zoznamom
  prihlásených párov podľa kategórií. Appka teda sama zistí, že v sobotu tancujete Dospelí D ŠTT a LAT.
- **Vyriešené: skrytý porotca.** „Suma“ v kole je o 0 až 4 vyššia než zverejnené krížiky (u vás 28 pri
  24, v semifinále 26 pri 22). Dôvod:
  - zoznam porotcov má písmená A, B, C, E, F, G, **chýba D**. KSIS ukazuje 6 stĺpcov, hoci porotcov bolo 7,
  - rozdiel nie je nikdy väčší ako 4, teda jeden krížik za každý zo 4 tancov od jedného porotcu
    (platí pre všetkých 13 párov vo všetkých kolách),
  - **finále to potvrdzuje:** prepočet skatingom len zo 6 zverejnených porotcov dáva iné súčty (vám 13
    a 2. miesto) ako KSIS (15 a 3. miesto). Siedmy porotca výsledok KSIS vysvetlí.

  KSIS teda porotcu D započíta do Sumy aj do finále, ale jeho meno ani známky nezverejní (prečo, nevieme).
  Appka ukáže: krížiky každého zverejneného porotcu s menom, „Sumu“ presne z KSIS a „skrytý porotca:
  4 krížiky“ (= Suma − zverejnené krížiky). Ak by čísla nesedeli, ukáže len Sumu z KSIS.
- **Stĺpce porotcov sa priraďujú podľa poradia**, nie podľa písmena v hlavičke: 4. stĺpec „D“ patrí
  porotcovi E zo zoznamu.
- **Body za súťaž** (u vás 18) a „Celkom“ (89/5F) berieme priamo z KSIS, appka ich nepočíta.
- **Skating** je spôsob, ako sa z umiestnení od porotcov vo finále vypočíta poradie (väčšina porotcov,
  potom súčet umiestnení v tancoch). **Stránka `skating.php` má v KSIS chybu** a jej súhrn odporuje
  oficiálnym výsledkom, preto z nej nečítame nič (`docs/KSIS_SAMPLES_NEEDED.md` §6).

**Čítanie stránok je hotové a otestované (9. 10. 2026):**
- kód: `supabase/functions/_shared/ksis-pages.ts`, testy: `ksis-pages.test.ts` (15 testov),
- vzorky: `fixtures/ksis/`, anonymizované (mená vymyslené, čísla a rozloženie skutočné),
- keď KSIS zmení stránku, čítanie skončí chybou „layout_changed“ a nič si nedomýšľa.

## 7. Ako to postavíme (každý krok build, testy, tvoja kontrola)

1. **SQL** `supabase/migrations/20261009_ksis_auto_sync.sql`:
   - stav páru z KSIS pri `user_couples`,
   - kolá s krížikmi a porotcovia pri výsledkoch,
   - sledované súťaže `ksis_live_watches`,
   - upozornenia `user_notifications`,
   - zdieľaná vyrovnávacia pamäť stránok,
   - časovače (pg_cron): ráno obnova a prihlášky, v deň súťaže každé 2 minúty, v noci upratanie.
     Časovače chráni náhodné heslo, ktoré pozná len databáza.
2. **Čítanie stránok** (čistý kód s testami nad anonymizovanými vzorkami): zoznam párov, zoznam členov,
   detail páru, história, hodnotenie porotcov, porotcovia, prihlášky.
3. **Serverová funkcia `ksis-sync`:**
   - pre používateľa: `search` (meno alebo číslo), `link`, `refresh`, `stop_watch`, `unlink`,
   - pre časovač: `cron_daily`, `cron_live`.

   Šetrne: najviac 1 požiadavka za sekundu, každá stránka sa načíta raz pre všetkých.
4. **Appka:**
   - „Prepoj sa s KSIS“ (napíšeš meno alebo číslo, ťukneš na svoj pár),
   - Súťažný denník so skutočnými číslami z KSIS,
   - detail súťaže s krížikmi od každého porotcu po kolách,
   - karta „Dnes súťažíte“ so živým postupom.
5. **Test na živej súťaži:** najbližšie podujatie z kalendára KSIS. Overíme, ako rýchlo sa objaví „Postup“.
6. **Po kúpe Developer účtu:** upozornenie na zamknutej obrazovke (push) a Live Activity
   („Semifinále: postupujete ✓“) na zamknutej obrazovke a v Dynamic Islande.

**Dovtedy (bez Developer účtu):**
- v deň súťaže appka ukazuje postup okamžite, keď je otvorená,
- upozornenia sa ukážu po otvorení appky,
- iOS bez push nedovolí, aby sa správa sama zobrazila na zamknutej obrazovke spoľahlivo.
