# Encore — Tanečná Aplikácia & Súťažný Denník KSIS

Encore je prémiová natívna iOS aplikácia pre tanečný šport (Standard & Latin) vytvorená v SwiftUI s backendom na Supabase.

---

## KSIS Súťažný Denník & Sledovanie Postupov (Fáza 1)

Encore importuje oficiálne výsledky súťaží zo slovenského tanečného portálu KSIS (`szts.ksis.eu`) do osobného súťažného denníka tanečníka s automatickým výpočtom postupových bodov a finálových umiestnení.

### Architektúra & Bezpečnostné Princípy
- **Edge Functions & Service Role:** Všetky zápisy, aktualizácie a mazania prebiehajú výhradne cez zabezpečené Supabase Edge Functions (`ksis-manage-couples`, `ksis-import`, `ksis-manage-results`).
- **Klient Iba na Čítanie (RLS):** Všetky tabuľky majú zapnuté striktné RLS (Row Level Security). Pre roly `anon` a `authenticated` sú príkazy `INSERT`, `UPDATE`, `DELETE` explicitne odvolané (`REVOKE`). Používateľ má prístup len k vlastným záznamom (`auth.uid() = user_id`).
- **Čestný User-Agent:** Každá požiadavka na KSIS odosiela transparentnú hlavičku `User-Agent: EncoreApp/1.0 (contact: jakubkalina05@gmail.com)`. Žiadne obchádzanie Cloudflare.
- **SSRF Ochrana:** Vstupné parametre `sutaz_id` a `couple_id` sú striktne validované ako kladné celé čísla. URL sa skladá výhradne na strane servera.
- **Ochrana Súkromia & GDPR:** Aplikácia nikdy neukladá ani nevracia celé HTML stránky ani mená cudzích tanečníkov. Ukladá sa výlučne riadok priradený k prepojenému páru používateľa.
- **Rate Limiting:** Atómový cooldown na úrovni databázy (10 sekúnd na pár, 30 sekúnd na IP/používateľa) s hlavičkou `Retry-After: N` a HTTP 429 pre zabránenie preťaženia servera KSIS.
- **Zdroj Pravdy:** Kumulatívny stav bodov a finále sa berie z oficiálneho zápisu KSIS (napr. `"89/5F"`). Importujú sa len oficiálne potvrdené výsledky (`is_official = true`).

---

## SZTŠ Gate Checklist (Pred Ostrou Prevádzkou)

Pred spustením ostrej prevádzky pre verejných používateľov musí byť splnený tento kontrolný zoznam:

- [x] **1. Čestný a identifikovateľný User-Agent:**
  - Všetky požiadavky na `szts.ksis.eu` nesú hlavičku `EncoreApp/1.0 (contact: jakubkalina05@gmail.com)`.
- [x] **2. RLS & Server-Side Ochrana:**
  - Tabuľky `user_couples`, `competition_results`, `advancement_rules`, `import_cooldowns` majú striktné RLS politiky.
  - Všetky mutácie prebiehajú výhradne cez Edge Functions s `service_role`.
- [x] **3. GDPR & Súhlas Partnera:**
  - Pri prepojení tanečného páru (`ksis-manage-couples`) sa vyžaduje explicitné potvrdenie súhlasu partnera so spracovaním súťažných údajov (`partner_consent: true`).
  - Žiadne citlivé ani cudzie osobné údaje z KSIS protokolov sa neukladajú do databázy.
- [x] **4. Rate Limiting & Cooldowny:**
  - 10 sekúnd na pár, 30 sekúnd na používateľa.
  - V aplikácii je implementovaný interaktívny odpočet a deaktivácia tlačidla pri HTTP 429.
- [x] **5. Mazanie Účtu (Právo na Výmaz):**
  - Kaskádové mazanie (`ON DELETE CASCADE`) na tabuľkách `user_couples` a `competition_results` pri zmazaní profilu používateľa.
- [ ] **6. Notifikácia Správcu KSIS / SZTŠ:**
  - Odoslať informačný e-mail správcovi KSIS s popisom účelu Encore (čítanie verejných protokolov pre osobný denník páru s rate limitom a kontaktným e-mailom).

---

## Spustenie a Vývoj

### Požiadavky
- macOS s Xcode 16+
- Supabase CLI (`supabase`)
- Deno 2.x (pre lokálne testy parsera: `deno test supabase/functions/_shared/ksis-parser.test.ts`)

### Lokálne Testovanie
```bash
# Spustenie testov parsera
deno test supabase/functions/_shared/ksis-parser.test.ts

# Nasadenie Edge Functions
supabase functions deploy ksis-manage-couples
supabase functions deploy ksis-import
supabase functions deploy ksis-manage-results
```
