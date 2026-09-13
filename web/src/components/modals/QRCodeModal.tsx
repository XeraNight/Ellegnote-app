'use client'

import React, { useMemo } from 'react'
import { QRCodeSVG } from 'qrcode.react'
import { X, Smartphone, Sparkles } from 'lucide-react'

interface QRCodeModalProps {
  isOpen: boolean
  onClose: () => void
  userEmail: string
}

export default function QRCodeModal({ isOpen, onClose, userEmail }: QRCodeModalProps) {
  const syncPayload = useMemo(
    () =>
      JSON.stringify({
        app: 'Encore',
        user: userEmail,
        pairingCode: 'ENC-8429',
      }),
    [userEmail]
  )

  if (!isOpen) return null

  return (
    <div
      onClick={onClose}
      className="fixed inset-0 z-50 bg-black/80 backdrop-blur-md flex items-center justify-center p-4 select-none animate-fadeIn"
    >
      <div
        onClick={e => e.stopPropagation()}
        className="relative w-full max-w-sm rounded-3xl p-6 bg-gradient-to-b from-[#1b0812]/95 to-[#0b0307]/95 border border-[#D4AF37]/40 shadow-[0_25px_70px_rgba(0,0,0,0.9)] text-center space-y-5"
      >
        {/* Close Button */}
        <button
          onClick={onClose}
          className="absolute top-4 right-4 p-2 rounded-full bg-white/[0.06] hover:bg-white/[0.12] text-white/60 hover:text-white transition-colors cursor-pointer"
        >
          <X className="w-4 h-4" />
        </button>

        <div className="space-y-1">
          <div className="inline-flex items-center gap-1.5 px-3 py-0.5 rounded-full bg-[#D4AF37]/15 border border-[#D4AF37]/30 text-[#FFE088] text-[10px] font-black uppercase tracking-widest">
            <Sparkles className="w-3 h-3" />
            Mobilné Párovanie
          </div>
          <h3 className="text-xl font-black text-white">Naskenuj QR Kód</h3>
          <p className="text-xs text-white/50">
            Otvor aplikáciu Encore na iPhone a naskenuj tento kód pre okamžitú synchronizáciu.
          </p>
        </div>

        {/* QR Code Container with Gold Border */}
        <div className="p-4 rounded-2xl bg-white p-4 mx-auto w-fit shadow-[0_10px_30px_rgba(212,175,55,0.25)] border-2 border-[#D4AF37]/50">
          <QRCodeSVG value={syncPayload} size={180} fgColor="#000000" bgColor="#FFFFFF" level="H" />
        </div>

        {/* Pairing info */}
        <div className="p-3 rounded-2xl bg-white/[0.04] border border-white/[0.08] flex items-center justify-between text-xs">
          <div className="flex items-center gap-2 text-white/70">
            <Smartphone className="w-4 h-4 text-[#D4AF37]" />
            <span>Párovací kód:</span>
          </div>
          <span className="font-mono font-black text-[#FFE088] text-sm tracking-wider">
            ENC-8429
          </span>
        </div>

        <button
          onClick={onClose}
          className="w-full py-2.5 rounded-full bg-gradient-to-r from-[#D4AF37] to-[#B8861E] text-black font-black text-xs hover:brightness-110 active:scale-95 transition-all shadow-[0_4px_16px_rgba(212,175,55,0.4)] cursor-pointer"
        >
          Hotovo
        </button>
      </div>
    </div>
  )
}
