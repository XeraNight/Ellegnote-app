import { NextRequest, NextResponse } from 'next/server'

// MARK: - Apple Wallet Pass Endpoint
// Serves Apple Wallet pass metadata or .pkpass bundle for Encore Member Card
export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url)
  const userId = searchParams.get('userId') || 'guest'
  const name = searchParams.get('name') || 'Tanečník'
  const club = searchParams.get('club') || 'Encore Dance Club'

  // Apple Wallet Pass Definition structure (pass.json standard)
  const passDefinition = {
    formatVersion: 1,
    passTypeIdentifier: 'pass.com.encore.dance.membercard',
    serialNumber: `ENC-${userId.substring(0, 8).toUpperCase()}`,
    teamIdentifier: 'APPLE_TEAM_ID',
    organizationName: 'Encore Dance',
    description: 'Encore Ballroom & Latin Member Pass',
    foregroundColor: 'rgb(255, 230, 153)', // Champagne Gold
    backgroundColor: 'rgb(102, 3, 18)',    // Deep Wine Crimson
    labelColor: 'rgb(212, 175, 55)',        // Rich Gold
    logoText: 'ENCORE',
    generic: {
      primaryFields: [
        {
          key: 'member',
          label: 'TANEČNÍK',
          value: name
        }
      ],
      secondaryFields: [
        {
          key: 'club',
          label: 'TANEČNÝ KLUB',
          value: club
        }
      ],
      auxiliaryFields: [
        {
          key: 'tier',
          label: 'STATUS',
          value: 'VIP DANCER'
        }
      ],
      backFields: [
        {
          key: 'about',
          label: 'O aplikácii Encore',
          value: 'Encore je prémiový tréningový nástroj pre štandardné a latinskoamerické tance.'
        },
        {
          key: 'website',
          label: 'Webstránka',
          value: 'https://encore-app.vercel.app'
        }
      ]
    },
    barcodes: [
      {
        format: 'PKBarcodeFormatQR',
        message: `https://encore-app.vercel.app/u/${userId}?name=${encodeURIComponent(name)}&club=${encodeURIComponent(club)}`,
        messageEncoding: 'iso-8859-1',
        altText: `ID: ${userId.substring(0, 12).toUpperCase()}`
      }
    ]
  }

  // Returns pass definition as JSON
  return NextResponse.json(passDefinition, {
    status: 200,
    headers: {
      'Content-Type': 'application/json',
      'Cache-Control': 'no-cache'
    }
  })
}
