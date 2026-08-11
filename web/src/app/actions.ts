'use server'

import { redirect } from 'next/navigation'
import { headers } from 'next/headers'
import { createClient } from '@/lib/supabase/server'
import { loginSchema, checkRateLimit } from '@/lib/security'

export async function signIn(_: unknown, formData: FormData) {
  // ── Rate limiting (Security #14) ─────────────────────────────────────
  const headersList = await headers()
  const ip =
    headersList.get('x-forwarded-for')?.split(',')[0]?.trim() ??
    headersList.get('x-real-ip') ??
    'unknown'

  const { allowed } = checkRateLimit(ip)
  if (!allowed) {
    return { error: 'Príliš veľa pokusov. Skús to za minútu.' }
  }

  // ── Input validation with Zod (OWASP A03) ────────────────────────────
  const raw = {
    email: formData.get('email'),
    password: formData.get('password'),
  }

  const parsed = loginSchema.safeParse(raw)
  if (!parsed.success) {
    const msg = parsed.error.issues[0]?.message ?? 'Neplatné údaje'
    return { error: msg }
  }

  const { email, password } = parsed.data

  // ── Supabase auth ─────────────────────────────────────────────────────
  const supabase = await createClient()
  const { error } = await supabase.auth.signInWithPassword({ email, password })

  if (error) {
    // Generic message — don't reveal whether email exists (OWASP A07)
    return { error: 'Nesprávny email alebo heslo.', success: undefined }
  }

  redirect('/dashboard')
}

export async function signUp(_: unknown, formData: FormData) {
  const headersList = await headers()
  const ip =
    headersList.get('x-forwarded-for')?.split(',')[0]?.trim() ??
    headersList.get('x-real-ip') ??
    'unknown'

  const { allowed } = checkRateLimit(ip)
  if (!allowed) {
    return { error: 'Príliš veľa pokusov. Skús to za minútu.' }
  }

  const raw = {
    email: formData.get('email'),
    password: formData.get('password'),
  }

  const parsed = loginSchema.safeParse(raw)
  if (!parsed.success) {
    const msg = parsed.error.issues[0]?.message ?? 'Neplatné údaje'
    return { error: msg }
  }

  const { email, password } = parsed.data
  const supabase = await createClient()
  const { data, error } = await supabase.auth.signUp({ email, password })

  if (error) {
    return { error: `Registrácia zlyhala: ${error.message}` }
  }

  if (data.session) {
    redirect('/dashboard')
  }

  return { success: 'Účet bol vytvorený! Ak je zapnuté overenie emailu, skontroluj svoju schránku.' }
}

export async function signOut() {
  const supabase = await createClient()
  await supabase.auth.signOut()
  redirect('/login')
}
