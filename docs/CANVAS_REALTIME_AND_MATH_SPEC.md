# Architektúra Supabase Realtime a Výpočtová Matematika Canvasu pre Ellegnote

Dokument slúži ako kompletná technická a matematická špecifikácia pre synchronizáciu a manipuláciu s tanečnými kartami na nekonečnom/ohraničenom 2D plátne naprieč **iOS (Swift / SwiftUI)** a **Webom (Next.js / TypeScript / React)**.

---

## 1. Ako funguje Supabase Realtime pod kapotou

Supabase Realtime je postavený na **Elixir / Phoenix Channels** serveroch bežiacich nad WebSockets. Poskytuje obojsmerný komunikačný kanál s minimálnou réžiou a extrémnou priepustnosťou.

V Ellegnote využívame 3 základné stavebné bloky Realtime architektúry:

```
                      ┌────────────────────────────────────────┐
                      │        Supabase Realtime Cluster       │
                      │           (Phoenix Channels)           │
                      └────┬──────────────┬───────────────┬────┘
                           │              │               │
            1. Broadcast   │  2. Presence │  3. Postgres  │ (CDC / WAL)
            (Sub-50ms)     │  (Stav izby) │     Changes   │
                           │              │               │
             ┌─────────────▼──────────────▼───────────────▼─────────────┐
             │                   WebSocket Kanál:                       │
             │           `canvas_{routine_id.lowercased()}`             │
             └─────────────────────┬────────────────────────────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │                             │
         ┌──────────▼──────────┐       ┌──────────▼──────────┐
         │  iOS Klient (Swift) │       │ Web Klient (Next.js)│
         │  `supabase-swift`   │       │  `@supabase/ssr`    │
         └─────────────────────┘       └─────────────────────┘
```

### A. Broadcast (Najnižšia latencia, < 50ms, bez zápisu do DB)
* **Princíp:** Správy typu Publish/Subscribe priamo cez WebSocket pamäť servera. Nezapisujú sa na disk ani do PostgreSQL tabuliek.
* **Využitie v Ellegnote:**
  1. `node_moved`: Priebežné vysielanie súradníc `(x, y)` karty počas ťahania prstom/myšou (frekvencia ~30 Hz).
  2. `canvas_action`: Okamžitá notifikácia o pridani (`added`), zmazaní (`deleted`) alebo úprave figúry (`updated`), kým DB synchronizácia beží asynchrónne na pozadí.
* **Prečo je to dôležité:** Ak by sa každý pohyb prsta zapisoval do databázy, databáza by skolabovala pod stovkami SQL `UPDATE` príkazov za sekundu. Broadcast zaručuje 60fps plynulosť pre partnera bez akejkoľvek záťaže DB.

### B. Presence (Kto je na parkete a čo drží)
* **Princíp:** CRDT (Conflict-free Replicated Data Type) stav udržiavaný na klastri. Automaticky deteguje pripojenie (`joins`) a odpojenie (`leaves`).
* **Payload stavu:**
  ```json
  {
    "userId": "uuid-pouzivatela",
    "userName": "Kali",
    "x": 1640.5,
    "y": 1480.0,
    "draggingNodeId": "uuid-tahanej-figury" // null ak len prezerá parket
  }
  ```
* **Využitie v Ellegnote:**
  - Živé zobrazenie partnerského kurzora s menovkou na plátne.
  - **Soft-Locking kariet:** Keď partner chytí kartu (`draggingNodeId != null`), druhá strana kartu vizuálne uzamkne (zlatý badge „Kali práve presúva“), čím predchádzame kolíziám a preťahovaniu.

### C. Postgres Changes (CDC – Change Data Capture)
* **Princíp:** Počúvanie zmien priamo z PostgreSQL Write-Ahead Logu (WAL) cez `supabase_realtime` publikáciu:
  ```sql
  ALTER PUBLICATION supabase_realtime ADD TABLE canvas_nodes;
  ALTER TABLE canvas_nodes REPLICA IDENTITY FULL;
  ```
* **Využitie v Ellegnote:**
  - Garantovaná perzistencia. Keď používateľ pustí kartu (`onDragEnd`), pozícia sa uloží do DB. Druhému zariadeniu príde potvrdenie cez CDC ako fallback, ak by náhodou vypadol broadcast paket.

### D. Reconnection & Auto-Reconcile (Obnova spojenia)
Pri prechode iPhonu do pozadia alebo výpadku siete:
1. **Heartbeat:** Klient každých 8 sekúnd overuje stav WebSocketu (`channel.status == .subscribed`).
2. **Re-sync po reconnecte:** Po obnovení spojenia klient okamžite stiahne aktuálny snapshot z databázy, aby dorovnal akékoľvek zmeny, ktoré prebehli počas offline stavu.

---

## 2. Výpočtová Matematika Canvasu a Presúvania Kariet

Pohyb prvkov na 2D plátne vyžaduje transformácie medzi dvoma rôznymi súradnicovými sústavami: **Viewport Space (obrazovka)** a **World/Canvas Space (virtuálny parket)**.

```
       VIEWPORT SPACE (Displej telefónu / monitor)
       ┌───────────────────────────────┐
       │ (0,0)                         │
       │        W_viewport             │
       │   ┌─────────────────┐         │
       │   │  Stred displeja │         │
       │   │   (W_v/2, H_v/2)│         │
       │   └─────────────────┘         │
       │                    H_viewport │
       └───────────────────────────────┘
                       │
       Transformácia cez Scale (S) a Pan Offset (ΔX_pan, ΔY_pan)
                       │
                       ▼
       WORLD / CANVAS SPACE (Virtuálny parket 3000 x 3000 pt)
       ┌────────────────────────────────────────────────────────┐
       │ (0,0)                                                  │
       │                                                        │
       │                  (1500, 1500)                          │
       │                 Stred Parketu                          │
       │                       •                                │
       │                  [Karta Figúry]                        │
       │                                                        │
       │                                            (3000, 3000)│
       └────────────────────────────────────────────────────────┘
```

### A. Parametre Plátna
* Rozmer plátna: $W_{canvas} = 3000\text{ pt}, \quad H_{canvas} = 3000\text{ pt}$.
* Stred parketu: $(X_{center}, Y_{center}) = (1500, 1500)$.
* Mierka (Zoom): $S \in [S_{min}, S_{max}]$ (napr. $0.55 \le S \le 2.5$).
* Posun plátna (Pan offset): $\mathbf{T} = (T_x, T_y)$.

### B. Prevod Súradníc

#### 1. Z Canvas Space na Obrazovku (Forward Transform):
Určuje, na ktorom pixeli displeja sa má vykresliť karta alebo partnerský kurzor:
$$X_{screen} = (X_{canvas} - 1500) \cdot S + \frac{W_{viewport}}{2} + T_x$$
$$Y_{screen} = (Y_{canvas} - 1500) \cdot S + \frac{H_{viewport}}{2} + T_y$$

#### 2. Z Obrazovky na Canvas Space (Inverse Transform):
Určuje, na ktorý bod virtuálneho parketu klikol používateľ myšou alebo prstom:
$$X_{canvas} = 1500 + \frac{X_{screen} - \frac{W_{viewport}}{2} - T_x}{S}$$
$$Y_{canvas} = 1500 + \frac{Y_{screen} - \frac{H_{viewport}}{2} - T_y}{S}$$

### C. Zásadná Matematika Ťahania Karty: Invariancia voči Mierke ($1/S$)
Keď používateľ potiahne kartu prstom o vektor obrazovky $(\delta x_{screen}, \delta y_{screen})$, skutočný posun karty vo virtuálnom svete **musí byť vydelený mierkou $S$**:

$$\Delta X_{canvas} = \frac{\delta x_{screen}}{S}$$
$$\Delta Y_{canvas} = \frac{\delta y_{screen}}{S}$$

**Prečo je delenie $S$ kritické:**
- Ak je používateľ **priblížený** ($S = 2.0$), posun prsta o $20\text{px}$ na displeji zodpovedá len $10\text{pt}$ na parkete.
- Ak je používateľ **oddialený** ($S = 0.5$), posun prsta o $20\text{px}$ na displeji zodpovedá $40\text{pt}$ na parkete.
- *Bez delenia $S$ karta pod prstom pláva, zaostáva alebo nekontrolovateľne uteká.*

### D. Orezanie Okrajov Parketu (Boundary Clamping)
Karta nesmie vyletieť von z tanečnej sály ($3000 \times 3000$). S uvážením polovičnej šírky karty $W_{card}/2 = 70\text{pt}$ a výšky $H_{card}/2 = 66\text{pt}$ a bezpečnostného okraja $M = 20\text{pt}$:

$$X_{clamped} = \min\left(\max\left(X_{raw}, 70 + M\right), 3000 - 70 - M\right)$$
$$Y_{clamped} = \min\left(\max\left(Y_{raw}, 66 + M\right), 3000 - 66 - M\right)$$

### E. Magnetické Zarovnávanie (Magnetic Snap & Alignment Guides)

1. **Diskrétna mriežka sály ($G = 40\text{pt}$):**
   $$X_{snap} = \text{round}\left(\frac{X}{G}\right) \cdot G$$
   $$Y_{snap} = \text{round}\left(\frac{Y}{G}\right) \cdot G$$

2. **Magnetické priťahovanie k susedným kartám (Tolerancia $\epsilon = 12\text{pt}$):**
   Pre každú ďalšiu kartu $N_j$ na parkete:
   $$\text{ak } |X_{curr} - X_j| \le \epsilon \implies X_{curr} = X_j \quad (\text{vertikálna vodiaca čiara})$$
   $$\text{ak } |Y_{curr} - Y_j| \le \epsilon \implies Y_{curr} = Y_j \quad (\text{horizontálna vodiaca čiara})$$

### F. Hladká Interpolácia Pohybu Partnera (LERP & Spring Smoothing)
Pakety cez Broadcast chodia diskrétne (každých ~33ms). Ak by sme pozíciu karty na obrazovke prepisovali skokovo, pohyb by trhal.

Používame exponenciálne vyhladzovanie (LERP):
$$\mathbf{P}(t + \Delta t) = \mathbf{P}(t) + \alpha \cdot (\mathbf{P}_{target} - \mathbf{P}(t))$$
kde $\alpha = 1 - e^{-\lambda \Delta t}$ (pričom $\lambda \approx 18$ pre responzívny a maslový pohyb bez oneskorenia).
V SwiftUI to rieši `.animation(.interactiveSpring(response: 0.22, dampingFraction: 0.85))`.

---

## 3. Webová Architektúra (Čo pridáme POTOM na Web)

Na webe (`web/src/app/dashboard/routines/[id]/canvas`) vytvoríme plnohodnotný Realtime editor zhodný s mobilnou aplikáciou:

### A. Technologický Stack
- **Framework:** Next.js (App Router, React 19)
- **Realtime Klient:** `@supabase/supabase-js` cez existujúci `createClient()` z `web/src/lib/supabase/client.ts`.
- **Canvas Rendering:** HTML5 Canvas alebo SVG transform container (`<g transform="matrix(...)">`) s hardvérovou akceleráciou `will-change: transform`.

### B. Komponentová Štruktúra na Webe
1. `useCanvasGestures.ts`: Hook spracúvajúci Pointer Events:
   - `onPointerDown`: Zaznamená počiatočný bod, aktivuje `setPointerCapture`.
   - `onPointerMove`: Aplikuje $\Delta X_{canvas} = \delta x_{screen} / S$, throttluje Broadcast na 30fps.
   - `onWheel`: Zoomovanie s kotvou v bode kurzora (Zoom-towards-cursor math).
2. `useCanvasRealtime.ts`: Hook spravujúci WebSocket kanál `canvas_{routineId}`:
   - Pripojenie na Broadcast `node_moved`, `canvas_action`.
   - Pripojenie na Presence (vysielanie polohy myši pre partnera na iPhone).
   - Auto-reconnect a synchronizácia s Supabase DB.
3. `CanvasBoard.tsx`: Hlavný viewport obsahujúci:
   - `CanvasGrid`: Šachovnicová mriežka tanečnej sály.
   - `ConnectionsLayer`: SVG Bézierove krivky medzi kartami s vyznačeným rytmom.
   - `CanvasNodeCard`: Karty figúr v tmavom obsidiánovo-zlatom dizajne s tlačidlami úprav.
   - `PartnerCursorOverlay`: Kurzor partnera pohybujúceho sa z mobilu alebo iného PC.

---

## 4. Swift Architektúra (Čo pridávame TERAZ do iOS aplikácie)

V existujúcom kóde iOS aplikácie (`CanvasRealtimeManager.swift`, `RoutineCanvasView.swift`, `CanvasLayersAndCards.swift`) rozširujeme funkcionalitu o nasledujúce prvky:

### A. Vylepšenia v Matematike Ťahania Kariet:
1. **Ohraničenie (Clamping):** Zabezpečiť, aby karta pri potiahnutí nemohla opustiť rozsah $[80, 2920]\text{pt}$.
2. **Magnetické zarovnanie (Magnetic Snap):** Pri pustení karty (`onEnded`) jemne zarovnať na mriežku sály ($40\text{pt}$ step) s haptickou odozvou `UIImpactFeedbackGenerator(style: .light)`.
3. **Plynulý LERP / Spring:** Pri prijatí `node_moved` z WebSocketu použiť `interactiveSpring(response: 0.22, dampingFraction: 0.85)` pre dokonale plynulý posun.

### B. Vylepšenia v Realtime & Concurrency:
1. **Zámok karty (Concurrency Lock):**
   - Ak `partnerPresences.values` obsahuje používateľa, ktorý práve ťahá danú figúru (`draggingNodeId == node.id`), karta na displeji zobrazí jemný zlatý pulzujúci lem a text s menom partnera (napr. *„Kali presúva“*).
   - Gestá na tejto karte sú dočasne zablokované, aby nedochádzalo k race condition.
2. **Indikátor stavu Realtime s odozvou:**
   - Zobrazenie zeleného pulzujúceho bodu s textom *„Realtime pripojené“* a indikátorom nízkej latencie v štýle Obsidian & Gold.
3. **Konzistentný luxusný dizajn kurzora partnera:**
   - Prepracovanie `PartnerCursorView` do tmavého obsidiánového štýlu so zlatým indikátorom.
