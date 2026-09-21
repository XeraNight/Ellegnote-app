import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

export const runtime = 'nodejs'
export const dynamic = 'force-dynamic'

// MARK: - Public Invite Details Endpoint
// Returns non-sensitive public profile details (name, club, avatar) by invite_code
export async function GET(
  request: NextRequest,
  context: { params: Promise<{ code: string }> }
) {
  try {
    const { code } = await context.params
    const cleanCode = (code || '').trim().toUpperCase()

    if (!cleanCode || cleanCode.length < 4 || cleanCode.length > 12) {
      return NextResponse.json(
        { error: 'invalid_code', message: 'Neplatný formát kódu pozvánky.' },
        { status: 400 }
      )
    }

    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://iukblwlttvrcdclmlyxu.supabase.co'
    const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''
    const supabase = createClient(supabaseUrl, supabaseAnonKey)

    // Query profile by invite_code
    const { data: profile, error } = await supabase
      .from('profiles')
      .select('name, club, avatar_url, invite_code')
      .eq('invite_code', cleanCode)
      .single()

    if (error || !profile) {
      return NextResponse.json(
        { error: 'not_found', message: 'Tanečník s týmto kódom pozvánky sa nenašiel.' },
        { status: 404 }
      )
    }

    return NextResponse.json(
      {
        success: true,
        invite: {
          code: profile.invite_code,
          name: profile.name || 'Tanečník',
          club: profile.club || '',
          avatarUrl: profile.avatar_url || null
        }
      },
      {
        status: 200,
        headers: {
          'Cache-Control': 'public, s-maxage=60, stale-while-revalidate=300'
        }
      }
    )
  } catch (error: any) {
    return NextResponse.json(
      { error: 'server_error', message: error.message || 'Chyba servera.' },
      { status: 500 }
    )
  }
}
