'use client'

import { useState, useActionState } from 'react'
import Image from 'next/image'
import { signIn, signUp } from '../actions'
import { createClient } from '@/lib/supabase/client'

type AuthState = { error?: string; success?: string }
const initialState: AuthState = {}

export default function LoginPage() {
  const [mode, setMode] = useState<'login' | 'register'>('login')
  const [googleLoading, setGoogleLoading] = useState(false)

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

  const handleGoogleSignIn = async () => {
    try {
      setGoogleLoading(true)
      const supabase = createClient()
      const { error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: `${window.location.origin}/auth/callback`,
        },
      })
      if (error) {
        setGoogleLoading(false)
        console.error('Google sign in error:', error.message)
      }
    } catch (e) {
      setGoogleLoading(false)
      console.error('Google sign in exception:', e)
    }
  }

  return (
    <div className="min-h-screen bg-[#060608] flex items-center justify-center px-4 py-8 relative overflow-hidden font-sans">
      
      {/* ── Outer Ambient Canvas Backlight ───────────────────────────── */}
      <div className="fixed top-1/4 right-1/4 w-[500px] h-[500px] bg-[#D4AF37]/15 rounded-full blur-[160px] pointer-events-none" />
      <div className="fixed bottom-1/4 left-1/4 w-[450px] h-[450px] bg-[#FFE088]/10 rounded-full blur-[140px] pointer-events-none" />

      {/* ── Glowing Card Container (Spotify-style) ───────────────────── */}
      <div className="glow-card-container">
        
        {/* Soft Radial Ambient Aura Bleed behind the Card */}
        <div className="glow-card-backdrop" />

        {/* The Card */}
        <div className="glow-card">
          
          {/* Logo */}
          <div className="relative mb-3 group">
            <div className="absolute inset-0 bg-[#D4AF37]/30 rounded-full blur-xl group-hover:blur-2xl transition-all" />
            <Image
              src="/logo.png"
              alt="Encore Official Logo"
              width={72}
              height={72}
              className="relative w-18 h-18 object-contain drop-shadow-[0_0_20px_rgba(212,175,55,0.6)]"
              priority
            />
          </div>

          {/* Brand Title (Encore) */}
          <h1 
            className="text-3xl font-black text-[#FFE088] tracking-wide mb-6"
            style={{ 
              fontFamily: 'var(--font-DelaGothicOne), sans-serif',
              textShadow: '0 0 25px rgba(212, 175, 55, 0.5)'
            }}
          >
            Encore
          </h1>

          {/* Form */}
          <form action={formAction} className="w-full flex flex-col gap-3.5">
            
            {mode === 'register' && (
              <input
                id="nickname"
                name="nickname"
                type="text"
                placeholder="Dancer Name / Nickname"
                required
                maxLength={60}
                autoComplete="name"
                className="glow-input"
              />
            )}

            <input
              id="email"
              name="email"
              type="email"
              placeholder="Email Address"
              required
              maxLength={254}
              autoComplete="email"
              className="glow-input"
            />

            <input
              id="password"
              name="password"
              type="password"
              placeholder="Password"
              required
              maxLength={128}
              autoComplete={mode === 'login' ? 'current-password' : 'new-password'}
              className="glow-input"
            />

            {/* Error Message */}
            {state?.error && (
              <div
                role="alert"
                aria-live="assertive"
                className="w-full p-3 rounded-xl bg-[#E11D48]/15 border border-[#E11D48]/60 text-[#F43F5E] text-xs font-medium text-center"
              >
                ⚠️ {state.error}
              </div>
            )}

            {/* Success Message */}
            {state?.success && (
              <div
                role="alert"
                aria-live="assertive"
                className="w-full p-3 rounded-xl bg-[#10B981]/15 border border-[#10B981]/60 text-[#10B981] text-xs font-medium text-center"
              >
                ✓ {state.success}
              </div>
            )}

            {/* Primary Login Button */}
            <button
              type="submit"
              disabled={pending}
              className="glow-btn-login mt-2"
            >
              {pending ? (
                <span className="flex items-center justify-center gap-2">
                  <svg className="animate-spin h-4 w-4 text-current" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                  </svg>
                  {mode === 'login' ? 'Logging in…' : 'Creating account…'}
                </span>
              ) : mode === 'login' ? (
                'Login'
              ) : (
                'Sign Up'
              )}
            </button>
          </form>

          {/* Forgot password link */}
          <div className="mt-3.5 mb-1 text-center">
            <button
              type="button"
              onClick={() => alert('Pre obnovenie hesla kontaktuj správcu alebo použi link zaslaný na email.')}
              className="text-xs text-white/50 hover:text-[#FFE088] transition-colors"
            >
              Forgot password?
            </button>
          </div>

          {/* Mode Switcher Link */}
          <div className="mt-2 text-center">
            <button
              type="button"
              onClick={() => setMode(mode === 'login' ? 'register' : 'login')}
              className="text-xs text-[#D4AF37] hover:text-[#FFE088] font-semibold transition-colors"
            >
              {mode === 'login' 
                ? 'Nemáš účet? Zaregistruj sa' 
                : 'Už máš účet? Prihlás sa'}
            </button>
          </div>

          {/* Quick Google Sign In */}
          <div className="w-full mt-6 pt-4 border-t border-white/10">
            <button
              type="button"
              onClick={handleGoogleSignIn}
              disabled={googleLoading}
              className="w-full py-3 px-4 rounded-xl bg-white/[0.04] hover:bg-white/[0.08] border border-[#D4AF37]/30 hover:border-[#D4AF37] text-white/90 hover:text-white text-xs font-semibold flex items-center justify-center gap-2.5 transition-all cursor-pointer shadow-[0_0_12px_rgba(212,175,55,0.12)] hover:shadow-[0_0_20px_rgba(212,175,55,0.25)]"
            >
              {googleLoading ? (
                <span className="animate-spin text-[#D4AF37]">●</span>
              ) : (
                <svg className="w-4.5 h-4.5 shrink-0" viewBox="0 0 24 24">
                  <path
                    d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                    fill="#4285F4"
                  />
                  <path
                    d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                    fill="#34A853"
                  />
                  <path
                    d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                    fill="#FBBC05"
                  />
                  <path
                    d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                    fill="#EA4335"
                  />
                </svg>
              )}
              <span>Continue with Google</span>
            </button>
          </div>

        </div>
      </div>
    </div>
  )
}
