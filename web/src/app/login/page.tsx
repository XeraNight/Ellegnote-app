'use client'

import { useState, useActionState } from 'react'
import { signIn, signUp } from '../actions'

type AuthState = { error?: string; success?: string }
const initialState: AuthState = {}

export default function LoginPage() {
  const [mode, setMode] = useState<'login' | 'register'>('login')

  const [state, formAction, pending] = useActionState(
    async (prevState: AuthState, formData: FormData): Promise<AuthState> => {
      if (mode === 'login') {
        return await signIn(prevState, formData)
      } else {
        return await signUp(prevState, formData)
      }
    },
    initialState
  )

  return (
    <div className="min-h-screen bg-[#050505] flex items-center justify-center px-4 relative overflow-hidden font-sans">
      
      {/* ── Ambient Background Glows ─────────────────────────────────── */}
      <div className="fixed top-[-100px] left-[-100px] w-[500px] h-[500px] bg-[#D4AF37]/10 rounded-full blur-[140px] pointer-events-none" />
      <div className="fixed bottom-[-100px] right-[-100px] w-[500px] h-[500px] bg-[#3B82F6]/10 rounded-full blur-[150px] pointer-events-none" />

      <div className="w-full max-w-md relative z-10">
        
        {/* Logo & Header */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-br from-[#D4AF37]/20 to-[#FFE088]/5 border border-[#D4AF37]/30 mb-4 shadow-xl shadow-[#D4AF37]/10">
            <span className="text-3xl">💃</span>
          </div>
          <h1 className="text-2xl font-black text-white tracking-wider">ELLEGNOTE</h1>
          <p className="text-xs text-[#D4AF37] font-medium tracking-wide mt-1">Creative Dance Workspace</p>
        </div>

        {/* Liquid Glass Card Container */}
        <div className="bg-[#0e0e12]/85 backdrop-blur-2xl border border-white/[0.08] hover:border-[#D4AF37]/30 rounded-3xl p-6 sm:p-8 shadow-2xl shadow-black/80 transition-all">
          
          {/* Mode Toggle Pills */}
          <div className="flex bg-white/[0.04] p-1 rounded-2xl mb-6 border border-white/[0.06]">
            <button
              type="button"
              onClick={() => setMode('login')}
              className={`flex-1 py-2 text-xs font-bold rounded-xl transition-all ${
                mode === 'login'
                  ? 'bg-gradient-to-r from-[#D4AF37] to-[#FFE088] text-[#050505] shadow-md shadow-[#D4AF37]/20'
                  : 'text-white/60 hover:text-white'
              }`}
            >
              Prihlásenie
            </button>
            <button
              type="button"
              onClick={() => setMode('register')}
              className={`flex-1 py-2 text-xs font-bold rounded-xl transition-all ${
                mode === 'register'
                  ? 'bg-gradient-to-r from-[#D4AF37] to-[#FFE088] text-[#050505] shadow-md shadow-[#D4AF37]/20'
                  : 'text-white/60 hover:text-white'
              }`}
            >
              Vytvoriť účet
            </button>
          </div>

          {/* Auth Form */}
          <form action={formAction} className="space-y-4">
            <div>
              <label htmlFor="email" className="block text-xs font-semibold text-white/70 mb-1.5">
                Emailová adresa
              </label>
              <input
                id="email"
                name="email"
                type="email"
                autoComplete="email"
                required
                maxLength={254}
                placeholder="partnerka@ellegnote.com"
                className="w-full px-4 py-3 rounded-2xl bg-white/[0.04] border border-white/10 text-white text-sm placeholder-white/30 focus:outline-none focus:border-[#D4AF37]/60 focus:ring-1 focus:ring-[#D4AF37]/40 transition-all"
              />
            </div>

            <div>
              <label htmlFor="password" className="block text-xs font-semibold text-white/70 mb-1.5">
                Heslo
              </label>
              <input
                id="password"
                name="password"
                type="password"
                autoComplete={mode === 'login' ? 'current-password' : 'new-password'}
                required
                maxLength={128}
                placeholder="••••••••••••"
                className="w-full px-4 py-3 rounded-2xl bg-white/[0.04] border border-white/10 text-white text-sm placeholder-white/30 focus:outline-none focus:border-[#D4AF37]/60 focus:ring-1 focus:ring-[#D4AF37]/40 transition-all"
              />
            </div>

            {state?.error && (
              <div
                role="alert"
                aria-live="assertive"
                className="px-4 py-3 rounded-2xl bg-[#E11D48]/15 border border-[#E11D48]/30 text-[#F43F5E] text-xs font-medium"
              >
                {state.error}
              </div>
            )}

            {state?.success && (
              <div
                role="alert"
                aria-live="assertive"
                className="px-4 py-3 rounded-2xl bg-[#10B981]/15 border border-[#10B981]/30 text-[#10B981] text-xs font-medium"
              >
                {state.success}
              </div>
            )}

            <button
              type="submit"
              disabled={pending}
              className="w-full py-3.5 px-4 rounded-2xl bg-gradient-to-r from-[#D4AF37] to-[#FFE088] text-[#050505] font-black text-sm hover:opacity-95 active:scale-[0.98] transition-all disabled:opacity-50 disabled:cursor-not-allowed shadow-lg shadow-[#D4AF37]/25 mt-2"
            >
              {pending ? (
                <span className="flex items-center justify-center gap-2">
                  <svg className="animate-spin h-4 w-4" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                  </svg>
                  {mode === 'login' ? 'Prihlasovanie…' : 'Vytváranie účtu…'}
                </span>
              ) : mode === 'login' ? (
                'Vstúpiť do štúdia'
              ) : (
                'Založiť tanečný účet'
              )}
            </button>
          </form>
        </div>

        <p className="text-center text-white/30 text-xs mt-6">
          Ellegnote · Ballroom & Latin Workspace
        </p>
      </div>
    </div>
  )
}
