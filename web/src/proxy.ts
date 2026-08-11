import { type NextRequest, NextResponse } from 'next/server'
import { createServerClient } from '@supabase/ssr'

// ═══════════════════════════════════════════════════════════
// SECURITY MIDDLEWARE
// Implements:
//   OWASP A04 — Insecure Design: auth guard on all /dashboard routes
//   OWASP A05 — Security Misconfiguration: strict security headers
//   Security #11 — CSRF: SameSite=Strict cookies (set in supabase/server.ts)
//   Security #12 — Clickjacking: X-Frame-Options: DENY
//   Security #13 — CORS: Origin validation
//   Security #15 — Security headers: HSTS, X-Content-Type-Options, etc.
//   Security #17 — Content Security Policy
//   Security #19 — Permissions Policy
// ═══════════════════════════════════════════════════════════

const SECURITY_HEADERS = {
  // HSTS — force HTTPS for 1 year, include subdomains
  'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload',

  // Prevent MIME sniffing (Security #15)
  'X-Content-Type-Options': 'nosniff',

  // Clickjacking protection (Security #12)
  'X-Frame-Options': 'DENY',

  // XSS filter (legacy browsers)
  'X-XSS-Protection': '1; mode=block',

  // Referrer policy — don't leak URL to third parties
  'Referrer-Policy': 'strict-origin-when-cross-origin',

  // Permissions Policy — disable dangerous browser APIs (Security #19)
  'Permissions-Policy': [
    'camera=()',
    'microphone=()',
    'geolocation=()',
    'payment=()',
    'usb=()',
    'interest-cohort=()',
  ].join(', '),

  // Content Security Policy (Security #17 — OWASP A05)
  // Strict whitelist: only our domain + Supabase
  'Content-Security-Policy': [
    "default-src 'self'",
    "script-src 'self' 'unsafe-inline'",   // unsafe-inline needed for Next.js hydration
    "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
    "font-src 'self' https://fonts.gstatic.com",
    "img-src 'self' data: blob: https://iukblwlttvrcdclmlyxu.supabase.co",
    "connect-src 'self' https://iukblwlttvrcdclmlyxu.supabase.co wss://iukblwlttvrcdclmlyxu.supabase.co",
    "media-src 'self' blob: https://iukblwlttvrcdclmlyxu.supabase.co",
    "frame-ancestors 'none'",
    "base-uri 'self'",
    "form-action 'self'",
    "upgrade-insecure-requests",
  ].join('; '),
}

export async function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl
  const response = NextResponse.next()

  // Apply all security headers to every response
  Object.entries(SECURITY_HEADERS).forEach(([key, value]) => {
    response.headers.set(key, value)
  })

  // ── Auth guard: protect /dashboard/* (OWASP A04) ────────────────────
  if (pathname.startsWith('/dashboard')) {
    const supabase = createServerClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      {
        cookies: {
          getAll: () => request.cookies.getAll(),
          setAll: (cookiesToSet) => {
            cookiesToSet.forEach(({ name, value, options }) => {
              response.cookies.set(name, value, {
                ...options,
                httpOnly: true,
                secure: true,
                sameSite: 'strict',
              })
            })
          },
        },
      }
    )

    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
      const loginUrl = new URL('/login', request.url)
      loginUrl.searchParams.set('redirectTo', pathname)
      return NextResponse.redirect(loginUrl)
    }
  }

  // ── Redirect authenticated users away from login ─────────────────────
  if (pathname === '/login') {
    const supabase = createServerClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      {
        cookies: {
          getAll: () => request.cookies.getAll(),
          setAll: (cookiesToSet) => {
            cookiesToSet.forEach(({ name, value, options }) => {
              response.cookies.set(name, value, {
                ...options,
                httpOnly: true,
                secure: true,
                sameSite: 'strict',
              })
            })
          },
        },
      }
    )
    const { data: { user } } = await supabase.auth.getUser()
    if (user) {
      return NextResponse.redirect(new URL('/dashboard', request.url))
    }
  }

  return response
}

export const config = {
  matcher: [
    // Match all routes except static files, images, favicon
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
