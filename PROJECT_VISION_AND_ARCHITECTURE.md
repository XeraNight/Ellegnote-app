# 💃 ELLEGNOTE — Vizóm, Architektúra a Stratégia Vývoja

---

## 🎯 1. Hlavná Hodnota a Problém, Ktorý Riešime

### Problém
Tanečné páry a tréneri na individuálnych lekciách strácajú drahocenné minúty písaním poznámok do bežných textových aplikácií (Apple Notes, Messenger). Textové poznámky:
- Nevysvetľujú priestorové smerovanie figúry na tancodrome (line of dance, rohy, stred).
- Nemajú prepojenie na konkrétne tréningové video alebo hlasovú poznámku trénera.
- Nie sú okamžite synchrónne medzi partnerom a partnerkou.

### Riešenie (Ellegnote)
- **Vizuálny Choreografický Canvas**: 2D tancodrom, kde sú figúry a prechody rozmiestnené v priestore s rytmickým počítaním a smerovaním.
- **Rýchle Instantné Záznamy (1-Tap Capture)**: Nahrávanie 15s tréningového videa alebo hlasovej poznámky priamo na individuálke bez zdržovania.
- **Realtime Partner Sync**: Okamžitý prenos zmien a pozície kurzora medzi partnerom a partnerkou cez Supabase Realtime.

---

## 📱 2. Stratégia Platforiem (iOS & Vercel Web pre Android)

### Zistenie & Riešenie
Väčšina tanečníkov a trénerov používa iPhone, avšak časť partnerov (vrátane partnerky) používa Android.

### Architektúra Prepojenia (iOS App + Vercel Web App):
1. **Materská iOS / macOS Aplikácia (Native Swift & SwiftUI)**:
   - Poskytuje maximálny 60 FPS grafický výkon Canvasu, haptiku, HW akceleráciu kamery a Apple Intelligence UI.
2. **Android Web Companion Aplikácia (`ellegnote.vercel.app`)**:
   - Vytvoríme ľahkú webovú aplikáciu (React / Vite alebo Next.js), ktorú nahráme na GitHub a **prepojíme s Vercelom**.
   - **Spoločný Supabase Backend (Zdieľané dáta)**: Obe aplikácie (iOS aj Vercel Web) používajú tie isté Supabase API kľúče a databázové tabuľky (`canvas_nodes`, `routines`).
   - Keď partnerka na Android mobile otvorí Vercel odkaz alebo si ho pridá ako PWA ikonu na plochu, vidí rovnaký živý Canvas a uvidíte navzájom svoje pozície kurzorov v reálnom čase!

---

## ⚡ 3. Matematické Vektorové Vzorce & Zero-Lag Architektúra

Namiesto 500 riadkov komplexného imperatívneho kódu, ktorý seká UI vlákno, používame **elegantné matematické vzorce a O(1) časovú zložitosť**:

### 3.1 Matematický Vzorec Krivky Prechodov (Cubic Bezier Spline)
Namiesto náročných cyklických prepočtov spojovacích čiar na CPU počítame pozície a stredové odznaky prechodov pomocou analytického closed-form vzorca:
\[
B(t) = (1-t)^3 P_0 + 3(1-t)^2 t P_1 + 3(1-t) t^2 P_2 + t^3 P_3
\]
Stredový bod prechodu pre tlačidlo poznámky sa vypočíta okamžitým vektorovým průměrom:
\[
\vec{P}_{center} = \frac{\vec{P}_{prev} + \vec{P}_{curr}}{2}
\]
Tento matematický vzorec znižuje výpočtovú záťaž zo sto riadkov layout kódu na 10 riadkov čistej vektorovej algebry!

### 3.2 Instantný Fotoaparát (Camera Pre-Warming)
- **Problém**: Inicializácia `AVCaptureSession` pri stlačení tlačidla kamery spôsobuje zdržanie a sekanie UI.
- **Riešenie**: Načítanie a pred-hriatie `AVCaptureSession` na pozadí (**Background Camera Warm-up**) už počas 2-sekundovej uvítacej obrazovky. Pri stlačení kamery je hneď pripravený stream bez 1ms meškania.

### 3.3 Preloading na Pozadí (Background Data Pre-Fetcher)
- Počas 2-sekundovej Apple Hello splash obrazovky sa na pozadí v asynchrónnom vlákne (`@SyncActor` / `Task.detached`):
  1. Načítajú SwiftData zostavy z disku do RAM pamäte.
  2. Nadviaže sa Supabase Realtime WebSocket spojenie a stiahne stav partnera.
  3. Po zmiznutí splash screenu je aplikácia na 100% načítaná v RAM a pripravená na okamžitú odozvu.

---

## 📅 4. Roadmapa Vývoja

### Fáza 1: Core Canvas & Splash (DOKONČENÉ)
- [x] 2-sekundová Apple Hello uvítacia obrazovka s menom používateľa.
- [x] Domovská stránka sústredená na Canvas Zostavy.
- [x] Plynulé GPU akcelerované prechody na canvase a swipe-back gestá.

### Fáza 2: Pre-warming Kamery & Optimalizácia Načítavania (PRÁVE PREBIEHA)
- [ ] Vytvorenie `CameraPrewarmer` manažéra pre instantné spustenie videa.
- [ ] Asynchrónny preloader dát počas uvítacej obrazovky.
- [ ] Vyladenie realtime odznakov a synchronizácie poznámok.

### Fáza 3: Vercel Web Companion pre Android & Export
- [ ] Vytvorenie Vercel/GitHub webového rozhrania pre Android partnerov.
- [ ] QR kód a PDF/Video export choreografie pre trénerov.
