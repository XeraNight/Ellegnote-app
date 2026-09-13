'use client'

import React, { useState } from 'react'
import type { SVGProps } from 'react'

export function DownloadingLoopIcon({ size = 24, ...props }: SVGProps<SVGSVGElement> & { size?: number }) {
  return (
    <svg width={size} height={size} xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" {...props}>
      <g fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2">
        <path strokeDasharray="32" d="M12 21c-4.97 0 -9 -4.03 -9 -9c0 -4.97 4.03 -9 9 -9">
          <animate fill="freeze" attributeName="stroke-dashoffset" dur="0.6s" values="32;0" />
        </path>
        <path strokeDasharray="2 4" strokeDashoffset="6" d="M12 3c4.97 0 9 4.03 9 9c0 4.97 -4.03 9 -9 9" opacity="0">
          <set fill="freeze" attributeName="opacity" begin="0.45s" to="1" />
          <animateTransform fill="freeze" attributeName="transform" begin="0.45s" dur="0.6s" type="rotate" values="-180 12 12;0 12 12" />
          <animate attributeName="stroke-dashoffset" begin="0.85s" dur="0.6s" repeatCount="indefinite" to="0" />
        </path>
        <path strokeDasharray="10" strokeDashoffset="10" d="M12 8v7.5">
          <animate fill="freeze" attributeName="stroke-dashoffset" begin="0.85s" dur="0.2s" to="0" />
        </path>
        <path strokeDasharray="8" strokeDashoffset="8" d="M12 15.5l3.5 -3.5M12 15.5l-3.5 -3.5">
          <animate fill="freeze" attributeName="stroke-dashoffset" begin="1.05s" dur="0.2s" to="0" />
        </path>
      </g>
    </svg>
  )
}

interface DownloadButtonProps {
  label?: string
  loadingLabel?: string
  successLabel?: string
  onDownload?: () => Promise<void> | void
  className?: string
  data?: unknown
  filename?: string
}

export function DownloadButton({
  label = 'Stiahnuť zostavy (JSON)',
  loadingLabel = 'Sťahujem...',
  successLabel = 'Stiahnuté!',
  onDownload,
  className = '',
  data,
  filename = 'encore-export.json'
}: DownloadButtonProps) {
  const [status, setStatus] = useState<'idle' | 'loading' | 'success'>('idle')

  const handleClick = async () => {
    if (status === 'loading') return
    setStatus('loading')

    try {
      if (onDownload) {
        await onDownload()
      } else if (data) {
        // Trigger browser file download
        const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' })
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = filename
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        URL.revokeObjectURL(url)
      }

      setStatus('success')
      setTimeout(() => setStatus('idle'), 2500)
    } catch (err) {
      console.error('Download failed:', err)
      setStatus('idle')
    }
  }

  return (
    <button
      onClick={handleClick}
      disabled={status === 'loading'}
      className={`inline-flex items-center gap-2.5 px-4 py-2.5 rounded-xl font-medium text-sm transition-all duration-300 ${
        status === 'success'
          ? 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/30'
          : 'bg-[#1a1a1c] hover:bg-[#222226] text-white border border-[#2a2a2e] hover:border-[#D4AF37]/50 shadow-sm active:scale-95'
      } ${className}`}
    >
      <span className={status === 'loading' ? 'text-[#D4AF37]' : 'text-current'}>
        <DownloadingLoopIcon size={18} />
      </span>
      <span>
        {status === 'loading'
          ? loadingLabel
          : status === 'success'
          ? successLabel
          : label}
      </span>
    </button>
  )
}
