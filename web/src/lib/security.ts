import { z } from 'zod'

// ── Auth schemas (OWASP A03 — Injection prevention via strict validation) ──
export const loginSchema = z.object({
  email: z
    .string()
    .min(1, 'Email je povinný')
    .email('Neplatný formát emailu')
    .max(254, 'Email je príliš dlhý')
    .toLowerCase()
    .trim(),
  password: z
    .string()
    .min(6, 'Heslo musí mať aspoň 6 znakov')
    .max(128, 'Heslo je príliš dlhé'),
})

export type LoginInput = z.infer<typeof loginSchema>

// ── Rate limiting store (in-memory, edge-safe) ──────────────────────────
// Security #14 — Rate limiting: max 10 login attempts per IP per minute
const attempts = new Map<string, { count: number; resetAt: number }>()

export function checkRateLimit(ip: string): { allowed: boolean; remaining: number } {
  const now = Date.now()
  const windowMs = 60_000 // 1 minute
  const maxAttempts = 10

  const entry = attempts.get(ip)
  if (!entry || entry.resetAt < now) {
    attempts.set(ip, { count: 1, resetAt: now + windowMs })
    return { allowed: true, remaining: maxAttempts - 1 }
  }

  entry.count += 1
  if (entry.count > maxAttempts) {
    return { allowed: false, remaining: 0 }
  }
  return { allowed: true, remaining: maxAttempts - entry.count }
}

// Clean up old entries periodically (prevent memory leak)
if (typeof setInterval !== 'undefined') {
  setInterval(() => {
    const now = Date.now()
    for (const [key, val] of attempts.entries()) {
      if (val.resetAt < now) attempts.delete(key)
    }
  }, 120_000)
}
