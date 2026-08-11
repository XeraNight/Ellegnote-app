'use client'

import { useActionState } from 'react'
import { signIn } from '../actions'

const initialState = { error: undefined as string | undefined }

export default function LoginPage() {
  const [state, formAction, pending] = useActionState(signIn, initialState)

  return (
    <div className="min-h-screen bg-[#0f0f10] flex items-center justify-center px-4">
      <div className="w-full max-w-sm">
        {/* Logo */}
        <div className="text-center mb-10">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-br from-[#c9a96e] to-[#8b6340] mb-4 shadow-xl">
            <span className="text-3xl">💃</span>
          </div>
          <h1 className="text-2xl font-bold text-white tracking-tight">Ellegnote</h1>
          <p className="text-[#888] text-sm mt-1">Dance practice manager</p>
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
              placeholder="tvoj@email.com"
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
              autoComplete="current-password"
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
                Prihlasovanie…
              </span>
            ) : (
              'Prihlásiť sa'
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
