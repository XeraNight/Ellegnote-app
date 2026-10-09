# Encore pre Apple Watch: plán verzie 1.1

Stav k 8. 10. 2026. Hodinky **nie sú súčasťou v1**. Vo v1 nie je žiadny watchOS target ani kód pre
hodinky (pôvodný `WatchCueingManager.swift` sa nikde nepoužíval a bol odstránený; jeho pokyny sú opísané
nižšie, aby sa nestratili). Tento dokument je kompletné zadanie, s ktorým sa po vydaní v1 dá začať.

## 1. Cieľ

Tanečník cíti tréning na zápästí bez pozerania na telefón, aj s rukou v tanečnom držaní:

- akcent na dobu 1 v takte (voliteľne každá doba),
- upozornenie takt pred zmenou figúry alebo ťažkým prechodom,
- zmenu figúry,
- koniec tanca,
- voliteľne tep, kalórie a trvanie tréningu v aplikácii Zdravie.

## 2. Rozsah v1.1

**Áno**
1. Spustenie zostavy na hodinkách: z iPhonu (plátno → „Spustiť na hodinkách“) alebo z hodiniek (zoznam zostáv).
2. Rytmické vibrácie podľa tempa tanca (takty za minútu) a počtu dôb v takte.
3. Na displeji názov aktuálnej a nasledujúcej figúry; vibrácia takt pred zmenou a pri zmene.
4. Koniec tanca dlhou vibráciou.
5. Tréning v Zdraví (`HKWorkoutSession`, typ `.socialDance`) iba so súhlasom používateľa.
6. Ak ostane čas: komplikácia / Smart Stack s najbližším tréningom z Plánu.

**Nie (neskôr)**: rozpoznávanie figúr z pohybu, analýza rise & fall z akcelerometra, synchronizácia dvoch
hodiniek v páre, ukladanie tepu na server.

## 3. Ako to bude fungovať (architektúra)

### Prečo rytmus odpočítavajú hodinky, nie telefón
Správy z iPhonu na hodinky (WatchConnectivity) meškajú nepredvídateľne, často o viac ako 100 ms.
V Quickstepe je medzi dobami asi 300 ms, takže by to bolo cítiť. Preto telefón pošle **celý plán
naraz** a hodinky si vibrácie odpočítavajú podľa vlastných hodín.

### Plán tréningu (posiela sa raz)
```json
{
  "routineId": "…",
  "dance": "Quickstep",
  "barsPerMinute": 50,
  "beatsPerBar": 4,
  "cues": { "everyBeat": false, "warnBarsBefore": 1 },
  "figures": [
    { "name": "Natural Spin Turn", "startBeat": 0, "lengthBeats": 6 },
    { "name": "Chasse from PP", "startBeat": 6, "lengthBeats": 4 }
  ]
}
```
- `lengthBeats` sa vypočíta z rytmu figúry (`CanvasNode.rhythm`). Formáty v appke sú rôzne
  („1, 2, 3“, „S Q Q“, „1 2 & 3“), preto treba **parser rytmu s testami** (S = 2 doby, Q = 1, „&“ = pol doby).
- Tempo tanca: z tabuľky v appke; **nič neodhadovať**, hodnoty potvrdiť podľa oficiálnych pravidiel
  (rovnaké pravidlo ako pri KSIS).

### Prenos
- `updateApplicationContext`: posledná verzia zoznamu zostáv (hodinky ju majú aj bez telefónu),
- `transferUserInfo`: zaradené zmeny,
- `sendMessage`: iba „štart / stop teraz“, keď sú hodinky dosiahnuteľné.
- Štart: najlepšie ťuknutím na hodinkách (žiadny problém so synchronizáciou času). Pri štarte z iPhonu
  pošle telefón „štart o 3 s“ a hodinky odpočítajú samy.

### Vibrácie (z pôvodného `WatchCueingManager`)
| Pokyn | Kedy | Haptika |
|---|---|---|
| `beatAccent` | doba 1 v takte | `.click` |
| `warning` | takt pred zmenou | `.directionUp` |
| `figureChange` | začiatok novej figúry | `.notification` |
| `finalGong` | koniec tanca | `.stop` |

Plánovač počíta s dátumom štartu (`Date`), nie s opakovaným `Timer`, aby sa tempo neposúvalo.
Silu vibrácií treba vyskúšať na zápästí počas tanca (možnosť dvojitého kliku pre silnejší akcent).

### Beh so zhasnutým displejom
Bez tréningovej relácie watchOS appku po zhasnutí displeja uspí. Správna cesta je **`HKWorkoutSession`
s typom `.socialDance`** (spoločenské tance) a režim na pozadí *Workout processing*.
`WKExtendedRuntimeSession` (mindfulness / self-care) na tanec **nepoužívať**, App Review to môže
považovať za zneužitie. Typ „Ballroom Dance“ v HealthKite neexistuje.

### Kód
- Spoločné jadro (čistý Swift, bez UI): `RoutineSchedule`, `RhythmParser`, výpočet časov, s unit testami.
- watchOS appka: `WatchSessionManager` (príjem plánu), `CueEngine` (plánovač + haptika),
  `WorkoutController` (HealthKit), jednoduché obrazovky: zoznam → tréning → súhrn.
- Na hodinkách stačí malá kópia dát (Codable súbor), nie SwiftData.

## 4. Súkromie a právo (nutné pred v1.1)

- **Tep je údaj o zdraví** (osobitná kategória, čl. 9 GDPR). Treba výslovný súhlas a jasný účel.
- Odporúčanie: tep, kalórie a tréningy **zostanú v aplikácii Zdravie na zariadení** a Encore ich
  neposiela na server. Do zásad pribudne sekcia „Apple Watch a Zdravie“.
- HealthKit dáta sa nesmú použiť na reklamu ani predať (Guideline 5.1.3). Encore reklamu nemá.
- `Info.plist`: `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription` (slovenské texty).
- App Store Connect: aktualizovať App Privacy (ak by dáta zo Zdravia niekedy odchádzali zo zariadenia)
  a dotazník vekového hodnotenia (otázka o medicínskych / wellness témach).

## 5. Nastavenie v Xcode (urobíš ty, ostatné napíšem ja)

| Pole | Hodnota |
|---|---|
| Šablóna | watchOS → App |
| Product Name | `EncoreWatch` (bez pomlčky) |
| Team | tvoj platený tím, rovnaký ako iPhone appka |
| Organization Identifier | `com.jakub` (iPhone appka je `com.jakub.encore`) |
| Typ | **Watch App for Existing iOS App** → **Encore** (bundle ID bude `com.jakub.encore.watchkitapp`) |
| Testing System | None (testy jadra budú v `EncoreTests`) |

Potom na watch targete: Capabilities → **HealthKit**, Background Modes → **Workout processing**.
Minimálna verzia watchOS 26 (Series 6 a novšie, SE 2. gen a novšie, Ultra).

## 6. Poradie práce

1. Jadro: `RoutineSchedule`, `RhythmParser`, výpočet časov + testy (dá sa urobiť aj bez hodiniek).
2. Watch target + príjem plánu + zoznam zostáv.
3. `CueEngine` + haptika, ladenie na zápästí.
4. `HKWorkoutSession`, súhlas, súhrn tréningu.
5. iPhone: tlačidlo „Spustiť na hodinkách“, nastavenia pokynov.
6. Rozhodnúť plán predplatného (Plus / Premium). Do paywallu pridať až keď funkcia funguje.
7. Zásady ochrany súkromia, App Privacy, vekové hodnotenie.
8. Testovanie: spárované simulátory → tvoje hodinky (Series 12) → TestFlight s partnerkou.
9. Poznámky pre App Review: ako funkciu otestovať (krátke video z tréningu pomôže).

## 7. Riziká

- Slabá vibrácia počas pohybu → vyskúšať vzory, prípadne dvojitý klik.
- Batéria: tréningová relácia míňa viac → automatické ukončenie po tanci / po 2 hodinách.
- Presnosť tempa → plánovanie podľa času štartu, testy výpočtu.
- Zamietnutie: watch appka musí fungovať (nie prázdna) a HealthKit iba ak ho naozaj používame.
