# Encore DevOps & Analytics Playbook

> Živý manuál pre správu, monitoring a support aplikácie Encore.  
> Aktualizuj pri každom novom release alebo zmene procesu.

---

## 🚀 Setup (Jednorazové kroky – urobiť pred prvým release)

### 1. PostHog (Analytika iOS + Web)

1. Choď na [posthog.com](https://posthog.com/) → Vytvor si zadarmo účet
2. Vytvor nový **Project** s názvom `Encore`
3. Zvoľ **EU Cloud** (server: `eu.posthog.com`) → GDPR compliant
4. Skopíruj **Project API Key**

**iOS (Swift):**
- Otvor Xcode → File → Add Package Dependencies
- Vlož URL: `https://github.com/PostHog/posthog-ios`
- Pridaj package do targetu `Encore`
- V `AnalyticsManager.swift` odkomentuj `import PostHog` a celý blok v `setup()`
- Vlož API Key do `Info.plist` ako `POSTHOG_API_KEY`

**Web (Next.js):**
- `posthog-js` je už nainštalovaný
- Pridaj do `.env.local` (lokál) a Vercel Dashboard (produkcia):
  ```
  NEXT_PUBLIC_POSTHOG_KEY=phc_xxxxxxxxxxxxxxxxxxxx
  NEXT_PUBLIC_POSTHOG_HOST=https://eu.posthog.com
  ```

### 2. Better Stack (Web Logy + Uptime)

1. Choď na [betterstack.com](https://betterstack.com/) → Registrácia (zadarmo)
2. **Logs** → Create Source → Node.js → Skopíruj **Source Token**
3. Pridaj do `.env.local` a Vercel:
   ```
   LOGTAIL_SOURCE_TOKEN=xxxxxxxxxxxxxxxx
   ```
4. **Uptime** → Create Monitor:
   - URL: tvoja Vercel URL (napr. `https://encore-web.vercel.app`)
   - Check interval: 3 minúty
   - Alert: Email, keď web padne na 2+ minúty

### 3. Formspree (Kontaktný formulár)

1. Choď na [formspree.io](https://formspree.io/) → Registrácia (zadarmo, 50 správ/mesiac)
2. New Form → Nastav **Email** (kam prídu správy)
3. Skopíruj Form ID (napr. `xpzvkrqb`)
4. V `web/src/app/support/page.tsx` nahraď:
   ```tsx
   const FORMSPREE_ENDPOINT = 'https://formspree.io/f/YOUR_FORMSPREE_ID'
   // nahraď:
   const FORMSPREE_ENDPOINT = 'https://formspree.io/f/xpzvkrqb'
   ```

### 4. Apple Xcode Organizer (iOS Crash Reporting)

- **Žiadny setup!** Automaticky dostupný po prvom App Store Archive.
- Prístup: **Xcode → Window → Organizer → Crashes**
- Dostupné po schválení prvého buildu a dostatočnom počte používateľov (cca 25+ zariadení)

---

## 📊 Ako čítať PostHog Dashboard

### Kľúčové metriky (Daily check)
| Metrika | Kde nájdeš | Čo sledovať |
|---|---|---|
| Počet aktívnych používateľov | Dashboard → Insights | Trend rastu |
| Najpopulárnejší tanec | Events → `dance_card_viewed` → breakdown by `dance_name` | Waltz vs Samba |
| Počet otvorení Zrkadla | Events → `mirror_opened` | Kľúčová funkcia! |
| Login metóda | Events → `auth_signin_apple` vs `auth_signin_google` | Čo preferujú |
| Vytváranie zostáv | Events → `routine_created` → breakdown by `dance_category` | Standard vs Latin |

### Funnel Analysis
Vytvor Funnel: `auth_signin_*` → `routine_created` → `canvas_opened`
→ Vidíš, koľko percent ľudí sa prihlási a vytvorí prvú zostavu.

---

## 🐛 Ako reagovať na Crash Logy (Xcode Organizer)

1. **Zisti, kedy sa crash objavil** – Xcode Organizer ukazuje timeline pádov
2. **Otvor crash report** – klikni na crash → uvidíš symbolicated stack trace
3. **Identifikuj súbor a riadok** – napr. `ProfileView.swift:340`
4. **Priorizuj podľa počtu zariadení** – crash na 1 zariadení → nízka priorita, na 10+ → vysoká

### Postup opravy:
```
1. Reprodukuj crash lokálne v Simulátore
2. Oprav kód
3. Otestuj na fyzickom iPhone
4. Zvýš Build Number v Xcode (napr. 1 → 2)
5. Archive → Distribute → TestFlight → čakaj na schválenie (~15 min)
6. Sleduj Organizer, či sa crash opakuje
```

---

## 📋 Release Checklist

### Pred Archive v Xcode:
- [ ] Verzia `CFBundleShortVersionString` správne zvýšená (napr. 1.0 → 1.1)
- [ ] Build Number `CFBundleVersion` zvýšený o 1
- [ ] Kód sa kompiluje bez chýb (`⌘+B`)
- [ ] Otestovaný na fyzickom iPhone (nie len Simulátor)
- [ ] Skontrolovaná sekcia Profil → Údržba a Dáta (funkčné tlačidlá)
- [ ] Sync funguje (prihlásenie → zmena na canvase → viditeľné na webe)

### Pre App Store Submit (ostré):
- [ ] Screenshots sú aktuálne (1290 × 2796 px pre iPhone 14 Pro Max)
- [ ] App Store Connect → Privacy Policy URL nastavená
- [ ] App Store Connect → Support URL nastavená
- [ ] Testovací účet pre Apple Reviewera existuje a heslo je správne
- [ ] App Privacy Nutrition Label vyplnená v App Store Connect

---

## 📬 Support Workflow (Formspree → Triáž)

| Kategória | SLA | Akcia |
|---|---|---|
| `bug` (chyba) | 48 hodín | Reprodukovať → opraviť → TestFlight patch |
| `feature` (návrh) | 1 týždeň | Uložiť do zoznamu features |
| `account` (účet) | 24 hodín | Preveriť cez Supabase Dashboard |
| `other` | 72 hodín | Odpovedz emailom |

---

## 🔒 GDPR Data Requests

### Žiadosť o vymazanie (Right to Erasure):
1. Používateľ môže sám zmazať účet cez `Profil → Zmazať účet`
2. Ak žiada emailom: Supabase Dashboard → Authentication → Users → Delete User
3. Potvrdiť emailom do 30 dní

### Žiadosť o export dát (Right to Access):
1. Používateľ môže exportovať cez `Profil → Exportovať zostavy (JSON)`
2. Pre manuálny export:
```sql
SELECT * FROM public.routines WHERE user_id = 'uuid-here';
SELECT * FROM public.profiles WHERE id = 'uuid-here';
```

---

## 🌐 Better Stack Uptime

- Nastav notifikácie: Email pri výpadku > 2 minúty
- Sleduj Response Time grafy → ak priemerný response > 3s, prever Vercel logs

---

## 🗃️ Verzia

| Verzia | Dátum | Zmeny |
|---|---|---|
| 1.0 | September 2026 | Inicializácia – PostHog, Formspree, Xcode Organizer, Better Stack, GDPR |
