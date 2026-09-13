# Canvas UI & Interaction Architecture Specification

Dokumentácia nového rozhrania Canvasu a rozbočovača zostáv pre aplikáciu **Ellegnote** vyhotovená na základe wireframe náčrtu a spätnej väzby používateľa.

---

## 1. Dvojúrovňová Architektúra Canvasu (Navigation Flow)

```
[ 📱 Spodný Dock: Tab 1 "Canvas" ]
                │
                ▼
┌─────────────────────────────────────────────────────────────┐
│  CHOREOGRAFIE                                               │
│  Moje Zostavy                         [ + Nová zostava ]    │
├─────────────────────────────────────────────────────────────┤
│  🔍 [ Hľadať zostavu alebo tanec...                       ]  │
│  ( Všetky )  ( Standard )  ( Latina )                       │
├─────────────────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────────────────┐  │
│  │ 🌟 ŠTANDARD                          [ ⊞ QR ]  [ ⋯ ]  │  │
│  │ QUICKSTEP • Súťažná zostava 2026                      │  │
│  │ ○───○───○───○ (Mini schéma choreografie)              │  │
│  │ 🟢 8 figúr • 📹 2 videá           Otvoriť plátno ➔     │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ 🔥 LATINA                            [ ⊞ QR ]  [ ⋯ ]  │  │
│  │ RUMBA • Základná variácia                             │  │
│  │ ○───○───○ (Mini schéma choreografie)                  │  │
│  │ 🔴 5 figúr • 📹 1 video           Otvoriť plátno ➔     │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                │
                ▼ (Kliknutie na kartičku zostavy)
┌─────────────────────────────────────────────────────────────┐
│ [ < Späť ]       Názov zostavy • Tanec       [ (QR) ] [ (...) ] │  <- Horná lišta (Liquid Glass)
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                                                             │
│                                   ┌───────────┐             │
│                                   │ Figúra 1  │             │
│                                   └─────┬─────┘             │
│                                         │ (prechod)         │
│                                         ▼                   │
│                                   ┌───────────┐             │
│                                   │ Figúra 2  │             │
│                                   └───────────┘             │
│                                                             │
│  [ TV ] (AirPlay)                                 [ ⟳ ]     │  <- Bočné tlačidlá odsadené 24pt od okrajov
│  [ ✏️ ] (Ceruza)                                   [ ⌖ ]     │  <- Umiestnené v dolnej tretine (thumb zone)
│                                                             │
│                   ┌───────────────────────┐                 │
│                   │ 🟢 Real time          │                 │  <- Znížený indikátor tesne nad dockom
│                   └───────────────────────┘                 │
├─────────────────────────────────────────────────────────────┤
│  [ 🏠 Domov ]   [ ▦ Canvas ]   [ 🎥 Kamera ]   [ 👤 Profil ]  │  <- Spodný Dock (MainTabView)
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Podrobný opis komponentov

### A. Výber mojich zostáv (`CanvasRoutinesHubView`)
Keď používateľ ťukne v spodnom docku na záložku **Canvas**, nezobrazí sa rovno náhodné plátno, ale **Výber mojich zostáv**:
1. **Responzívne Auto-Padding odsadenie**:
   - Všetky prvky (hlavička, vyhľadávanie, prepínače kategórií, kartičky zostáv) sú zabalené do jednotného zvislého scrollu s automatickým bočným odstupom `autoSidePadding = max(screenWidth * 0.08, 22)`.
   - Zodpovedá luxusnému štandardu z `ContentView` (8–10 % šírky displeja), čo chráni obsah pred orezaním na zaoblených hranách a fyzických rámčekoch iPhonov.
   - Spojovacie čiary v mini-schéme zostavy majú striktne ohraničenú šírku (20 pt), vďaka čomu kartičky nikdy nepretekajú cez okraje obrazovky.
2. **Hlavička s akčným tlačidlom**:
   - Titulok **"Moje Zostavy"** v luxusnom serif písme s odznakom kategórie a podporou dynamického škálovania písma.
   - Zlaté Liquid Glass tlačidlo **`+ Nová zostava`**, ktoré okamžite otvorí sprievodcu výberom tanca (`DanceCategorySelectionSheet`).
3. **Vyhľadávanie a kategórie**:
   - Vyhľadávacie pole s dymovým skleneným efektom na filtrovanie podľa názvu alebo tanca.
   - Prepínacie filtre: `Všetky`, `Standard` (modrý akcent), `Latina` (karmínový plameň) s kompaktným rozložením garantujúcim nulové pretekanie aj na najmenších iPhonoch (SE / mini).
   - Štatistická pilulka s celkovým počtom zostáv a figúr.
4. **Kartičky zostáv (Choreography Cards)**:
   - Každá zostava má vlastnú Liquid Glass kartičku s jemným farebným okrajom podľa disciplíny a `.frame(maxWidth: .infinity, alignment: .leading)`.
   - Odznak disciplíny (`ŠTANDARD` / `LATINA`), veľký názov tanca a názov zostavy.
   - **Mini schéma choreografie**: Grafická konštelácia uzlov a spojníc znázorňujúca tok figúr danej zostavy.
   - Počet figúr, počet videí, čas poslednej úpravy a rýchle tlačidlo na QR kód.
   - Ťuknutie na kartičku otvorí interaktívny Canvas danej zostavy.

---

### B. Obrazovka plátna zostavy (`RoutineCanvasView`)

1. **Horná lišta**:
   - **`< SPÄŤ`**: Elegantné tlačidlo návratu do výberu zostáv (`CanvasRoutinesHubView`).
   - **Stred**: Názov zostavy a tanca v zlatej typografii.
   - **Vpravo**: Dve Liquid Glass kruhové tlačidlá:
     - `QR CODE zostavy`: Generovanie zdieľacieho QR kódu danej zostavy.
     - `...`: Akčné menu (Pridať figúru, Duel videí, Inventár videí a fotiek).

2. **Bočné plávajúce panely (Umiestnené nad spodným dockom)**:
   - **Horizontálne odsadenie**: Tlačidlá majú bezpečné odsadenie **24 pt od okrajov obrazovky**, vďaka čomu nie sú orezané ani na zaoblených hranách moderných iPhonov.
   - **Vertikálne umiestnenie nad dockom**: Odsadenie zdola je zvýšené na **138 pt** (`padding(.bottom, 138)`), čím tlačidlá plávajú s luxusným odstupom 24 pt **priamo nad hornou hranou spodného docku** (dock výška 64 pt + 16 pt padding + safe area ~34 pt = 114 pt):
     - **Vľavo**:
       - `AirPlay share` (priame vysielanie na TV v sále cez `StudioAirPlayManager`).
       - `Ceruza` (prepínanie režimu voľného kreslenia a anotácií na parket).
     - **Vpravo**:
       - `Hrubý refresh` (okamžitá nútená synchronizácia zo Supabase pri výpadku WebSocketu).
       - `Vycentrovanie` (automatické dopočítanie rozmerov a animovaný zoom na celú zostavu).

3. **Indikátor "Real time"**:
   - Zdvihnutý na `padding(.bottom, isPresentedInTab ? max(geo.safeAreaInsets.bottom + 78, 120) : max(geo.safeAreaInsets.bottom + 16, 36))`, vďaka čomu sa nachádza v strede obrazovky tesne nad hornou krivkou docku (vertikálne zarovnaný k spodným hranám bočných tlačidiel).
   - Zobrazuje okamžitý stav spojenia WebSocket kanála a indikuje prebiehajúcu synchronizáciu.

---

## 3. Celoobrazovkové plátno (Edge-to-Edge) a stabilita pri odomknutí

1. **Odstránenie horného a dolného čierneho obdĺžnika**:
   - Pôvodný `GeometryReader` rešpektoval safe area displeja a orezával (`.clipped()`) mriežku parketu medzi horným a dolným safe area insetom. Tým vznikali pod hornou lištou a za spodným dockom čierne pásy.
   - Nové riešenie obaľuje celý pohľad do `GeometryReader { geo in ... }.ignoresSafeArea()`. Plátno (sieť, stred sály, figúry a spojnice) sa vykresľuje po celom fyzickom displeji od bodu `(0, 0)` až po spodnú hranu.
   - Horná lišta (`< Späť`, titulok, QR, `...`), bočné tlačidlá (AirPlay, Ceruza, Refresh, Scope), status pill aj spodný dock sú „prilepené“ (plávajú priamo nad priehľadným nekonečným plátnom).

2. **Eliminácia vertikálneho skoku pri odomknutí telefónu**:
   - **Príčina skoku**: Pri zamknutí a odomknutí iPhonu systém dočasne mení safe area insets (alebo ich nastaví na 0 pri lock screene). Ak `GeometryReader` neignoroval safe area, jeho výška sa zmenila a `clampedTranslation` prepočítal `verticalLimit`, čo posunulo stred plátna nahor. Zároveň `scenePhase` pri prebúdzaní mazal a znova vkladal figúry a spúšťal toast notifikáciu s animáciou.
   - **Riešenie**:
     - Vďaka `.ignoresSafeArea()` je rozmer `geo.size` zhodný s fyzickým displejom (`UIScreen.main.bounds`) a pri zamknutí/odomknutí sa nemení.
     - `onChange(of: geo.size)` je ošetrené prahom `abs(delta) > 5`, čím sa ignorujú mikroskopické prechody.
     - `refreshFromDB(userInitiated: false)` pri prebudení zo spánku aktualizuje existujúce figúry priamo na mieste bez ich mazania a nezobrazuje rušivý toast oznam. Plátno ostáva presne na pôvodnej pozícii.
