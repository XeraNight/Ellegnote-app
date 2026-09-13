# Supabase Library & Realtime Architektúra: Chat, Canvas a Kolaborácia (Web & iOS)

Tento dokument detailne rozoberá architektúru oficiálnej **Supabase Library** (šablóny a bloky pre Next.js), princíp fungovania **Realtime Chatu**, kolaboratívnych kurzorov a diagramov (**Realtime Flow**), a ich priamu aplikáciu v **Ellegnote** pre Web (Next.js) aj iOS (SwiftUI).

---

## 1. Ako funguje Supabase Library (supabase.com/library)

Supabase Library je oficiálna zbierka produkčných komponentov typu „copy-paste“ (kompatibilná so `shadcn/ui` CLI: `npx shadcn add @supabase/...`).

### Kľúčové architektonické bloky v knižnici:

| Komponent / Blok | Primárna technológia | Účel a správanie | Využitie v Ellegnote |
| :--- | :--- | :--- | :--- |
| **Realtime Chat** | `channel.on('broadcast')` | Blesková výmena správ v reálnom čase bez záťaže DB s voliteľnou perzistenciou cez `onMessage`. | Chat medzi tanečnými partnermi a trénerom v štúdiu/zostave. |
| **Realtime Cursor** | `channel.track()` + `Broadcast` | Zdieľanie polohy kurzora myši/prsta na plátne s menom používateľa; vyhladzovanie cez `perfect-cursors`. | Zobrazenie polohy prsta partnera na parkete. |
| **Realtime Flow** | `React Flow` + `Yjs` CRDT | Plátno s uzlami a hranami; kolaboratívne presúvanie kariet s automatickým riešením konfliktov. | Inšpirácia pre webový Canvas choreografií. |
| **Realtime Avatar Stack**| `channel.presenceState()` | Zoznam tvárí / avatarov používateľov, ktorí majú aktuálne otvorenú rovnakú zostavu. | Hlavička zostavy („Kto je práve online na parkete“). |
| **Platform Kit** | Supabase Management API Proxy | Vstavané admin rozhranie na správu DB, používateľov, storage videí, SQL a logov priamo v aplikácii. | Interný Admin Panel & Trénerská správa v Next.js dashboarde. |
| **SSR Auth & Client** | `@supabase/ssr` | Bezpečné spracovanie cookies v Next.js (Server Components, Middleware, Client). | Autentifikácia na webe v `web/src/lib/supabase/`. |

---

## 2. Podrobný rozbor: Ako funguje Realtime Chat

Analýza zdrojového kódu z `https://supabase.com/library/docs/nextjs/realtime-chat` a `realtime-chat-nextjs.json`:

```
          Používateľ A (Odosielateľ)                   WebSocket Server (Phoenix)                   Používateľ B (Príjemca)
                    │                                             │                                            │
  1. Napíše správu  │                                             │                                            │
  2. Optimistic UI: │                                             │                                            │
     Pridá do `messages`                                          │                                            │
  3. channel.send({ │ ─────── type: 'broadcast', ───────────────► │                                            │
        event: 'message',       event: 'message'                  │                                            │
        payload: msg                                              │ ────────── Event 'message' ──────────────► │
     })             │                                             │            s payloadom správ               │
                    │                                             │                                            │ 4. on('broadcast')
                    │                                             │                                            │    Pridá do `messages`
                    │                                             │                                            │ 5. scrollToBottom()
```

### A. Zdrojový kód hooku `useRealtimeChat`
```typescript
export function useRealtimeChat({ roomName, username }: UseRealtimeChatProps) {
  const supabase = createClient()
  const [messages, setMessages] = useState<ChatMessage[]>([])
  const [channel, setChannel] = useState<RealtimeChannel | null>(null)
  const [isConnected, setIsConnected] = useState(false)

  useEffect(() => {
    // 1. Pripojenie na izolovaný kanál miestnosti
    const newChannel = supabase.channel(roomName)

    // 2. Počúvanie prichádzajúcich správ od ostatných
    newChannel
      .on('broadcast', { event: 'message' }, (payload) => {
        setMessages((current) => [...current, payload.payload as ChatMessage])
      })
      .subscribe(async (status) => {
        setIsConnected(status === 'SUBSCRIBED')
      })

    setChannel(newChannel)

    return () => {
      supabase.removeChannel(newChannel)
    }
  }, [roomName, username, supabase])

  // 3. Odoslanie správy
  const sendMessage = useCallback(
    async (content: string) => {
      if (!channel || !isConnected) return

      const message: ChatMessage = {
        id: crypto.randomUUID(),
        content,
        user: { name: username },
        createdAt: new Date().toISOString(),
      }

      // Optimistický lokálny update – odosielateľ nečaká na sieť
      setMessages((current) => [...current, message])

      // Bleskové odoslanie cez WebSocket pamäť
      await channel.send({
        type: 'broadcast',
        event: 'message',
        payload: message,
      })
    },
    [channel, isConnected, username]
  )

  return { messages, sendMessage, isConnected }
}
```

### B. Kľúčové princípy pre chat v Ellegnote:
1. **Optimistic UI:** Odosielateľ nečaká na odpoveď zo servera. Správa sa okamžite zobrazí v bubline, čo dáva pocit nulovej latencie.
2. **Duálna perzistencia (Voliteľné ukladanie do Postgresu):**
   - Správy posielané len cez `Broadcast` žijú iba v pamäti WebSocket spojenia. Ak sa stránka obnoví, vymažú sa.
   - V Ellegnote použijeme hybridný model:
     - Počas písania a rýchleho odoslania: `Broadcast` zabezpečí okamžité zobrazenie u partnera (<50ms).
     - Callback `onMessage` alebo asynchrónny server action správu zapíše do tabuľky `chat_messages` v Supabase, aby si pár našiel históriu poznámok aj na druhý deň.
3. **Plynulé rolovanie (`useChatScroll`):**
   - Použitie `useRef` na kontajner správ a volanie `container.scrollTo({ top: container.scrollHeight, behavior: 'smooth' })` pri každej novej správe.

---

## 3. Realtime Cursors a Realtime Flow (Diagramy a Karty)

V oficiálnej Supabase Library existujú dva komponenty priamo súvisiace s naším tanečným plátnom:
1. **`realtime-cursor`:**
   - Využíva **Supabase Presence** na zdieľanie polohy myši.
   - Odporúča matematickú knižnicu `perfect-cursors`, ktorá robí **Spline/Hermite krivkovú interpoláciu** medzi bodmi, aby kurzor netrhal ani pri sieťovom oneskorení 80ms.
2. **`realtime-flow`:**
   - Spája **React Flow** s **Yjs (CRDT)** cez balík `@supabase-labs/y-supabase`.
   - Pri presunutí uzla sa zmena zapíše do zdieľanej mapy `Y.Map`. Ak dvaja používatelia pohnú kartou v rovnakom milisekunde, CRDT deterministicky určí výsledok (Last-Write-Wins na úrovni jednotlivých vlastností bez prepísania celého objektu).

---

## 4. Platform Kit: Vstavaná správa Supabase vo vnútri platformy

Podľa špecifikácie z `https://supabase.com/library/docs/platform/platform-kit` (`@supabase/platform-kit-nextjs`) slúži tento balík na vytvorenie **vstavaného administrátorského a manažérskeho rozhrania priamo v tvojej aplikácii**.

Namiesto toho, aby si musel chodiť do externej Supabase konzoly na webe, Platform Kit poskytuje responzívny modál / zásuvku (`SupabaseManagerDialog`), ktorá v sebe integruje:
1. **Správu databázy & Tabuliek:** Prehliadanie tabuliek (`canvas_nodes`, `routines`, `dances`), spúšťanie SQL dotazov.
2. **AI-Powered SQL generátor:** Možnosť písať otázky v prirodzenom jazyku a generovať SQL query cez OpenAI API (`OPENAI_API_KEY`, `NEXT_PUBLIC_ENABLE_AI_QUERIES`).
3. **Správu používateľov & Auth:** Prehľad registrovaných tanečníkov, ich statusy, overenie e-mailov, resetovanie hesiel.
4. **Správu Storage (Úložiska):** Správa video vaultov, nahratých zostáv, fotiek profilu a limitov úložiska.
5. **Secrets & Monitoring:** Sledovanie výkonu databázy, logov pripojení a environment premenných.

### Bezpečnostná architektúra Platform Kitu:
* **Management API Token (`SUPABASE_MANAGEMENT_API_TOKEN`):** Osobný token má plné práva k projektu. **Nikdy nesmie uniknúť na klienta.**
* **API Proxy (`/api/supabase-proxy/[...path]`):** Požiadavky z UI dialógu nejdú priamo do Supabase, ale cez zabezpečený serverový endpoint v Next.js, ktorý overí oprávnenie používateľa (napr. len admin/tréner) a až potom prepošle požiadavku s tokenom do Supabase Management API.

### Aplikácia v Ellegnote:
Tento nástroj môžeme využiť v Next.js webovom rozhraní v administrátorskej sekcii (`/dashboard/admin` alebo v trénerskom režime) na monitorovanie databázy choreografií, správu úložiska videí a sledovanie stavu synchronizácie.

---

## 5. Výpočtová Matematika Canvasu pre Presúvanie Kariet

Plátno v Ellegnote je virtuálny tanečný parket s rozmermi **3000 x 3000 pt**. Súradnice musia byť matematicky zladené medzi mobilom a počítačom.

```
       SÚRADNICOVÉ SÚSTAVY:
       ┌─────────────────────────────────────────────────────────┐
       │ 1. SCREEN SPACE (Displej iPhonu alebo Web monitor):    │
       │    (0, 0) je vľavo hore na skle displeja.               │
       │    Šírka W_s, Výška H_s.                                │
       └────────────────────────────┬────────────────────────────┘
                                    │
                       Transformačná Matica:
            Scale S (zoom) & Pan Translation (Tx, Ty)
                                    │
       ┌────────────────────────────▼────────────────────────────┐
       │ 2. WORLD CANVAS SPACE (Tanečná sála Ellegnote):         │
       │    Rozmer 3000 x 3000 pt. Stred parketu = (1500, 1500). │
       │    Tu žijú karty figúr: node.x, node.y                  │
       └─────────────────────────────────────────────────────────┘
```

### A. Matematické transformačné rovnice

1. **Prevod z virtuálneho parketu na obrazovku (Kde na displeji kartu vykresliť):**
   $$X_{screen} = (X_{canvas} - 1500) \cdot S + \frac{W_{screen}}{2} + T_x$$
   $$Y_{screen} = (Y_{canvas} - 1500) \cdot S + \frac{H_{screen}}{2} + T_y$$

2. **Prevod z obrazovky na virtuálny parket (Kam na parket používateľ klikol/ťahá):**
   $$X_{canvas} = 1500 + \frac{X_{screen} - \frac{W_{screen}}{2} - T_x}{S}$$
   $$Y_{canvas} = 1500 + \frac{Y_{screen} - \frac{H_{screen}}{2} - T_y}{S}$$

### B. Zásadný vzorec: Delenie mierkou ($1/S$)
Keď sa prst alebo myš posunie na displeji o vektor $(\delta x_{screen}, \delta y_{screen})$, posun na parkete je:

$$\Delta X_{canvas} = \frac{\delta x_{screen}}{S}, \qquad \Delta Y_{canvas} = \frac{\delta y_{screen}}{S}$$

* **Prečo?** Pri priblížení ($S = 2.0$) by bez delenia karta utekala dvakrát rýchlejšie ako prst. Pri oddialení ($S = 0.5$) by sa vliekla za prstom. Delenie $S$ zaručuje, že karta je presne ukotvená pod bodom dotyku na akomkoľvek zoome.

### C. Ohraničenie sály (Boundary Clamping)
Karta nesmie uletieť mimo parket:
$$X_{clamped} = \min(\max(X_{raw}, 90), 2910)$$
$$Y_{clamped} = \min(\max(Y_{raw}, 86), 2914)$$

### D. Magnetické zarovnávanie (Magnetic Snap)
Pri pustení karty sa súradnice zaokrúhlia na najbližšiu mriežku tanečnej sály (kroky po $20\text{pt}$ alebo $40\text{pt}$):
$$X_{snap} = \text{round}\left(\frac{X_{clamped}}{20}\right) \cdot 20$$
$$Y_{snap} = \text{round}\left(\frac{Y_{clamped}}{20}\right) \cdot 20$$

### E. Hladký pohyb u partnera (Spring / LERP)
Pre príjem `node_moved` paketov:
$$\mathbf{P}(t + \Delta t) = \mathbf{P}(t) + (1 - e^{-\lambda \Delta t}) \cdot (\mathbf{P}_{target} - \mathbf{P}(t))$$
V SwiftUI to zabezpečuje `.animation(.interactiveSpring(response: 0.22, dampingFraction: 0.85))`, na webe `requestAnimationFrame` s LERP interpoláciou.

---

## 6. Čo pridáme na Web (Next.js) – Plán implementácie POTOM

V Next.js webovej aplikácii (`web/`) vybudujeme plnohodnotné kolaboratívne štúdio inšpirované Supabase Library:

1. **Komponent `RealtimePartnerChat.tsx`:**
   - Zdieľaný chat pre trénera a tanečníkov priamo v bočnom paneli zostavy.
   - Využije presný vzor `useRealtimeChat` zo Supabase Library.
2. **Hook `useCanvasGestures.ts`:**
   - Obsluha myši s pointer capture a zoomovaním cez koliesko myši ukotveným k bodu kurzora.
3. **Plátno `ChoreographyCanvas.tsx`:**
   - Hardvérovo akcelerované SVG/HTML plátno $3000 \times 3000\text{px}$.
   - Zobrazuje karty figúr, Bézierove prepojovacie čiary s rytmom a živé kurzory partnerov (`RealtimeCursors`).
   - Karty figúr budú používať rovnaký temný obsidiánovo-zlatý štýl ako mobilná aplikácia.

---

## 7. Čo pridávame do Swiftu (iOS) – Implementácia TERAZ

V iOS aplikácii (`CanvasLayersAndCards.swift`, `RoutineCanvasView.swift`, `CanvasRealtimeManager.swift`):

1. **Clamping & Snapping na kartách figúr:**
   - Implementácia ohraničenia $[90, 2910]$ a magnetického prichytenia s haptikou `UIImpactFeedbackGenerator(style: .light)`.
2. **Soft-Locking kariet (Zámok pri preťahovaní):**
   - Keď partner na druhom zariadení chytí kartu, karta zobrazí pulzujúci zlatý zámok s menovkou *„Kali presúva“* a lokálne ťahanie sa dočasne zablokuje, aby nedochádzalo k race condition.
3. **Prémiový Obsidian & Gold dizajn kurzora partnera:**
   - Prepracovanie `PartnerCursorView` na zlatý žiarivý kruh s elegantnou menovkou tanečníka.
