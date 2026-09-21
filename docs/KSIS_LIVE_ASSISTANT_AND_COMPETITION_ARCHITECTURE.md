# 🏆 KSIS Live Assistant & Súťažný Denník – Architektonická Špecifikácia
*(Verzia 7 – Final pred Fázou 0, review 9/10)*

---

## 📌 1. Overené Fakty o KSIS

| Vlastnosť | Zistenie |
|---|---|
| URL vzor | `szts.ksis.eu/sutaz.php?sutaz_id=12094` |
| Cloudflare | ✅ Aktívne. Challenge = 200/503 s „Just a moment..." |
| ETag / 304 | ❌ Nepodporuje |
| HTML štruktúra | Bootstrap 3 tabuľka |
| Identifikácia páru | KSIS `couple_id` (stabilné) |
| Umiestnenie | Môže byť rozsah: „7.–9." → ukladať **text aj číslo** |
| Nebodovacie | Nemajú kumulatívny stav `89/5F` → nullable |
| **Neoverené** | Medzivýsledky, skupiny, postup – nemáme live HTML |
| **Neoverené** | Cloudflare vs. Supabase IPs – **Fáza 0** |

---

## ⚠️ 2. Tvrdé Pravidlá

### RLS & Prístup – Hlavný Princíp
> **Klient NIKDY nepíše priamo do tabuliek cez Supabase API.** Všetky zápisy idu cez Edge Functions alebo RPC. RLS policies sú len SELECT (read) pre authenticated. INSERT/UPDATE/DELETE len cez `service_role`.

| Tabuľka | Klient (authenticated) | Server (service_role) |
|---|---|---|
| `user_couples` | SELECT own | INSERT/UPDATE/DELETE (cez Edge Function) |
| `live_subscriptions` | SELECT own | INSERT/UPDATE/DELETE (cez Edge Function) |
| `live_states` | SELECT own | INSERT/UPDATE (worker) |
| `competition_results` | SELECT own (not deleted) | INSERT/UPDATE (import EF) |
| `import_cooldowns` | žiadny prístup | INSERT/UPDATE |
| `worker_lock` | žiadny prístup | INSERT/UPDATE |
| `advancement_rules` | SELECT all | admin only |

### Sieť & Bezpečnosť
- **Poctivý User-Agent:** `EncoreApp/1.0 (kontakt: ${KSIS_CONTACT_EMAIL})`. Env var.
- **Len server komunikuje s KSIS.**
- **SSRF ochrana:** Len číselné ID.
- **Žiadne obchádzanie Cloudflare.**
- **Edge Functions sú verejné URL:** Worker chránený `CRON_SECRET` (uložený vo **Vault**, nie v texte cron úlohy). Porovnanie v **konštantnom čase** (`timingSafeEqual`). Connectivity test chránený tajnou hlavičkou + zmazať po použití.
- **Nikdy nelogovať HTML ani mená.** Len error kódy, HTTP status, sutaz_id.

### Import
- **Rate limit:** Max 1 import / 60s na user. Min 30s na `sutaz_id` (globálne).
- **Atomický rate limit:** Jeden `INSERT ... ON CONFLICT ... WHERE last_import_at < now() - interval '30s'`. Nie „najprv check, potom write".
- **Hromadný import po súťaži:** 50 tanečníkov v hale → väčšina dostane 429. Response: `429 + Retry-After` header s náhodným oneskorením. iOS appka: retry s random jitter (5–30s).
- **Import len po isOfficial = true.**
- **Import robí server.** Klient posiela len ID.
- **Nesmie oživiť soft-deleted výsledok** bez explicitnej akcie.
- **Umiestnenie:** Ukladať `placement_text` (TEXT, napr. „7.–9.") aj `placement` (INT, napr. 7).

### Couple Identity
- **Sebadeklarácia.** Max 2 páry na user (enforced v Edge Function).
- **Mäkká kontrola:** Server porovná meno z KSIS s profilom **bez diakritiky** (`normalize('NFD').replace(/[\u0300-\u036f]/g, '')`). Warning ak nesedí, nie block.
- **Žiadny vyhľadávací endpoint podľa mena.** Používateľ vloží `par.php?id=...` link.

### Live Subscriptions (Fáza 2)
- Max 2 aktívne. Auto-expirácia 12h. FK na `user_couples`.
- **Zápis cez Edge Function**, nie priamo z klienta.

### Worker Lock (Fáza 2)
- `run_id` pre bezpečné uvoľnenie.
- **Predlžovanie zámku** ak beh trvá dlhšie (viac súťaží).
- **Paralelné sťahovanie** s limitom (max 3 concurrent fetches).
- pg_cron s `pg_net` (overiť vo Fáze 0 či 30s interval funguje).

### APNs (Fáza 2)
- Provider JWT cache, refresh max 1× / 20 min.
- `push_environment` (sandbox/production) uložené s tokenom.
- 410 / BadDeviceToken → deaktivácia.
- Po finále: end event.
- Alert len pri zmene `state_hash`.
- **ContentState:** Žiadne `Date` typy (len String, Int). Pod 4 KB. Pridať `timestamp` (String ISO), `event` (String), `staleDate` (String ISO).
- **Appka v popredí** spúšťa Live Activity. Token update loop.

### Realtime (Fáza 2)
- **Správne poradie:** Subscribe PRVÉ, fetch POTOM, merge podľa `updated_at`. Nie naopak (medzera).

### GDPR & Legal
- Ukladáme len vlastný pár. Nikdy celé HTML, cudzie mená, deti.
- **Súhlas partnera** ak ukladáme jeho meno → checkbox v onboardingu.
- **Privacy policy** pred TestFlight.
- **Mazanie účtu** (Apple requirement) → cascade delete.

### 🚪 SZTŠ Gate
> **Bez odpovede od SZTŠ žiadny externý TestFlight ani verejné spustenie.**
- Kontaktovať SZTŠ / správcu KSIS pred ostrým testovaním s ľuďmi.
- Ponúknuť partnerskú integráciu, odkázať na poctivý User-Agent.
- Ak nedostaneme súhlas: feature ostane internal-only alebo sa zruší.

---

## 📜 3. Overené Stavy

| Stav | Overený? |
|---|---|
| `not_published` | ✅ |
| `final_placement` | ✅ |
| `advanced` | ❓ Až po live HTML |
| `eliminated` | ❓ Až po live HTML |

**Kritérium pre Fázu 2:** „Ak je z HTML vidieť postup pred koncom súťaže (aspoň `advanced` / `eliminated`), ideme ďalej. Ak nie, Fáza 2 sa nerobí."

**Plán na získanie live HTML:** Uložiť stránky z prehliadača počas najbližšej živej súťaže po každom kole (ŠTT, LAT, jedna nebodovaná). Nahradiť reálne mená pred commitom.

---

## 📜 4. JSON Kontrakt

```typescript
type CoupleStatus = "not_published" | "advanced" | "eliminated" | "final_placement"

interface KSISCoupleState {
  sutazId: number
  coupleId: number
  eventName: string
  categoryName: string | null
  date: string | null
  place: string | null
  advancementKey: string | null
  coupleCount: number | null
  bib: string | null
  coupleName: string
  club: string | null
  currentRound: string | null
  status: CoupleStatus
  isOfficial: boolean
  placementText: string | null  // "7.–9."
  placement: number | null      // 7
  pointsEarned: number | null
  cumulativeStats: string | null  // nullable (nebodovacie)
  cumulativePoints: number | null
  cumulativeFinals: number | null
  stateHash: string
  fetchedAt: string
}
```

---

## 🏗️ 5. Architektúra

```
Supabase Edge Functions
├── _shared/
│   ├── ksis-parser.ts
│   └── ksis-types.ts
├── ksis-connectivity-test/   ← Fáza 0 (tajná hlavička, zmazať!)
├── ksis-import/              ← Fáza 1
├── ksis-manage-couples/      ← Fáza 1 (CRUD user_couples)
└── ksis-worker/              ← Fáza 2 (CRON_SECRET z Vault)
```

---

## 📊 6. SQL

```sql
-- ══════════════════════════════════════════
-- user_couples: Sebadeklarácia. Max 2 (enforced v EF).
-- Klient: len SELECT. Zápis cez Edge Function.
-- ══════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.user_couples (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  couple_id INT NOT NULL,
  partner_name TEXT NOT NULL,
  partner_consent BOOLEAN DEFAULT false,
  discipline TEXT CHECK (discipline IN ('STT', 'LAT', '10T')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, couple_id)
);
ALTER TABLE public.user_couples ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users read own couples" ON public.user_couples
  FOR SELECT TO authenticated USING (user_id = auth.uid());
-- No INSERT/UPDATE/DELETE policy → service_role only (Edge Function)

-- ══════════════════════════════════════════
-- competition_results: Import výsledkov.
-- Klient: SELECT own + UPDATE is_deleted. Zápis cez EF.
-- ══════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.competition_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sutaz_id INT NOT NULL,
  couple_id INT NOT NULL,
  event_name TEXT NOT NULL,
  category_name TEXT,
  discipline TEXT CHECK (discipline IN ('STT', 'LAT', '10T')),
  date DATE,
  place TEXT,
  couple_count INT,
  placement INT,
  placement_text TEXT,            -- "7.–9."
  points_earned INT,
  cumulative_stats TEXT,          -- nullable (nebodovacie)
  cumulative_points INT,
  cumulative_finals INT,
  is_final BOOLEAN DEFAULT false,
  season TEXT,
  notes TEXT,
  is_deleted BOOLEAN DEFAULT false,
  imported_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, sutaz_id, couple_id)
);
ALTER TABLE public.competition_results ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users read own results" ON public.competition_results
  FOR SELECT TO authenticated
  USING (user_id = auth.uid() AND is_deleted = false);
-- Soft delete: len is_deleted, nič iné
CREATE POLICY "Users soft-delete own" ON public.competition_results
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid() AND is_deleted = true);
-- No INSERT policy → service_role only

-- ══════════════════════════════════════════
-- advancement_rules: Read-only
-- ══════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.advancement_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category TEXT NOT NULL,
  from_class TEXT NOT NULL,
  to_class TEXT NOT NULL,
  required_points INT NOT NULL,
  required_finals INT NOT NULL,
  notes TEXT,
  updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.advancement_rules ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated reads rules" ON public.advancement_rules
  FOR SELECT TO authenticated USING (true);

INSERT INTO public.advancement_rules (category, from_class, to_class, required_points, required_finals, notes)
VALUES ('adults', 'D', 'C', 200, 5, 'Overiť voči aktuálnym pravidlám SZTŠ 2026')
ON CONFLICT DO NOTHING;

-- ══════════════════════════════════════════
-- import_cooldowns: Rate limiting. RLS on, no policy.
-- ══════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.import_cooldowns (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sutaz_id INT NOT NULL,
  last_import_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, sutaz_id)
);
ALTER TABLE public.import_cooldowns ENABLE ROW LEVEL SECURITY;

-- ══════════════════════════════════════════
-- FÁZA 2 TABUĽKY (vytvoriť až pri implementácii)
-- ══════════════════════════════════════════

-- live_subscriptions: Max 2 aktívne. Zápis cez EF.
CREATE TABLE IF NOT EXISTS public.live_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  couple_id INT NOT NULL,
  sutaz_id INT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  push_token TEXT,
  push_environment TEXT CHECK (push_environment IN ('sandbox', 'production')),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '12 hours'),
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, sutaz_id, couple_id),
  CONSTRAINT fk_couple FOREIGN KEY (user_id, couple_id)
    REFERENCES public.user_couples(user_id, couple_id)
);
ALTER TABLE public.live_subscriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users read own subs" ON public.live_subscriptions
  FOR SELECT TO authenticated USING (user_id = auth.uid());
-- No INSERT/UPDATE/DELETE → service_role only (Edge Function)

-- live_states: user_id priamo. Cleanup 24h. Worker only.
CREATE TABLE IF NOT EXISTS public.live_states (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sutaz_id INT NOT NULL,
  couple_id INT NOT NULL,
  event_name TEXT,
  category_name TEXT,
  date DATE,
  place TEXT,
  advancement_key TEXT,
  couple_count INT,
  bib TEXT,
  couple_name TEXT,
  club TEXT,
  current_round TEXT,
  status TEXT NOT NULL DEFAULT 'not_published'
    CHECK (status IN ('not_published', 'advanced', 'eliminated', 'final_placement')),
  is_official BOOLEAN DEFAULT false,
  placement INT,
  placement_text TEXT,
  points_earned INT,
  cumulative_stats TEXT,
  cumulative_points INT,
  cumulative_finals INT,
  state_hash TEXT,
  fetched_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, sutaz_id, couple_id)
);
ALTER TABLE public.live_states ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users read own states" ON public.live_states
  FOR SELECT TO authenticated USING (user_id = auth.uid());

-- worker_lock: RLS on, no policy.
CREATE TABLE IF NOT EXISTS public.worker_lock (
  id TEXT PRIMARY KEY DEFAULT 'ksis_worker',
  locked_until TIMESTAMPTZ,
  run_id TEXT
);
ALTER TABLE public.worker_lock ENABLE ROW LEVEL SECURITY;
INSERT INTO public.worker_lock (id, locked_until, run_id)
VALUES ('ksis_worker', NULL, NULL)
ON CONFLICT DO NOTHING;
```

---

## 🗺️ 7. Fázový Plán

### 🔴 FÁZA 0: Connectivity Test (30 min)
1. Deploy `ksis-connectivity-test` (tajná hlavička!)
2. Fetch KSIS + test cheerio v Deno + (bonus) HTTP/2 APNs + pg_cron 30s s pg_net
3. HTML vrátiť v response, uložiť z terminálu, nahradiť mená
4. **Zmazať funkciu** po teste

### 🟢 FÁZA 1: Parser + Import + MVP Denník
- `_shared/ksis-parser.ts`, `ksis-import/`, `ksis-manage-couples/`
- iOS: `CompetitionModels.swift`, `CompetitionManager.swift`, `CompetitionTrackerView.swift`
- Úprava `ProfileView.swift`

### 🟡 FÁZA 2: Live (AK z HTML vidieť postup)
- Worker, Realtime, Dynamic Island, APNs
- Rozhodnutie až po Fáze 1 + live HTML fixturách

### 🚪 SZTŠ Gate
- Kontakt pred externým TestFlight
- Privacy policy + mazanie účtu + partner consent
