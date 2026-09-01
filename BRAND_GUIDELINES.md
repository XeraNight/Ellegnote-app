# 🏛️ Ellegnote Brand Identity & Design System Guide
### *Inšpirované estetikou Ellegance.sk, Apple Human Interface Guidelines a Športovým Luxusom*

Tento dokument definuje oficiálnu vizuálnu identitu, farebnú paletu, typografiu a systém UI komponentov (tlačidiel a kariet figúr) pre aplikáciu **Ellegnote**.

---

## 👑 1. Oficiálne Logo & Emblém (Sculptural Ribbon Mark)

Oficiálnym symbolom Ellegnote je **Sculptural Ribbon Mark (Variant 3B)**:
* **Koncept:** Spojitá 3D/vektorová stuha zo saténového šampanského zlata na hlbokom matnom obsidiáne (`#080808`).
* **Geometria:** Horná slučka stuhy znázorňuje siluetu štandardného tanečného držania v páre (Standard Dance Frame & Lady's Sway), ktorá plynule prechádza do kaligrafického písmena **„E“** (Ellegnote / Ellegance).
* **Assety v projekte:**
  * `Ellegnote/Assets.xcassets/AppIcon.appiconset/` (1024x1024 Universal, Dark Mode, Tinted Mode).
  * `Ellegnote/Assets.xcassets/EllegnoteLogo.imageset/` (`ellegnote_logo.png`).
  * `brand_assets/xcode_3d_layers/Ellegnote3D.imagestack/` (4-vrstvový priestorový asset pre Xcode a visionOS).

---

## 🎨 2. Oficiálna Farebná Paleta (Color Tokens)

### A. Primárna Paleta (Core Brand Colors)
* **🖤 Obsidian Black (`#080808` / `#0D0D0E`)**: Hlboká zamatová čierna. Základ pre App Icon, Dynamic Island, nočný režim a karty.
* **🏆 Champagne Gold (`#D4AF37` / `#F3E5AB`)**: Šampanské zlato. Farba úspechu, emblému, finálových bodov a aktívnych stavov.
* **🍦 Silk Ivory / Warm Cream (`#FBF9F5` / `#F5F2EB`)**: Hodvábny krémový podklad. Zabezpečuje príjemný kontrast pre oči pri dlhom štúdiu choreografií v sále.
* **🤍 Pure Card White (`#FFFFFF`)**: Čistá biela pre vyvýšené karty figúr na krémovom pozadí.

### B. Tanečné a Funkčné Akcenty (Discipline & Utility Codes)
* **💃 Latin Crimson (`#E11D48`)**: Vášeň, latinskoamerické tance (Samba, Cha-Cha, Rumba, Paso, Jive), nahrávanie videa (`REC`).
* **👔 Standard Royal Blue (`#1E40AF` / `#3B82F6`)**: Noblesa, štandardné tance (Waltz, Tango, Valčík, Slowfox, Quickstep), trénerské komentáre.
* **🌿 Emerald Sync (`#10B981`)**: Živá synchronizácia, úspešné uloženie, perfektný timing.
* **⚠️ Warning Amber (`#F59E0B`)**: Upozornenia na techniku, držanie rámu, stredný stav batérie.

---

## ✍️ 2. Typografický Systém (Typography Hierarchy)

| Úroveň | Písmo (Font) | Veľkosť & Rez | Použitie |
| :--- | :--- | :--- | :--- |
| **Display Title** | *New York / Playfair / SF Pro Display* | `28–34 pt`, Bold/Black | Názvy tancov, finálové kategórie, titulky obrazoviek |
| **Figure Headline** | *SF Pro Text / Inter* | `17–20 pt`, Bold/Heavy | Názov figúry (napr. *"Natural Spin Turn"*) |
| **Technical Body** | *SF Pro Text* | `14–15 pt`, Regular/Medium | Technický popis nášľapu, rotácie, sklony tela |
| **Badge & Chip** | *SF Pro Rounded* | `11–12 pt`, Heavy, All-Caps | Značky nášľapov (`TH`, `HT`), smer (`LOD`, `DW`) |
| **Timing & Digits** | *SF Mono / SF Pro Rounded* | `14–32 pt`, Heavy Monospace | Metronóm, počítadlo dôb (`1 2 3`), stopky |

---

## 🔘 3. Systém Tlačidiel (Button UI Hierarchy)

### 1. Primárne CTA Tlačidlo (Primary Luxury Button)
* **Vzhľad**: Zamatovo čierne pozadie (`#0D0D0E`) so zlatým textom a ikonou (`#D4AF37`), alebo plné šampanské zlato s čiernym textom.
* **Okraj**: Jemný `1px` svetlejší zlatý lem (`rgba(212, 175, 55, 0.35)`).
* **Tieň**: Mäkký rozptýlený tieň `shadow(color: black.opacity(0.15), radius: 14, y: 5)`.
* **Rohy**: Zaoblenie `16 pt` (moderná elegantná kapsula).
* **Haptika**: `UIImpactFeedbackGenerator(style: .medium)`.

### 2. Sekundárne Sklenené Tlačidlo (Frosted Glass Button)
* **Vzhľad**: Priehľadné/biele matné sklo (`.ultraThinMaterial` / `Color.white.opacity(0.85)`).
* **Okraj**: `1px` jemný neutrálny okraj (`#E5E7EB` alebo zlatý odtieň).
* **Použitie**: Filtre, sekundárne akcie, tlačidlo "Upraviť", "Zdieľať zostavu".

### 3. Tanečné Kapsulové Filtre (Discipline Pill Chips)
* **Vzhľad**: Malé 32pt kapsule (`Capsule()`).
* **Stav Aktívny**: Zlaté alebo karmínové pozadie s bielym/čiernym písmom.
* **Stav Neaktívny**: Biela karta s jemným šedým písmom a 1px okrajom.

---

## 🗂️ 4. Systém Kariet Figúr (Figure Card UI Architecture)

Karta figúry je kľúčový element celej aplikácie. Je rozdelená do 4 prehľadných zón:

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ 💃 WALTZ  •  Figúra #03              [ SQQ ] (Timing)          ↗ LOD (Smer)            │
├────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                        │
│  Natural Spin Turn                                            [ ★★★★★ ] (Mastery)      │
│  Pravá noha vpred, zníženie a silná rotácia 3/8 vpravo.                                │
│                                                                                        │
├────────────────────────────────────────────────────────────────────────────────────────┤
│  [ 🦶 T-H (Pán) ]  [ 🦶 H-T (Dáma) ]  [ 📐 Náklon: Vpravo ]  [ 🎙️ Tréner: 1 poznámka ] │
├────────────────────────────────────────────────────────────────────────────────────────┤
│  ┌────────────────────────────────────────────────────────┐                            │
│  │ 🎬 Video ukážka: 00:14 (HD)       [ 👁️ Porovnať ]     │                            │
│  └────────────────────────────────────────────────────────┘                            │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

### Kľúčové atribúty karty:
1. **Základňa**: Biela karta (`#FFFFFF`) na hodvábnom krémovom pozadí (`#FBF9F5`).
2. **Fazeta**: `1px` prémiový svetlozlatý/sklenený lem (`rgba(212, 175, 55, 0.20)`).
3. **Zaoblenie**: `20 pt` pre maximálnu modernosť a ergonómiu pri scrollovaní.
4. **Hĺbka**: Mäkký ambientný tieň bez tvrdých komiksových obrysov.
