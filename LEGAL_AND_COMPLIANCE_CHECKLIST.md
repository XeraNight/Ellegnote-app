# ⚖️ Encore / Ellegnote — Oficiálny Právny & App Store Compliance Checklist

> **Poznámka k statusu:** Tento dokument slúži ako technicko-právny audit a akčný checklist pripravený priamo na mieru kódu aplikácie **Encore**. Pred finálnym komerčným spustením sa odporúča dať vygenerované dokumenty (Privacy Policy & EULA/ToS) prebehnúť právnikovi špecializujúcemu sa na IT/GDPR.

---

## 🚦 RÝCHLY PREHĽAD: Kde naša appka stojí dnes?

| Oblasť | Stav v kóde | Čo je hotové | Čo treba urobiť pred App Store |
| :--- | :---: | :--- | :--- |
| **Sign in with Apple** | 🟢 **HOTOVO** | `SignInWithAppleButton` je v `AuthSheetView.swift` paralelne s Google | Otestovať reálne prihlásenie na fyzickom iPhone |
| **Zmazanie účtu v appke** | 🟢 **HOTOVO** | `deleteAccount()` v `AuthManager.swift` + potvrdzovací dialóg v `ProfileView.swift` | Overiť, že RPC funkcia `delete_user_account` je nasadená v Supabase |
| **Autorské práva k hudbe** | 🟢 **ČISTÉ** | Metronóm generuje syntetický PCM zvuk v RAM (`DanceMetronomeEngine.swift`), Speed Trainer prehráva iba lokálne súbory používateľa | Žiadna nelegálna hudba nie je v bundle appky |
| **Licencie k fontom** | 🟢 **ČISTÉ** | Používajú sa 100% natívne Apple fonty (SF Pro, New York, SF Mono, Zapfino, Snell Roundhand) | Žiadne cudzie fonty (TTF/OTF) s rizikom licenčných poplatkov |
| **Encryption export tag** | 🟡 **POTREBNÉ** | Beží štandardné HTTPS/Keychain | Pridať `ITSAppUsesNonExemptEncryption = NO` do `Info.plist` |
| **Privacy Policy odkaz v appke** | 🔴 **KRITICKÉ** | Chýba v UI | Pridať odkaz na Zásady ochrany osobných údajov do `ProfileView` a `AuthSheetView` |
| **Supabase RLS pravidlá** | 🔴 **KRITICKÉ** | RLS je zapnuté, ale pravidlá majú `using (true)` | Zviazať pravidlá s `auth.uid() = user_id`, aby si používatelia nevideli cudzie zostavy |
| **SZTŠ / ksis.eu dáta** | 🟡 **STRATÉGIA** | Prebieha cez Supabase Edge Function s rate limitom | Poslať informačný e-mail / žiadosť o partnerstvo na SZTŠ |

---

## 1. 🍎 Apple App Store — Technické požiadavky na schválenie (Guideline audit)

### 1.1 Odkaz na Privacy Policy priamo v appke (Guideline 5.1.1)
- [ ] **Problém:** Apple vyžaduje funkčný odkaz na Privacy Policy na dvoch miestach: v App Store Connect a **priamo v používateľskom rozhraní aplikácie**. V našom `ProfileView` a `AuthSheetView` tento odkaz zatiaľ chýba.
- [ ] **Riešenie v kóde:**
  - Vložiť sekciu do `ProfileView`: *"Právne informácie & Ochrana súkromia"* s linkom otvárajúcim URL (napr. Safari sheet).
  - Vložiť drobný text pod tlačidlá v `AuthSheetView`: *"Prihlásením súhlasíte s Obchodnými podmienkami a Zásadami ochrany osobných údajov."*

### 1.2 Sign in with Apple (Guideline 4.8) — STAV: VYRIEŠENÉ ✅
- [x] Apple striktne vyžaduje, že ak appka ponúka Google Sign-In, **musí** ponúkať aj Sign in with Apple ako rovnocennú možnosť.
- [x] V súbore `Encore/AuthSheetView.swift` je `SignInWithAppleButton` implementovaný hneď pod Google Sign-In s rovnakou veľkosťou a natívnym Apple štýlom.

### 1.3 Zmazanie účtu používateľom (Guideline 5.1.1(v)) — STAV: VYRIEŠENÉ ✅
- [x] Apple vyžaduje možnosť zmazať účet priamo v aplikácii, pričom musí ísť o úplné zmazanie dát.
- [x] V `ProfileView.swift` (riadok 659) máme hotový deštruktívny potvrdzovací dialóg: *"Naozaj zmazať účet?"*.
- [x] V `AuthManager.swift` (riadok 496) funkcia `deleteAccount()` volá Supabase RPC procedúru `delete_user_account`, odpája Google Sign-In a maže Keychain položky.

### 1.4 Export Compliance (`ITSAppUsesNonExemptEncryption`) — STAV: POTREBNÉ PRIDAŤ 🟡
- [ ] Apple sa pri každom builde v App Store Connect pýta na exportné šifrovanie.
- [ ] **Riešenie:** Do `Encore/Info.plist` stačí pridať:
  ```xml
  <key>ITSAppUsesNonExemptEncryption</key>
  <false/>
  ```
  Týmto deklarujeme, že appka využíva len štandardné šifrovanie operačného systému (HTTPS, Keychain, Face ID) a vyhneme sa papierovaniu s americkým úradom pre export.

### 1.5 App Privacy "Nutrition Labels" pre App Store Connect
V dotazníku v App Store Connect zaškrtávame:
- **Kontaktné údaje:** Meno a Email (zbierané cez Auth na účely prihlásenia a profilu).
- **Používateľský obsah:** Tréningové videá, hlasové nahrávky, choreografie (lokálne + voliteľne v cloude).
- **Identifikátory:** ID používateľa (UserID v Supabase).
- **Diagnostika & Pádové reporty:** Základné pádové logy.
- **Sledovanie (Tracking):** **NIE** (žiadne predávanie dát tretím stranám za účelom reklamného cielenia cez IDFA).

### 1.6 Ochrana pred škodlivým obsahom (Guideline 1.2 — User Generated Content)
- [ ] Naša appka má QR zdieľanie a spojenie s partnermi/priateľmi (`FriendsListView`).
- [ ] Pre 1:1 zdieľanie choreografií stačí mať v EULA / ToS klauzulu:
  - Zákaz nahrávania nevhodného, urážlivého alebo nezákonného materiálu.
  - V appke máme možnosť priateľa kedykoľvek odstrániť a vymazať zostavu.

---

## 2. 🔒 GDPR a Ochrana osobných údajov (Zber & Ukladanie)

### 2.1 Meno, E-mail a Profil
- [x] Právny základ: **Plnenie zmluvy / Poskytovanie služby** (používateľ si zakladá účet, aby mal prístup k svojim tanečným materiálom).
- [x] Heslá: Šifrované cez Supabase Auth (bcrypt). V našich Swift logoch ani lokálnom úložisku sa neukladá žiadne plain-text heslo.

### 2.2 Tréningové videá a Posture Analýza
- [x] **Je to biometrický údaj?** NIE. GDPR definuje biometrický údaj ako údaj získaný technickým spracovaním fyzických alebo fyziologických znakov, ktorý umožňuje alebo potvrdzuje **jednoznačnú identifikáciu fyzickej osoby** (napr. rozpoznávanie tváre, odtlačky prstov).
- [x] Naša posture analýza meria sklon ramien a držanie rámu tanečníka vo videu, neslúži na identifikáciu identity. Ide o bežný audiovizuálny osobný údaj.
- [ ] V Privacy Policy uviesť: Tréningové videá slúžia výhradne pre analýzu tanca používateľa. Sú uložené primárne na zariadení a pri cloud synchronizácii v privátnom úložisku používateľa.

### 2.3 Právo na výmaz a export dát
- [x] **Výmaz:** Implementovaný cez `deleteAccount()`.
- [x] **Export dát:** V `ProfileView.swift` máme funkciu `Exportovať zostavy (JSON)` aj export PDF materiálov, čím spĺňame právo na prenosnosť údajov (Data Portability).

### 2.4 DPA (Data Processing Agreement) so Supabase
- [ ] Supabase vystupuje ako sprostredkovateľ (Data Processor). V Supabase dashboarde v sekcii organizácie skontrolovať, či je odsúhlasené štandardné DPA (Data Processing Addendum) s doložkami EÚ (Standard Contractual Clauses).
- [ ] Skontrolovať región projektu (odporúčaný región: napr. `eu-central-1` Frankfurt).

---

## 3. 🛡️ Databáza a Row Level Security (RLS) — KRITICKÝ KROK

V súbore `Encore/SupabaseSecurityFix.sql` je zdokumentovaný aktuálny stav. RLS je zapnuté, ale pravidlá zatiaľ povoľujú prístup všetkým overeným používateľom (`using (true)`), pretože v tabuľkách historicky chýbal stĺpec `user_id`.

### Čo treba spraviť v Supabase SQL editore pred spustením pre verejnosť:
1. Pridať stĺpec vlastníctva:
   ```sql
   alter table public.routines add column if not exists user_id uuid references auth.users(id) default auth.uid();
   alter table public.figure_library_items add column if not exists user_id uuid references auth.users(id) default auth.uid();
   ```
2. Nahradiť politiku `using (true)` striktnou kontrolou identity:
   ```sql
   -- Používateľ vidí a upravuje IBA svoje vlastné zostavy
   create policy "users_manage_own_routines" on public.routines
   for all to authenticated
   using (auth.uid() = user_id)
   with check (auth.uid() = user_id);
   
   -- Používateľ vidí a upravuje IBA svoje vlastné figúry
   create policy "users_manage_own_figures" on public.figure_library_items
   for all to authenticated
   using (auth.uid() = user_id)
   with check (auth.uid() = user_id);
   ```
3. Otestovať cez SQL editor s anonymným kľúčom, že dotaz na cudzie dáta vráti `0 rows`.

---

## 4. 🎵 Autorské práva (Hudba, Videá, Názvy figúr)

### 4.1 Hudba v aplikácii — STAV: 100% BEZPEČNÉ ✅
- [x] **Metronóm:** `DanceMetronomeEngine.swift` neobsahuje žiadne pirátske ani licencované MP3 súbory. Zvukový klik sa generuje programovo v reálnom čase matematickou syntézou PCM sínusoidy do WAV buffera.
- [x] **Music Speed Trainer:** Appka nedistribuuje žiadne pesničky. Používateľ si cez systémový iOS `UIDocumentPicker` otvorí svoju vlastnú skladbu, ktorú vlastní na telefóne alebo v súboroch.
- [x] **Právne krytie:** V ToS bude uvedené: *"Aplikácia Encore neposkytuje hudobné nahrávky. Používateľ zodpovedá za legálnosť vlastných zvukových súborov prehrávaných v module Music Speed Trainer."*

### 4.2 "Idol" Porovnávanie a Záznamy zo seminárov
- [x] Pri porovnávaní dvoch videí na obrazovke používateľ nahráva video seba a porovnáva ho s videom trénera / vzoru.
- [ ] V ToS doplniť: *"Používateľ vyhlasuje, že disponuje potrebnými súhlasmi osôb zachytených na nahrávkach z workshopov a súťaží a že nahrávky používa výhradne na svoje súkromné študijné účely."*

### 4.3 Názvy tanečných figúr
- [x] Názvy ako *"Natural Spin Turn"*, *"Open Hip Twist"*, *"Telemark"* sú celosvetovo štandardizované tanečné termíny (WDSF, ISTD), ktoré nepodliehajú autorskoprávnej ochrane ani copyrightu. Každý tréner a tanečník ich môže voľne používať.

---

## 5. 🏆 SZTŠ / ksis.eu — Súťažné dáta a ochrana

V aplikácii Encore máme modul `CompetitionTrackerView`, ktorý importuje súťažné body a výsledky párov zo systému ksis.eu.

### 5.1 Ako to máme technicky zabezpečené v kóde:
- [x] Žiadny scraping nebeží agresívne z mobilu. Požiadavky idú cez kontrolovanú Supabase Edge Function (`ksis-import`).
- [x] V `CompetitionManager.swift` (riadok 212) je implementovaný striktný **Rate Limiting** (ochrana pred preťažením serverov ksis.eu).
- [x] Importujú sa iba **verejne dostupné výsledkové listiny**, ktoré SZTŠ zverejňuje pre verejnosť.

### 5.2 Právne roviny (Databázové právo vs. Zmluvné podmienky):
1. **Databázové právo EÚ (96/9/ES):** Samotné skóre z tanca a body sú športové fakty. Chránená môže byť štruktúra databázy, ale používateľ v Encore si vyhľadáva len výsledky svojho vlastného páru.
2. **Podmienky webu:** Prevádzkovateľ môže obmedziť robotický prístup.

### 5.3 Odporúčaná stratégia (Fair-play a partnerstvo):
- [ ] **Najlepšia cesta:** Odoslať oficiálny, priateľský e-mail na vedenie SZTŠ (`szts@szts.sk`):
  > *„Vážené vedenie SZTŠ, vyvíjame slovenskú mobilnú aplikáciu Encore zameranú na vzdelávanie a tréning slovenských tanečníkov spoločenských tancov. Aplikácia umožňuje tanečníkom evidovať si svoje výsledky a postupové body z ksis.eu pre osobný prehľad a prípravu na finále. Naším cieľom je popularizovať tanečný šport medzi mládežou. Radi by sme vás informovali o tomto projekte a overili možnosti oficiálneho partnerstva / API integrácie.“*
- Zväzy na toto takmer vždy reagujú pozitívne, pretože im to šetrí prácu a prináša modernú appku pre ich vlastných členov zadarmo.

---

## 6. 💳 Platby, Predplatné a DPH

- [ ] **iOS Aplikácia:** Všetky digitálne funkcie (napr. odomknutie pokročilej analýzy, cloud záloha) **musia** ísť cez Apple In-App Purchase (StoreKit).
  - **Obrovská výhoda:** Apple je v zmysle daňových zákonov *"Deemed Supplier"*. Apple sám fakturuje koncovému zákazníkovi, sám vyberá správnu DPH podľa krajiny používateľa a odvádza ju príslušnému daňovému úradu.
  - Tebe príde na účet čistá suma po odpočítaní Apple provízie a DPH.
- [ ] **Budúca webová verzia (Next.js / Stripe):**
  - Tu Apple nevystupuje ako sprostredkovateľ.
  - Pri predaji predplatného občanom v EÚ cez vlastný web je potrebné použiť Stripe Tax alebo systém OSS (One Stop Shop) na odvádzanie DPH v štátoch EÚ.
  - Pre začiatok (MVP) je preto oveľa jednoduchšie začať na iOS cez Apple IAP.

---

## 7. 📄 Zmluvné podmienky (ToS) a Zrieknutie sa zodpovednosti (Disclaimer)

Do podmienok používania aplikácie (Terms of Service) je potrebné zahrnúť tieto 3 kľúčové vety, ktoré ťa chránia pred akýmikoľvek žalobami či reklamáciami:

1. **Zdravotný disclaimer:**
   > *„Aplikácia Encore poskytuje tréningové nástroje a orientačné biomechanické postrehy. Nenahrádza certifikovaného trénera ani lekára. Cvičenie a tanec vykonávate na vlastné riziko. Prevádzkovateľ nenesie zodpovednosť za akékoľvek zranenia alebo škody na zdraví vzniknuté pri tréningu.“*
2. **Disclaimer k súťažným bodom:**
   > *„Výpočet postupových bodov a finálových umiestnení v aplikácii má informatívny charakter. Jediným oficiálnym a záväzným zdrojom výsledkov zostáva Slovenský zväz tanečného športu (SZTŠ) a systém ksis.eu.“*
3. **Vlastníctvo obsahu:**
   > *„Používateľ si ponecháva všetky práva duševného vlastníctva k nahrávkam, poznámkam a choreografiám, ktoré si do aplikácie nahrá.“*

---

## 🚀 ČO IDEME UROBIŤ HNEĎ (Konkrétne akčné kroky v projekte):

1. **Pridať `ITSAppUsesNonExemptEncryption` do `Info.plist`** (vyrieši otázku šifrovania v App Store).
2. **Pridať odkaz na Zásady ochrany osobných údajov a Podmienky používania do `ProfileView.swift`** (splnenie Guideline 5.1.1).
3. **Pripraviť SQL skript na sprísnenie RLS na `auth.uid() = user_id` v Supabase.**
