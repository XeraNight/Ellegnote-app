import { NextResponse } from 'next/server'

export const dynamic = 'force-static'

// MARK: - Apple App Site Association (Universal Links)
// Handled by iOS to open the Encore app directly when scanning QR codes or clicking links
export async function GET() {
  const teamId = process.env.APPLE_TEAM_IDENTIFIER || '2MD5BS4DLM'
  const bundleId = process.env.APPLE_BUNDLE_IDENTIFIER || 'com.jakub.encore'

  const aasa = {
    applinks: {
      apps: [],
      details: [
        {
          appID: `${teamId}.${bundleId}`,
          paths: ['/add/*', '/u/*']
        }
      ]
    },
    webcredentials: {
      apps: [`${teamId}.${bundleId}`]
    }
  }

  return NextResponse.json(aasa, {
    status: 200,
    headers: {
      'Content-Type': 'application/json',
      'Cache-Control': 'public, max-age=86400, immutable'
    }
  })
}
