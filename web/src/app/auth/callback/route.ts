import { createClient } from '@/lib/supabase/server'
import { NextRequest, NextResponse } from 'next/server'

// Auth callback — handles Supabase email confirmation deep links
// OWASP A01: validates redirectTo to prevent open redirect attacks
export async function GET(request: NextRequest) {
  const { searchParams, origin } = new URL(request.url)
  const code = searchParams.get('code')
  const next = searchParams.get('next') ?? '/dashboard'

  // Path traversal / open redirect protection (Security #20)
  const safePath = next.startsWith('/') ? next : '/dashboard'
  const userAgent = request.headers.get('user-agent') || ''
  const isIOS = /iPhone|iPad|iPod/i.test(userAgent)

  if (code) {
    const supabase = await createClient()
    const { error } = await supabase.auth.exchangeCodeForSession(code)
    if (!error) {
      if (isIOS) {
        return NextResponse.redirect(`${origin}/auth/confirm?type=login`)
      }
      return NextResponse.redirect(`${origin}${safePath}`)
    }
  }

  return NextResponse.redirect(`${origin}/login?error=invalid_link`)
}
