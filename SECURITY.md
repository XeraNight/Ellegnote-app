# 🛡️ Encore Security, Privacy & Apple Wallet Pass Architecture

Tento dokument slúži ako oficiálny bezpečnostný manuál a architektonická referencia pre aplikáciu **Encore (iOS & Supabase)**. Popisuje všetky vrstvy zabezpečenia, ochranu osobných údajov tanečníkov, postup udelenia predplatného kamarátom a podrobný postup nastavenia certifikátov pre Apple Wallet.

---

## ⚡ 0. Ako udeliť kamarátom a VIP partnerom Studio Tier zadarmo

Keďže migračný skript `AdminAndEntitlements.sql` je spustený v Supabase, tabuľka `public.user_entitlements` je aktívna.

### A. Cez Supabase SQL Editor (Najrýchlejšie – 5 sekúnd):
1. Otvor [supabase.com](https://supabase.com) -> tvoj projekt -> **SQL Editor**.
2. Zadaj e-mail kamaráta a spusti tento dotaz:
```sql
INSERT INTO public.user_entitlements (user_id, tier, source, expires_at, notes)
VALUES (
    (SELECT id FROM auth.users WHERE email = 'kamarát@gmail.com'),
    'studio',
    'owner_grant',
    NULL, -- NULL = Doživotný prístup (Lifetime)
    'VIP Kamarát / Tanečný partner'
)
ON CONFLICT (user_id) DO UPDATE 
SET tier = 'studio', 
    source = 'owner_grant', 
    expires_at = NULL, 
    notes = EXCLUDED.notes,
    updated_at = now();
```
3. Keď kamarát otvorí appku, `SubscriptionManager.refreshEntitlements()` ihneď načíta tento záznam a odomkne mu **Studio tier** (všetky funkcie, neobmedzené zostavy, radar súperov, posture linky).

### B. Automatický God Mode pre teba (Majiteľ aplikácie):
V [SubscriptionManager.swift](file:///Users/jakub/Documents/New%20project/Encore/SubscriptionManager.swift) je výlučne tvoj hlavný e-mail:
```swift
public static let ownerEmails: Set<String> = [
    "jakubkalina05@gmail.com"
]
```
- **Hlavný účet (`jakubkalina05@gmail.com`)**: Má plný God-Mode, odomknuté všetky Studio funkcie a prístup do **Majiteľskej Konzoly** v Profile na udeľovanie predplatného kamarátom cez e-mail alebo Dancer ID.
- **Skúšobný účet (`jakubkali69420@gmail.com`)**: Nemá God-Mode. Správa sa ako bežný používateľ, čo ti umožňuje na 100% testovať nákupy cez StoreKit Sandbox, bezplatné obmedzenia a proces upgrade.

---

## 1. Architektúra bezpečnosti a ochrana osobných údajov

### A. Prísne Row Level Security (RLS) v Supabase
Všetky databázové tabuľky majú striktne zapnuté **Row Level Security (RLS)**. Žiadny používateľ, partner ani tréner nemôže získať prístup k cudzím údajom bez explicitného udelenia v tabuľke `connections`.
- **Routines & Canvas**: Každá choreografia a blok na plátne patrí autorovi (`user_id = auth.uid()`).
- **Zero-Delete Coach Policy (Zákaz mazania trénerom)**:
  Tréner a partner majú cez RLS povolené choreografiu prezerať (`SELECT`) a upravovať figúry či pridávať technické poznámky (`UPDATE`). **Mazanie (`DELETE`) je na úrovni databázovej politiky povolené VÝHRADNE autorovi zostavy**. Tréner ani partner nemôžu žiakovi zostavu zmazať, ani keby modifikovali sieťovú požiadavku.
- **Auditing zmien**: Pri každej úprave zostavy trénerom sa ukladá podpis `last_modified_by = "Meno Trénera (Tréner)"`.

### B. Izolácia identity (Verejné KSIS ID / Dancer ID vs. Interné UUID)
- V aplikácii ani vo verejných API sa **nikdy nezobrazuje ani neodosiela interné databázové UUID** ani súkromný e-mail používateľa.
- Pre verejnú identifikáciu slúži:
  1. **KSIS ID** – oficiálne registračné číslo tanečníka v zväze (ak je zadané).
  2. **Dancer ID (napr. `DNC-8492`)** – kryptograficky generovaný unikátny 4-ciferný kód priradený k profilu.
- Vyhľadávanie používateľov prebieha cez zabezpečenú RPC funkciu `search_dancers(query)`, ktorá vracia len bezpečné verejné atribúty (meno, klub, Dancer ID, avatar).

### C. Opaque Expiring Tokens (Nehádateľné časové tokeny pre QR a linky)
- **Žiadne osobné údaje v QR kóde**: Osobný QR kód na karte neobsahuje meno, klub ani ID.
- Obsahuje iba náhodný kryptografický reťazec s vysokou entropiou (`tok_` + 128-bitový náhodný hex kód vygenerovaný cez `crypto.getRandomValues`).
- **Expirácia a okamžitá obnova**: Token má obmedzenú platnosť (predvolene 7 dní). Ak tanečník ťukne na karte na **„Obnoviť QR“**, predchádzajúci token je v databáze okamžite označený ako `revoked_at = now()`. Starý kód už nikto nemôže použiť.
- **Obojstranné potvrdenie (Žiadne automatické pridanie)**:
  Naskenovaním kódu sa priateľstvo **nepridá automaticky**. Druhej strane sa otvorí zabezpečený modal sheet s vizitkou a možnosťami **[Prijať pozvánku]** alebo **[Odmietnuť]**.
- **Ochrana hraničných stavov**:
  - Pokus o pridanie samého seba je zablokovaný na serveri aj v klientovi.
  - Pokus o duplicitné odoslanie pozvánky zobrazí zrozumiteľnú hlášku bez duplikovania záznamov.
  - Expirovaný alebo zrušený token zobrazí informáciu o potrebe nového kódu.
  - Blokovaní používatelia dostanú neutrálne systémové hlásenie bez prezradenia existencie účtu.

---

## 2. Bezpečnostná architektúra Apple Wallet (PassKit)

### Prečo NIE certifikáty v aplikácii:
Apple Wallet vyžaduje, aby každý digitálny preukaz (`.pkpass`) bol podpísaný certifikátom vydaným autoritou Apple.
- **Klientsky kód v iOS aplikácii NESMIE obsahovať privátne kľúče ani certifikáty**. Ak by boli v aplikácii, ktokoľvek by ich mohol reverzným inžinierstvom získať a podpisovať falošné lístky v tvojom mene.
- Preto sa `.pkpass` generuje **výhradne na serveri** (v Supabase Edge Function `generate-wallet-pass`).
- Server najprv overí identitu prihláseného používateľa cez Supabase Auth JWT token. Používateľ si môže vygenerovať lístok **len pre svoj vlastný profil**.

### Apple Pass Web Service (Automatické push aktualizácie):
Preukaz v Apple Peňaženke podporuje automatické aktualizácie podľa oficiálnej špecifikácie Apple PassKit Web Service:
- Keď si používateľ pridá preukaz do Peňaženky, iOS zariadenie zaregistruje svoj `pushToken` cez endpoint:
  `POST /functions/v1/wallet-pass-service/v1/devices/{deviceId}/registrations/{passTypeId}/{serialNumber}`
- Pri zmene údajov v profile (klub, tanečné kategórie, nové KSIS ID) server odošle tichý APNs push a Apple Wallet na pozadí stiahne aktualizovanú kartu bez toho, aby musel používateľ čokoľvek robiť.

---

## 3. Návod: Čo stiahnuť z Apple Portálu a ako nastaviť Supabase

Keď budeš pripravený nasadiť podpisovanie pre Apple Peňaženku, postupuj podľa týchto krokov:

### Krok 1: Vytvorenie Pass Type ID v Apple Developer Portáli
1. Prihlás sa na [developer.apple.com/account](https://developer.apple.com/account).
2. Choď do **Certificates, Identifiers & Profiles** -> **Identifiers**.
3. Klikni na modré tlačidlo **(+)** a vyber **Pass Type IDs**.
4. Zadaj:
   - **Description**: `Encore Member Card`
   - **Identifier**: `pass.com.jakub.encore` (alebo `pass.com.encore.dance`)
5. Potvrď kliknutím na **Register**.

### Krok 2: Vytvorenie a export podpisového certifikátu
1. V zozname Identifiers klikni na novovytvorené **Pass Type ID**.
2. Klikni na **Create Certificate**.
3. Na svojom Macu otvor aplikáciu **Keychain Access (Kľúčenka)**:
   - V menu: *Keychain Access -> Certificate Assistant -> Request a Certificate from a Certificate Authority...*
   - Zadaj svoj e-mail a zvoľ **Saved to disk**. Vznikne súbor `CertificateSigningRequest.certSigningRequest`.
4. Nahraj tento súbor do Apple portálu a stiahni vygenerovaný `pass.cer`.
5. Dvakrát klikni na stiahnutý `pass.cer`, čím sa naimportuje do Kľúčenky.
6. V Kľúčenke nájdi certifikát `Pass Type ID: pass.com.jakub.encore`, klikni naň pravým tlačidlom a zvoľ **Exportovať**:
   - Formát: **Personal Information Exchange (.p12)**
   - Nastav bezpečné heslo (alebo nechaj prázdne) a ulož ako `pass.p12`.

### Krok 3: Stiahnutie Apple WWDR CA certifikátu
1. Otvor [Apple PKI](https://www.apple.com/certificateauthority/).
2. Stiahni certifikát **Worldwide Developer Relations - G4 (alebo G6)**:
   - Súbor: `AppleWWDRCAG4.cer`.

### Krok 4: Konverzia do formátu PEM cez Terminál
V priečinku, kde máš stiahnuté súbory, spusti v Termináli tieto príkazy:

```bash
# 1. Konverzia certifikátu z .p12 do cert.pem
openssl pkcs12 -in pass.p12 -clcerts -nokeys -out pass_cert.pem

# 2. Konverzia privátneho kľúča z .p12 do key.pem
openssl pkcs12 -in pass.p12 -nocerts -nodes -out pass_key.pem

# 3. Konverzia Apple WWDR z .cer do wwdr.pem
openssl x509 -inform der -in AppleWWDRCAG4.cer -out wwdr.pem
```

### Krok 5: Nahratie certifikátov do Supabase Secrets
Spusti nasledujúce príkazy cez Supabase CLI (alebo zadaj do webového rozhrania Supabase v *Project Settings -> Secrets*):

```bash
# Nahratie identifikátorov
supabase secrets set APPLE_PASS_TYPE_ID="pass.com.jakub.encore"
supabase secrets set APPLE_TEAM_ID="2MD5BS4DLM"

# Nahratie certifikátov
supabase secrets set APPLE_PASS_CERT="$(cat pass_cert.pem)"
supabase secrets set APPLE_PASS_KEY="$(cat pass_key.pem)"
supabase secrets set APPLE_WWDR_CERT="$(cat wwdr.pem)"
```

---

## 4. Universal Links & Associated Domains v Xcode

Pre správne fungovanie prepojení dotykom telefónov a skenovaním QR kódov:
1. Súbor `web/src/app/.well-known/apple-app-site-association/route.ts` už obsahuje záznam:
   ```json
   {
     "applinks": {
       "apps": [],
       "details": [
         {
           "appID": "2MD5BS4DLM.com.jakub.encore",
           "paths": ["/add*", "/add/*", "/u/*"]
         }
       ]
     }
   }
   ```
2. V Xcode v targete **Encore** v záložke **Signing & Capabilities** skontroluj, že je zapnutá schopnosť **Associated Domains** a obsahuje doménu:
   `applinks:encore-app.vercel.app`

---

## 5. Zhrnutie bezpečnostného statusu aplikácie

| Oblasť | Riešenie | Úroveň zabezpečenia |
| :--- | :--- | :--- |
| **Ochrana údajov v databáze** | PostgreSQL RLS na všetkých tabuľkách | 🟢 Banková úroveň (autorizácia na úrovni DB jadra) |
| **Mazanie zostáv trénermi** | Tréner má povolený len SELECT a UPDATE, DELETE striktne blokovaný | 🟢 100% ochrana pred nechceným zmazaním choreografie |
| **Súkromie používateľov** | Zobrazuje sa len verejné KSIS ID / Dancer ID, nikdy nie interné UUID ani e-mail | 🟢 GDPA / Apple App Store Privacy Compliant |
| **QR kódy a pozvánky** | Opaque Token s vysokou entropiou, 7-dňovou platnosťou a možnosťou okamžitej obnovy | 🟢 Ochrana proti brute-force a spamu |
| **Apple Wallet podpisovanie** | Kryptografické podpisovanie prebieha výhradne na serveri v Edge Function | 🟢 Kľúče nie sú prítomné v klientskom kóde |
| **Dotyk telefónov** | Natívny iOS 17 Proximity AirDrop gesture cez systémový Share Sheet | 🟢 Žiadne rušivé povolenia na lokálnu sieť ani sledovanie |
