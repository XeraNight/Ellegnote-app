# 💃 ENCORE — Tanečný Asistent & Choreografický Systém
### *Oficiálna dokumentácia a architektonický rozcestník*

Encore je prémiová natívna iOS aplikácia (SwiftUI + SwiftData + Supabase) navrhnutá pre súťažných tanečníkov (Standard & Latin), trénerov a tanečné kluby. 

Hlavným poslaním Encore je **zrýchliť progres tanečníka a odstrániť stratu času** — umožniť po lekcii za 5 sekúnd zapísať alebo nadiktovať poznámky k figúre, priradiť video a nestratiť priestorovú orientáciu na tanečnom parkete.

---

## 🧭 Prehľad Dokumentácie (Rozcestník pre Vývoj & Claude)

Pre maximálny prehľad je projekt rozdelený do špecializovaných dokumentov:

| Dokument | Účel & Obsah |
| :--- | :--- |
| **[`app.md`](file:///Users/jakub/Documents/New%20project/app.md)** | **Kompletný stav kódu a architektúra:** Čo všetko je v appke hotové, ako funguje jadro (Core Loop), prehľad obrazoviek, opravené chyby (mikrofón, hit-testing). |
| **[`LEGAL_AND_COMPLIANCE_CHECKLIST.md`](file:///Users/jakub/Documents/New%20project/LEGAL_AND_COMPLIANCE_CHECKLIST.md)** | **App Store Release & Právna ochrana:** Apple Developer účet, TestFlight, StoreKit 2 platby, GDPR, riziká obrázkov z Pinterestu a ich legálna náhrada. |
| **[`BRAND_GUIDELINES.md`](file:///Users/jakub/Documents/New%20project/BRAND_GUIDELINES.md)** | **Brand & Dizajnový systém:** Farby (Obsidian, Gold, Velvet Crimson), typografia, UI komponenty, filozofia "Jedna hlavná vec" a UI/UX pravidlá. |
| **[`SECURITY.md`](file:///Users/jakub/Documents/New%20project/SECURITY.md)** | **Bezpečnosť & Supabase:** RLS pravidlá, **ako grantnúť kamarátom Studio tier zadarmo cez SQL**, Apple Wallet certifikáty a ochrana dát. |
| **[`MOZNE_CHYBY.md`](file:///Users/jakub/Documents/New%20project/MOZNE_CHYBY.md)** | **Register 90 zraniteľných scenárov:** Riešenie pádov, plného disku, offline režimu, konfliktov audia a stresových situácií na súťaži. |
| **[`docs/DEVOPS_AND_ANALYTICS_PLAYBOOK.md`](file:///Users/jakub/Documents/New%20project/docs/DEVOPS_AND_ANALYTICS_PLAYBOOK.md)** | **PostHog Analytika & Monitoring:** Sledovanie používateľov, konverzie predplatného, pádové logy a škálovanie na 1000+ používateľov. |

---

## ⚡ Rýchly Manuál: Čo urobiť teraz

### 1. Ako grantnúť kamarátovi Studio Tier (Zadarmo):
V Supabase SQL Editore stačí spustiť:
```sql
INSERT INTO public.user_entitlements (user_id, tier, source, expires_at, notes)
VALUES (
    (SELECT id FROM auth.users WHERE email = 'kamarát@email.com'),
    'studio',
    'owner_grant',
    NULL, -- Doživotne (Lifetime)
    'Kamarát / VIP tanečník'
)
ON CONFLICT (user_id) DO UPDATE 
SET tier = 'studio', source = 'owner_grant', expires_at = NULL, notes = EXCLUDED.notes;
```

### 2. Ako testovať nákupy za 0 € na tvojom iPhone:
1. V Xcode otvor projekt a zvoľ schému **Encore**.
2. Vďaka pripojenému `EncoreProducts.storekit` sa všetky nákupy v Simulatori aj na pripojenom kábli správajú ako bezplatné testovacie nákupy.
3. Pre reálny TestFlight a App Store je nutné aktivovať **Apple Developer Program ($99/rok)**.

---

## 🛠️ Technický Stack
- **iOS:** Swift 5.10 / Swift 6, SwiftUI, SwiftData, AVFoundation, Speech, StoreKit 2, PassKit.
- **Backend:** Supabase (PostgreSQL, Row Level Security, Auth, Storage, Edge Functions v Deno).
- **Web:** Next.js 15, TypeScript, Tailwind CSS, Vercel.
- **Analytika:** PostHog EU, Xcode Organizer.
