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
    <div className="min-h-screen bg-[#0f0f10] flex items-center justify-center px-4">
      <div className="w-full max-w-sm">
        {/* Logo */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-br from-[#c9a96e] to-[#8b6340] mb-4 shadow-xl">
            <span className="text-3xl">💃</span>
          </div>
          <h1 className="text-2xl font-bold text-white tracking-tight">Ellegnote</h1>
          <p className="text-[#888] text-sm mt-1">Dance practice manager</p>
        </div>

        {/* Mode Toggle */}
        <div className="flex bg-[#1a1a1c] p-1 rounded-xl mb-6 border border-[#2a2a2e]">
          <button
            type="button"
            onClick={() => setMode('login')}
            className={`flex-1 py-2 text-xs font-semibold rounded-lg transition-all ${
              mode === 'login'
                ? 'bg-[#c9a96e] text-black shadow'
                : 'text-[#888] hover:text-white'
            }`}
          >
            Prihlásenie
          </button>
          <button
            type="button"
            onClick={() => setMode('register')}
            className={`flex-1 py-2 text-xs font-semibold rounded-lg transition-all ${
              mode === 'register'
                ? 'bg-[#c9a96e] text-black shadow'
                : 'text-[#888] hover:text-white'
            }`}
          >
            Vytvoriť účet
          </button>
        </div>

        {/* Form */}
        <form action={formAction} className="space-y-4">
          <div>
            <label htmlFor="email" className="block text-sm font-medium text-[#ccc] mb-1.5">
              Email
            </label>
            <input
              id="email"
              name="email"
              type="email"
              autoComplete="email"
              required
              maxLength={254}
              placeholder="partnerka@email.com"
              className="w-full px-4 py-3 rounded-xl bg-[#1a1a1c] border border-[#2a2a2e] text-white placeholder-[#555] focus:outline-none focus:ring-2 focus:ring-[#c9a96e] focus:border-transparent transition-all"
            />
          </div>

          <div>
            <label htmlFor="password" className="block text-sm font-medium text-[#ccc] mb-1.5">
              Heslo
            </label>
            <input
              id="password"
              name="password"
              type="password"
              autoComplete={mode === 'login' ? 'current-password' : 'new-password'}
              required
              maxLength={128}
              placeholder="••••••••"
              className="w-full px-4 py-3 rounded-xl bg-[#1a1a1c] border border-[#2a2a2e] text-white placeholder-[#555] focus:outline-none focus:ring-2 focus:ring-[#c9a96e] focus:border-transparent transition-all"
            />
          </div>

          {state?.error && (
            <div
              role="alert"
              aria-live="assertive"
              className="px-4 py-3 rounded-xl bg-red-950/50 border border-red-800/40 text-red-400 text-sm"
            >
              {state.error}
            </div>
          )}

          {state?.success && (
            <div
              role="alert"
              aria-live="assertive"
              className="px-4 py-3 rounded-xl bg-emerald-950/50 border border-emerald-800/40 text-emerald-400 text-sm"
            >
              {state.success}
            </div>
          )}

          <button
            type="submit"
            disabled={pending}
            className="w-full py-3 px-4 rounded-xl bg-gradient-to-r from-[#c9a96e] to-[#b8884a] text-white font-semibold text-sm hover:opacity-90 active:scale-[0.98] transition-all disabled:opacity-50 disabled:cursor-not-allowed shadow-lg shadow-[#c9a96e]/20 mt-2"
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
              'Prihlásiť sa'
            ) : (
              'Vytvoriť nový účet'
            )}
          </button>
        </form>

        <p className="text-center text-[#444] text-xs mt-8">
          Ellegnote · Privátna aplikácia
        </p>
      </div>
    </div>
  )
}
