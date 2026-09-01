'use client'

import React, { useState } from 'react'
import { DownloadingLoopIcon } from './icons/DownloadingLoopIcon'

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
  filename = 'ellegnote-export.json'
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
