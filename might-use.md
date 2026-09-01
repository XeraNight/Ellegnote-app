# 🎨 MIGHT-USE — Knižnica Animovaných SVG Ikon & UI Komponentov

Táto knižnica obsahuje pripravené animované SVG ikony pre React / Next.js web aj natívne iOS aplikácie.

---

## 1. 🏠 HomeIcon (Animovaný Domček)
Plynulá animácia vykreslenia podlahy, stien, strechy a dverí.

```tsx
import type { SVGProps } from "react"

export function HomeIcon({ size = 24, ...props }: SVGProps<SVGSVGElement> & { size?: number }) {
  return (
    <svg width={size} height={size} xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" {...props}>
      <g fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2">
        <path strokeDasharray="18" d="M4.5 21.5h15">
          <animate fill="freeze" attributeName="stroke-dashoffset" dur="0.3s" values="18;0" />
        </path>
        <path strokeDasharray="16" strokeDashoffset="16" d="M4.5 21.5v-13.5M19.5 21.5v-13.5">
          <animate fill="freeze" attributeName="stroke-dashoffset" begin="0.3s" dur="0.3s" to="0" />
        </path>
        <path strokeDasharray="28" strokeDashoffset="28" d="M2 10l10 -8l10 8">
          <animate fill="freeze" attributeName="stroke-dashoffset" begin="0.6s" dur="0.4s" to="0" />
        </path>
        <path strokeDasharray="26" strokeDashoffset="26" d="M9.5 21.5v-9h5v9">
          <animate fill="freeze" attributeName="stroke-dashoffset" begin="0.9s" dur="0.6s" to="0" />
        </path>
      </g>
    </svg>
  )
}
```

---

## 2. 👁️ VisionIcon (Animované Oko & AI Vision)
Ideálna pre tlačidlá: *Posture Analysis*, *Ghost Camera*, *Live Pose Tracking*, *Vision AI*.

```tsx
import type { SVGProps } from "react"

export function VisionIcon({ size = 24, ...props }: SVGProps<SVGSVGElement> & { size?: number }) {
  return (
    <svg width={size} height={size} xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" {...props}>
      <g fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2">
        <path
          strokeDasharray="36"
          strokeDashoffset="36"
          d="M2 12c2.5 -5 6.5 -8 10 -8c3.5 0 7.5 3 10 8c-2.5 5 -6.5 8 -10 8c-3.5 0 -7.5 -3 -10 -8Z"
        >
          <animate fill="freeze" attributeName="stroke-dashoffset" dur="0.5s" to="0" />
        </path>
        <path
          strokeDasharray="14"
          strokeDashoffset="14"
          d="M12 9a3 3 0 1 1 0 6a3 3 0 0 1 0 -6Z"
        >
          <animate fill="freeze" attributeName="stroke-dashoffset" begin="0.4s" dur="0.3s" to="0" />
        </path>
        <circle cx="12" cy="12" r="1" fill="currentColor" opacity="0">
          <set fill="freeze" attributeName="opacity" begin="0.7s" to="1" />
          <animate
            attributeName="r"
            values="1;1.6;1"
            dur="2s"
            repeatCount="indefinite"
            begin="0.7s"
          />
        </circle>
      </g>
    </svg>
  )
}
```

---

## 3. 📥 DownloadingLoopIcon (Animované Sťahovanie & Loop)
Pre export dát, ukladanie zostáv a zálohovanie.

```tsx
import type { SVGProps } from "react"

export function DownloadingLoopIcon({ size = 24, ...props }: SVGProps<SVGSVGElement> & { size?: number }) {
  return (
    <svg width={size} height={size} xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" {...props}>
      <g fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2">
        <path strokeDasharray="32" d="M12 21c-4.97 0 -9 -4.03 -9 -9c0 -4.97 4.03 -9 9 -9">
          <animate fill="freeze" attributeName="stroke-dashoffset" dur="0.6s" values="32;0"/>
        </path>
        <path strokeDasharray="2 4" strokeDashoffset="6" d="M12 3c4.97 0 9 4.03 9 9c0 4.97 -4.03 9 -9 9" opacity="0">
          <set fill="freeze" attributeName="opacity" begin="0.45s" to="1"/>
          <animateTransform fill="freeze" attributeName="transform" begin="0.45s" dur="0.6s" type="rotate" values="-180 12 12;0 12 12"/>
          <animate attributeName="stroke-dashoffset" begin="0.85s" dur="0.6s" repeatCount="indefinite" to="0"/>
        </path>
        <path strokeDasharray="10" strokeDashoffset="10" d="M12 8v7.5">
          <animate fill="freeze" attributeName="stroke-dashoffset" begin="0.85s" dur="0.2s" to="0"/>
        </path>
        <path strokeDasharray="8" strokeDashoffset="8" d="M12 15.5l3.5 -3.5M12 15.5l-3.5 -3.5">
          <animate fill="freeze" attributeName="stroke-dashoffset" begin="1.05s" dur="0.2s" to="0"/>
        </path>
      </g>
    </svg>
  )
}
```
