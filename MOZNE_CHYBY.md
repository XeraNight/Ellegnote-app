# 🛡️ ELLEGNOTE — Kompletný Register 90 Zraniteľných Scenárov & 20 Profesionálnych Tanečných Návrhov

> **Dátum:** August 2026  
> **Status:** Analýza rizík, edge-cases a návrhy funkcií pre tréningy, kempy, súťaže a analýzu  
> **Cieľ:** 90 podrobných hraničných situácií (rozdelených do 6 kategórií) a 20 profesionálnych funkcií pre tanečné páry, trénerov a súťažiacich.

---

## 📸 1. Nastavenie a Správanie Blesku v Kamere

### Aktuálny Princíp:
* **Blesk je v predvolenom stave VYPNUTÝ (`picker.cameraFlashMode = .off`).**
* Pri otvorení kamery blesk/svetlo **nikdy nezasvieti automaticky** a neoslepí tanečníkov na parkete.
* V hornom rohu natívneho rozhrania kamery má používateľ **interaktívnu ikonu blesku (⚡)**, ktorou si môže prisvietenie manuálne zapnúť na `Auto`, `On` alebo `Off` podľa potreby v tmavšej sále.

---

## 💃 2. 20 Profesionálnych Návrhov pre Tréning, Kempy, Súťaže a Analýzu

Inšpirované aplikáciami ako *Apple Camera, Halide, Blackmagic Cam, Hudl Technique, Dartfish* a profesionálnou tanečnou praxou v Standarde & Latine:

```
┌────────────────────────────────────────────────────────────────────────┐
│  🏆 SÚŤAŽNÝ & TRÉNINGOVÝ ASISTENT ELLEGNOTE                            │
│                                                                        │
│  [🎥 Kamera & Slo-Mo]      [👥 Side-by-Side Duel]   [⏱️ 5-Dance Final] │
│  [📐 Posture Angle Lines]  [🎵 BPM Pitch Trainer]  [📺 Studio AirPlay] │
│  [🎪 Camp Workshop Split]  [⌚ Watch Haptic Cue]   [📄 PDF Cheat Sheet]│
└────────────────────────────────────────────────────────────────────────┘
```

### A. Pokročilé Funkcie Kamery (1 – 10)
1. **⏱️ Samospúšť (Hands-Free Countdown 3s / 5s / 10s):** Tanečník položí iPhone na statív alebo lavičku a má čas zaujať východiskovú pozíciu pred spustením záznamu.
2. **📐 Kompozičná mriežka a vodováha (Grid & Level):** Vodiace čiary (Rule of Thirds) a horizontálna vodováha, aby záznam držania tela a parketu nepadal na stranu.
3. **🔍 Rýchle prepínanie ohnísk (0.5x Ultra-Wide, 1x Štandard, 2x / 3x Detail nôh):** 0.5x zachytí celú sálu a smer tanca (Line of Dance), 2x zachytí detailnú prácu chodidiel.
4. **👻 Ghost / Onion Skinning (Prekrývací tréningový mód):** Zobrazenie polopriehľadného videa trénera alebo referenčnej figúry priamo v hľadáčiku kamery na živé porovnanie držania tela.
5. **🪞 Zrkadlový režim prednej kamery (Mirror Front Mode):** Displej sa správa presne ako veľké tréningové zrkadlo v tanečnej sále.
6. **🏎️ Slo-Mo (120 / 240 FPS) s krokovaním po snímkach:** Analýza rýchlych spinov a rotácií po jednotlivých framoch (Frame-by-Frame Scrubbing).
7. **🎙️ Prepínač mikrofónu a audio indikátor:** Voľba medzi vstavaným mikrofónom, AirPods a bezdrôtovým klopovým mikrofónom trénera s vizuálnym meračom hlasitosti.
8. **✂️ Rýchly orezávač videa (Quick Trim):** Odstrihnutie začiatku a konca videa (kde tanečník iba kráča k telefónu a späť) pred uložením k figúre.
9. **🎵 Vstavaný metronóm s BPM tanca:** Vizuálne alebo haptické počítanie tempa (napr. 28-30 MPM pre Slowfox) počas nahrávania.
10. **🏷️ Automatické tagovanie figúry:** Priradenie štítku k videu na jedno ťuknutie: *„Chodidlá“, „Držanie tela“, „Chyba v rotácii“, „Trénerov komentár“*.

### B. Špeciálne Tanečné Moduly pre Kempy, Súťaže a Analýzu (11 – 20)
11. **👥 Side-by-Side Dual Playback (Synchrónne porovnanie dvoch videí):** Prehrávanie vlastného videa a videa majstrov sveta/trénera vedľa seba s jedným spoločným posuvníkom času.
12. **📐 Posture & Angle Lines (Vizuálna analýza línií a postúry):** Možnosť kresliť čiary priamo cez video (sklon chrbtice, C-shape top line v štandarde, uhol panvy v latine, rovina ramien).
13. **🎪 Camp / Workshop Splitter (Rýchly extraktor figúr z dlhého seminára):** Nahratie 45-minútového seminára na medzinárodnom kempe a rýchle rozstrihanie a priradenie jednotlivých figúr na canvas.
14. **🎵 Music Pitch & Speed Trainer (Spomalenie hudby bez zmeny tónu):** Možnosť spomaliť súťažnú skladbu na 80 %, 90 % alebo zrýchliť na 105 % pre tréning stability a svalovej pamäte.
15. **🏆 Súťažný simulátor finále (5-Dance Final Endurance Mode):** Automatický časovač 1:30 min na každý tanec s 30-sekundovou pauzou, prepínaním hudby a zobrazením zostavy na Dynamic Islande.
16. **⌚ Apple Watch Haptic Cueing (Tiché haptické pokyny):** Hodinky jemne ťuknú partnera na zápästie 1 dobu pred náročným prechodom alebo zmenou smeru tanca.
17. **📺 Studio AirPlay / External Display Mode:** Bezdrôtové zrkadlenie canvasu alebo spomaleného videa na veľkú TV v sále bez rušivých tlačidiel aplikácie (čistý Full-Screen video stream).
18. **📄 PDF Export choreografie pre trénerov a porotcov:** Vygenerovanie profesionálneho hárku zostavy so zoznamom figúr, počítaním, diagramom parketu a QR kódom.
19. **⭐ Tréningový denník a hodnotenie trénera (Coach Feedback Log):** Možnosť prideliť figúre 1-5 hviezdičiek, zaznamenať dátum zvládnutia a sledovať progres páru v čase.
20. **🔢 Súťažný organizér (Heats & Rounds Planner):** Zápis štartovného čísla, rozlosovania do rozstrelov (Heat 1, Heat 2), zoznamu súperov a poznámok k parketu.

---

## 🚨 3. Kompletný Register 90 Zraniteľných Scenárov (Stress Audit)

---

### Kategória I: Kamera, Médiá a Hardvér (Scenáre 1 – 15)

| # | Hraničná Situácia | Riziko / Správanie | Riešenie a Ochrana |
|---|---|---|---|
| 1 | **Plný disk počas 4K videa** | Nahrávanie zlyhá uprostred figúry, nahrávka sa poškodí. | Pred otvorením kamery skontrolovať aspoň 300 MB voľného miesta na disku. |
| 2 | **Prichádzajúci hovor / Alarm** | iOS preruší audio/video reláciu a zatvorí kameru. | Odchytiť `AVAudioSession.interruptionNotification` a uložiť dovtedy zaznamenanú časť. |
| 3 | **Low Power Mode (Slabá batéria)** | Zníženie FPS z 60 na 30 FPS a zníženie jasu displeja. | Akceptovať throttling, informovať používateľa jemným toastom. |
| 4 | **Zhodenie aplikácie po kliknutí na "Use Video"** | Používateľ potiahne appku hore skôr, ako sa dokončí zápis. | Obaliť ukladanie do `UIApplication.shared.beginBackgroundTask`. |
| 5 | **Výber 48 MPx RAW fotografie** | Aplikácia spotrebuje priveľa RAM pri dekódovaní veľkej fotky. | `MediaResolver` automaticky zmenšuje obrázky na max 1400px pred vykreslením. |
| 6 | **Extrémne prehriatie iPhonu (Thermal State: Critical)** | Pri dlhom nahrávaní na horúcom parkete iOS zablokuje blesk a obmedzí kameru. | Sledovať `ProcessInfo.processInfo.thermalState` a znížiť kvalitu náhľadu pri prehriatí. |
| 7 | **Prehrávanie poškodeného video súboru** | Používateľ importuje súbor s neznámym kodekom, čierna obrazovka. | Nastaviť KVO pozorovateľ na `AVPlayerItem.status == .failed` a zobraziť chybový stav. |
| 8 | **Prehrávanie 0.3s ultrakrátkeho videa v nekonečnej slučke** | `AVPlayerLooper` preťaží procesor neustálym seekovaním. | Nastaviť minimálnu dĺžku slučky alebo pridať 200 ms pauzu medzi opakovaniami. |
| 9 | **Odpojenie Bluetooth reproduktora počas prehrávania** | Zmena audio výstupu môže spôsobiť zásek prehrávača. | Implementovať listener na `AVAudioSession.routeChangeNotification`. |
| 10 | **Otočenie displeja do Landscape režimu počas videa** | Prvky ovládania sa môžu posunúť mimo obrazovku. | Využiť bezpečné zóny (`safeAreaInsets`) a responzívne layouty. |
| 11 | **Zablokovanie kamery v MDM / Rodičovskej kontrole** | Kamera je systémovo zakázaná na firemnom/školskom iPhone. | Detegovať `AVCaptureDevice.authorizationStatus == .restricted` s vysvetlením. |
| 12 | **Kamera beží v noci v úplnej tme** | Senzor zašumí a obraz je nečitateľný. | Ponúknuť zapnutie predného podsvietenia displeja alebo zadného LED prisvietenia. |
| 13 | **Pád aplikácie z dôvodu nedostatku RAM pri 10 otvorených kartách** | Zlyhanie alokácie pamäte v SwiftUI hierarchii. | Uvoľňovať `AVPlayer` inštancie pri `onDisappear` a zavretí detailu figúry. |
| 14 | **Zmazanie originálneho videa zo systémovej galérie Fotiek** | Ak aplikácia odkazovala na galériu, video zmizne. | Ellegnote vždy kopíruje médiá do vlastného chráneného Sandboxu (`Documents`). |
| 15 | **Vyčistenie úložiska systému iOS (Storage Pressure Sweep)** | Systém zmaže dočasné súbory v `tmp/` priečinku. | Všetky trvalé videá a fotky ukladať výhradne do `Documents/`, nikdy nenechávať v `tmp/`. |

---

### Kategória II: Hlasové Poznámky & Rozpoznávanie Reči (Scenáre 16 – 25)

| # | Hraničná Situácia | Riziko / Správanie | Riešenie a Ochrana |
|---|---|---|---|
| 16 | **Diktovanie v hlučnej sále s hudbou** | Prepis zachytí text piesne namiesto trénerovho hlasu. | Zobraziť grafický indikátor hladiny zvuku a možnosť jednoduchého zrušenia. |
| 17 | **Diktovanie v angličtine pri slovenskom nastavení** | Foneticky skomolený nezrozumiteľný text. | Rýchly prepínač jazyka [SK / EN] priamo vedľa tlačidla diktovania. |
| 18 | **Diktovanie dlhšie ako 60 sekúnd** | `SFSpeechRecognizer` má limit od Apple ~1 minútu na reláciu. | Automaticky segmentovať a reštartovať reláciu po 50 sekundách bez straty textu. |
| 19 | **Odpojenie alebo vybitie AirPods počas diktovania** | Audio engine spadne pre stratu vstupného hardvéru. | Zachytiť `routeChangeNotification`, zastaviť nahrávanie a uložiť dovtedajší text. |
| 20 | **Tréner diktuje špecifické tanečné výrazy (napr. *Chassé, Rondé, Fleckerl*)** | Slovenský slovník nepozná francúzske a nemecké tanečné termíny. | Doplniť `contextualStrings` do `SFSpeechAudioBufferRecognitionRequest` so slovníkom figúr. |
| 21 | **Používateľ nemá povolený mikrofón** | Tlačidlo diktovania nič neurobí a zamrzne. | Zobraziť dialóg: *"Pre diktovanie povoľte mikrofón v Nastavenia -> Ellegnote"*. |
| 22 | **Súčasné diktovanie a prehrávanie hudby z Apple Music** | Aplikácia stlmí alebo zastaví hudbu v sále. | Použiť kategóriu `.record` s voľbou `.duckOthers`, ktorá hudbu len jemne stíši. |
| 23 | **Offline diktovanie bez internetového pripojenia** | Staršie iPhony bez on-device dictation zlyhajú. | Overiť `recognizer.supportsOnDeviceRecognition` a informovať o stave. |
| 24 | **200+ nespracovaných instantných poznámok v schránke** | Pomalé scrollovanie a neprehľadnosť v paneli. | Doplniť možnosť hromadného vymazania a vyhľadávania v schránke. |
| 25 | **Vloženie extrémne dlhého textu do poznámky (10 000 slov)** | Deformácia karty figúry a sekanie renderovania. | Použiť elastický `AppleTypewriterTextView` s virtuálnym scrollovaním. |

---

### Kategória III: 2D Choreografický Canvas & Realtime (Scenáre 26 – 40)

| # | Hraničná Situácia | Riziko / Správanie | Riešenie a Ochrana |
|---|---|---|---|
| 26 | **Multi-touch: Ťahanie 3 figúr naraz rôznymi prstami** | Kolízia viacerých gest a nepredvídateľné skoky figúr. | Nastaviť `exclusiveTouch = true` pre karty figúr na canvase. |
| 27 | **Presunutie figúry ďaleko mimo parketu (x=15000)** | Figúra zmizne z dohľadu a nedá sa nájsť. | Nastaviť hranice parketu (Bounding Box) a tlačidlo *"Vycentrovať parket"*. |
| 28 | **Zostava s 60+ figúrami a desiatkami Bezier kriviek** | Pokles snímkovej frekvencie pod 30 FPS na starších zariadeniach. | Aktivovať Metal akceleráciu cez SwiftUI `drawingGroup()` na vrstve prepojení. |
| 29 | **Súčasný pohyb figúry dvoma partnermi cez WebSockets** | Figúra bliká a skáče medzi dvoma pozíciami (Race condition). | Zaviesť zámok figúry (Node Lock: *"Partner práve presúva"*). |
| 30 | **Partner A zmaže figúru, kým Partner B má otvorený jej detail** | Partner B upravuje neexistujúci objekt, pád pri ukladaní do SwiftData. | Pri prijatí Realtime DELETE okamžite bezpečne zatvoriť detail s toastom. |
| 31 | **Pinch-to-zoom na 0.01x (extrémne zmenšenie)** | Figúry sa zmenšia na neviditeľné body, zlyhanie hit-testov. | Obmedziť mierku zoomu na bezpečný rozsah (0.35x až 2.5x). |
| 32 | **Zostava bez figúr (prázdny Canvas)** | Používateľ nevie čo má robiť na prázdnej ploche. | Zobraziť elegantný prázdny stav (Empty State) s tlačidlom *"Pridať prvú figúru"*. |
| 33 | **Choreografia vytvorí nekonečný cyklus v číslovaní** | Počítadlo figúr ukazuje nesprávny súčet. | Automatický prepočet `orderIndex` podľa topologického usporiadania spojení. |
| 34 | **Kreslenie trajektórie (Apple Pencil / Prst) s 10 000 bodmi** | Extrémna pamäťová náročnosť vrstvy kreslenia. | Algoritmus Douglas-Peucker na zjednodušenie a vyhladenie krivky trajektórie. |
| 35 | **Zmena disciplíny zostavy (zo Štandardu na Latinu)** | Nekompatibilné rytmizácie a figúry v zozname. | Upozorniť používateľa modálnym oknom pred zmenou kategórie tanca. |
| 36 | **Vytvorenie dvoch zostáv s úplne identickým názvom** | Zmätok v zozname zostáv. | Automaticky pridať suffix (napr. *"Waltz Choreografia (2)"*). |
| 37 | **Prekrytie dvoch kariet figúr presne na rovnakých súradniciach** | Spodná karta sa nedá označiť ani kliknúť. | Inteligentný auto-layout offset (+20pt) pri vložení na rovnaké miesto. |
| 38 | **Pomalé internetové pripojenie partnera (Edge / 2G)** | Hromadenie WebSocket správ a oneskorené animácie. | Debouncing polohy (700 ms) a zhadzovanie zastaraných polôh kurzora. |
| 39 | **Výpadok Supabase Realtime servera** | Canvas prestane synchronizovať zmeny medzi partnermi. | Vizuálny offline indikátor v rohu canvasu a plynulý prechod na lokálny režim. |
| 40 | **Rozpojenie prepojenia medzi figúrami** | Zostava stratí kontinuitu a rytmickú nadväznosť. | Zobraziť prerušovanú červenú čiaru s upozornením na chýbajúci prechod. |

---

### Kategória IV: Cloud, Synchronizácia, Autentifikácia & Bezpečnosť (Scenáre 41 – 50)

| # | Hraničná Situácia | Riziko / Správanie | Riešenie a Ochrana |
|---|---|---|---|
| 41 | **Expirácia JWT tokenu pri štarte v offline režime** | Aplikácia by používateľa neprávom odhlásila. | Čítať prihlásený stav z hardvérového Keychainu a token obnoviť až online. |
| 42 | **Zmena hesla cez web a staré heslo uložené v Face ID** | Face ID zlyhá voči Supabase Auth s chybou `invalid_grant`. | Detegovať chybu, vymazať Keychain a vyzvať na zadanie nového hesla. |
| 43 | **Offline vytvorenie 10 zostáv a následné pripojenie na Wi-Fi** | Nárazová synchronizácia môže zahltiť API alebo vyvolať chyby. | Fronta požiadaviek (Sync Queue) s postupným odosielaním s odstupom 100 ms. |
| 44 | **Prekročenie 500 MB limitu Supabase Storage** | Server odmietne nahrať nové video s chybou HTTP 413. | Informovať používateľa; lokálne video zostáva plne funkčné na iPhone. |
| 45 | **Súčasná registrácia dvoch používateľov s rovnakým e-mailom** | Supabase Auth vráti chybu `user_already_exists`. | Zobraziť slovenskú hlášku a tlačidlo na okamžitý prechod do Prihlásenia. |
| 46 | **Slabé internetové pripojenie počas výmeny Google OAuth kódu** | Prihlásenie cez Google zamrzne na bielom displeji. | Nastaviť 15-sekundový timeout s možnosťou zopakovať pokus. |
| 47 | **Vymazanie účtu v profile aplikácie** | Dáta zostanú v cloude ako osirotené záznamy. | Kaskádové mazanie v PostgreSQL (`ON DELETE CASCADE`) pre všetky zostavy používateľa. |
| 48 | **Odhlásenie na jednom zariadení pri aktívnej Live Activity** | Dynamic Island pokračuje v behu a zobrazuje súkromné dáta. | Pri volaní `signOut()` okamžite ukončiť všetky aktívne Live Activities. |
| 49 | **Pokus o SQL Injection cez názov figúry alebo poznámku** | Bezpečnostné riziko pri nesprávnom escapovaní. | Používať výhradne parametrizované dotazy a PostgREST ORM wrapper. |
| 50 | **Neoprávnený prístup cudzieho používateľa k súkromnej zostave** | Únik tréningových choreografií konkurenčným párom. | Striktné Row Level Security (RLS) politiky na PostgreSQL tabuľkách. |

---

### Kategória V: Systém iOS, QR, Widgety & Dátová Integrita (Scenáre 51 – 60)

| # | Hraničná Situácia | Riziko / Správanie | Riešenie a Ochrana |
|---|---|---|---|
| 51 | **Naskenovanie QR kódu reštauračného menu alebo Wi-Fi** | Aplikácia sa pokúsi dekódovať neplatný JSON a spadne. | Validácia schémy s prefixom `ellegnote://routine` pred parsovaním. |
| 52 | **Generovanie QR kódu pre obrovskú zostavu (>40 figúr)** | Hustý QR kód je nečitateľný pre staršie fotoaparáty. | Kompresia dát cez Gzip/Deflate pred generovaním QR kódu. |
| 53 | **Zmena veľkosti systémového písma (Dynamic Type XXL)** | Prvky v navigácii a karty figúr pretečú cez okraje. | Podpora škálovania cez `@ScaledMetric` a flexibilné layouty s `ViewThatFits`. |
| 54 | **Zapnutý VoiceOver pre zrakovo znevýhodnených** | Tanečník nepočuje názvy figúr pri dotyku na canvase. | Pridať sémantické `.accessibilityLabel` a `.accessibilityHint` na karty figúr. |
| 55 | **Spustenie aplikácie na iPade v režime Split View (polovica obrazovky)** | Layout navrhnutý len pre iPhone sa zdeformuje. | Použitie responzívnych kontajnerov a adaptívneho plávajúceho doku. |
| 56 | **Zmena časového pásma pri cestovaní na medzinárodnú súťaž** | Nesúlad v časových značkách `updatedAt` pri synchronizácii. | Všetky časové pečiatky ukladať a porovnávať striktne v UTC (ISO 8601). |
| 57 | **Budúca aktualizácia schémy SwiftData (Nová verzia modelu)** | Pád aplikácie pri štarte na `SwiftData.MigrationError`. | `DatabaseRecoveryManager` automaticky zálohuje SQLite bázu pred obnovou. |
| 58 | **Používateľ 3x importuje rovnakú zostavu z QR kódu** | Vznik 3 identických duplikátov v zozname tancov. | Dialóg: *"Táto zostava už existuje. Chcete ju aktualizovať alebo vytvoriť kópiu?"*. |
| 59 | **Uspanie aplikácie systémom pri bežiacom Dynamic Islande** | Widget na zamknutej ploche zamrzne a neaktualizuje sa. | Nastaviť `staleDate` pre Live Activity a ukončiť ju pri nečinnosti. |
| 60 | **Zapnutie funkcie Obmedzenie pohybu (Reduce Motion) v iOS** | Rýchle prechody a animácie môžu spôsobiť nevoľnosť. | Rešpektovať `@Environment(\.accessibilityReduceMotion)` a vypnúť zbytočné animácie. |

---

### Kategória VI: Súťaže, Kempy, Tréningový Stres & Zdieľanie (Scenáre 61 – 90)

| # | Hraničná Situácia | Riziko / Správanie | Riešenie a Ochrana |
|---|---|---|---|
| 61 | **Zahltaná mobilná sieť v športovej hale s 2000 divákmi** | 100% strata paketov, timeouty synchronizácie. | Plný offline režim so zobrazením lokálne uložených dát bez blokovania UI. |
| 62 | **Kvapky potu / vody na displeji iPhonu počas tréningu** | Náhodné falošné dotyky posúvajú figúry po canvase. | Tlačidlo *"Zámok parketu"* (Lock Canvas), ktoré deaktivuje posun kariet. |
| 63 | **Zhasnutie / uzamknutie obrazovky (Auto-Lock) uprostred tanca** | Displej zhasne po 30 sekundách, tanečník nevidí zostavu. | Nastaviť `UIApplication.shared.isIdleTimerDisabled = true` počas otvoreného Canvasu. |
| 64 | **Zmena siete z 5G na štúdiovú Wi-Fi uprostred uploadu videa** | HTTP spojenie sa preruší a nahrávanie zlyhá. | Použiť `URLSessionUploadTask` s podporou automatického obnovenia (Resumable Upload). |
| 65 | **Prehrávanie videa cez štúdiový Bluetooth reproduktor s oneskorením** | Zvuk mešká 300 ms za videom (desynchronizácia dôb). | Možnosť manuálneho posunu audio offsetu (+/- ms) v prehrávači. |
| 66 | **Paralelné cvičenie: Apple Fitness / Tréning beží na hodinkách** | Dve audio-aktívne aplikácie bojujú o kategóriu relácie. | Nastavenie `AVAudioSessionCategoryOptionMixWithOthers`. |
| 67 | **Zdieľanie choreografie cez AirDrop (`.ellegnote` súbor)** | Systém nevie priradiť súbor aplikácii. | Zaregistrovať vlastný Document Type a UTI `com.ellegnote.routine` v `Info.plist`. |
| 68 | **Odpojenie AirPlay TV uprostred tímového rozboru na kempe** | Prehrávač zamrzne alebo spadne pri strate externého displeja. | Odchytiť `UIScreen.didDisconnectNotification` a vrátiť prehrávanie na telefón. |
| 69 | **Rýchle viacnásobné klikanie na tlačidlo Nahrávať (Spamming)** | Spustenie viacerých inštancií rekordéra za sebou. | Debounce na tlačidle nahrávania (blokovanie na 500 ms po kliknutí). |
| 70 | **Rýchle zmazanie figúry počas prebiehajúceho uploadu jej videa** | Upload nahrá video do cloudu, ale figúra v databáze už neexistuje. | Zrušiť priradený `Task` uploadu pri volaní `deleteVideo()`. |
| 71 | **Otvorenie dvoch okien aplikácie na iPade (Stage Manager)** | Dve inštancie `RoutineCanvasView` naraz pristupujú k SwiftData. | SwiftData `ModelContext` koordinácia a zdieľaný state kontajner. |
| 72 | **Súčasná editácia zostavy tromi partnermi na medzinárodnom kempe** | Konflikt viacerých WebSocket streamov na jednom kanáli. | Kanál routovaný podľa `routineId` s priradením unikátneho `clientId` pre každého. |
| 73 | **Cudzojazyčné znaky v názvoch figúr (Azbuka, Japončina, Čínština)** | Poškodenie kódovania pri prenose cez QR kód alebo JSON. | Striktné kódovanie `String.Encoding.utf8` vo všetkých serializátoroch. |
| 74 | **Prepnutie používateľského konta v offline režime** | Zobrazenie dát predchádzajúceho používateľa. | Reset lokálneho SwiftData kontextu pri zmene `AuthManager.currentUser`. |
| 75 | **Poškodená hlavička videa (`moov atom`) pri násilnom reštarte iPhonu** | Video sa nedá prehrať v iOS ani na webe. | `UIImagePickerController` automaticky finalizuje hlavičku priamo cez AVFoundation. |
| 76 | **Hardvérový prepínač tichého režimu (Mute Switch) na iPhone** | Používateľ nepočuje video ani rytmus. | Nastavenie kategórie `.playback` ignoruje hardvérový Silent Switch podľa Apple HIG. |
| 77 | **Extrémne veľká vlastná knižnica figúr (500+ položiek)** | Pomalé načítanie zoznamu figúr v paneli. | Použitie `LazyVStack` a stránkovania (Pagination) v `GlobalLibraryView`. |
| 78 | **Aktivácia Siri ("Hey Siri") počas nahrávania tanca** | Siri preruší mikrofón aj nahrávanie kamery. | Odchytiť prerušenie relácie a po skončení Siri umožniť pokračovanie. |
| 79 | **Zapnuté nahrávanie obrazovky iOS (Screen Recording v Control Center)** | Limitovaný prístup k video hardvéru. | Kompatibilné spracovanie cez štandardný `UIImagePickerController`. |
| 80 | **Používateľ manuálne zruší Live Activity v Dynamic Islande** | Aplikácia sa pokúsi poslať update do neexistujúcej aktivity. | Ošetriť `Activity.activityState == .dismissed` pred volaním `update()`. |
| 81 | **Prechod na letný/zimný čas (Daylight Saving) uprostred nočného tréningu** | Chyba vo výpočte trvania tréningu v štatistikách. | Výpočet dĺžky tréningu cez `Date().timeIntervalSince(startTime)`. |
| 82 | **Poškodený náhľadový obrázok (Thumbnail) stiahnutý z cloudu** | Pád aplikácie pri pokuse o zobrazenie poškodeného JPG. | Bezpečný guard `UIImage(data:)` s fallbackom na generickú ikonu tanca. |
| 83 | **Zablokovanie Face ID po 5 neúspešných pokusoch v tmavej sále** | Aplikácia neumožní prihlásenie tvárou. | Automatický plynulý fallback na zadanie hesla alebo biometrického kódu iPhonu. |
| 84 | **Zapnutý režim vysokého kontrastu v Nastaveniach prístupnosti** | Strata viditeľnosti jemných farieb na parkete. | Kontrola `@Environment(\.colorSchemeContrast)` a zosilnenie okrajov kariet. |
| 85 | **Uspanie aplikácie počas sťahovania zostavy z cloudu** | Sťahovanie zlyhá uprostred prenosu. | Konfigurácia `URLSessionConfiguration.background` pre sieťové úlohy. |
| 86 | **Detský účet (Family Sharing) s obmedzenými právami** | Zákaz prístupu k mikrofónu alebo cloudu. | Zobrazenie zrozumiteľného vysvetlenia namiesto nekonečného načítavania. |
| 87 | **Rýchle prepínanie kategórií tancov počas prehrávania videa** | Video z predchádzajúceho tanca hrá na pozadí nového. | Okamžité zastavenie a deallocácia prehrávača pri zmene tanca. |
| 88 | **Nedostatočná šírka pásma pri AirPlay 4K zrkadlení** | Sekanie obrazu na veľkej TV v tanečnej sále. | Ponúknuť zníženie rozlíšenia streamu na 1080p pre plynulých 60 FPS. |
| 89 | **Roztrasený statív pri dynamických skokoch na parkete** | Obraz z kamery vibruje a stráca ostrosť. | Automatická aktivácia hardvérovej stabilizácie senzora (Cinematic Stabilization). |
| 90 | **Import zostavy s neznámym budúcim ID tanca z novej verzie appky** | Staršia verzia aplikácie nerozpozná disciplínu. | Fallback na univerzálny tanec (*"Vlastný tanec"*) s možnosťou manuálneho zaradenia. |

---

## 🎯 Záver & Strategický Plán Implementácie

1. **Stav kamery je stabilný:** Natívny systém `UIImagePickerController` s bleskom vypnutým v predvolenom stave a pripravenou infraštruktúrou.
2. **Fáza 1 (Najbližšie vylepšenia kamery):**
   - Implementácia **Hands-Free Samospúšte (3s / 10s)** a **vodiacej mriežky (Grid)**.
   - Doplnenie **ochrany pred plným diskom** pred spustením videa.
3. **Fáza 2 (Súťažné a tréningové funkcie):**
   - **Side-by-Side porovnávací prehrávač** pre video rozbor techniky.
   - **Simulátor 5 tancov finále** s prepojením na Dynamic Island.
