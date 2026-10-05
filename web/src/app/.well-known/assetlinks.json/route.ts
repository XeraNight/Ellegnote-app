import { NextResponse } from 'next/server'

export const dynamic = 'force-static'

// MARK: - Digital Asset Links (Android App Links)
// Handled by Android devices to verify app ownership for deep linking
export async function GET() {
  const packageName = process.env.ANDROID_PACKAGE_NAME || 'com.jakub.encore'
  const certFingerprint = process.env.ANDROID_SHA256_FINGERPRINT || '14:6D:E9:01:C2:5F:29:41:A5:AC:12:F3:6E:B8:2C:9E:C1:8A:2F:78:E2:B6:3C:99:A1:04:D2:78:C8:8E:45:90'

  const assetLinks = [
    {
      relation: ['delegate_permission/common.handle_all_urls'],
      target: {
        namespace: 'android_app',
        package_name: packageName,
        sha256_cert_fingerprints: [certFingerprint]
      }
    }
  ]

  return NextResponse.json(assetLinks, {
    status: 200,
    headers: {
      'Content-Type': 'application/json',
      'Cache-Control': 'public, max-age=86400, immutable'
    }
  })
}
