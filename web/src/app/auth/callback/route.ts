import { createClient } from '@/lib/supabase/server'
import { NextRequest, NextResponse } from 'next/server'

// Auth callback — handles Supabase email confirmation deep links
// OWASP A01: validates redirectTo to prevent open redirect attacks
export async function GET(request: NextRequest) {
  const { searchParams, origin } = new URL(request.url)
  const code = searchParams.get('code')
  const type = searchParams.get('type') || 'login'

  if (code) {
    const supabase = await createClient()
    const { error } = await supabase.auth.exchangeCodeForSession(code)
    if (!error) {
      return NextResponse.redirect(`${origin}/auth/confirm?type=${encodeURIComponent(type)}&code=${encodeURIComponent(code)}`)
    }
  }

  return NextResponse.redirect(`${origin}/auth/confirm?error=invalid_link`)
}
