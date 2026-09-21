'use client'

import posthog from 'posthog-js'
import { PostHogProvider as PHProvider } from 'posthog-js/react'
import { useEffect } from 'react'

// PostHog API key should be set as NEXT_PUBLIC_POSTHOG_KEY in your .env.local
// Get it from https://posthog.com/ (free up to 1M events/month)
// EU server used for GDPR compliance: https://eu.posthog.com

export function PostHogProvider({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    const key = process.env.NEXT_PUBLIC_POSTHOG_KEY
    if (!key) return  // silently skip in dev if key not set

    posthog.init(key, {
      api_host: process.env.NEXT_PUBLIC_POSTHOG_HOST ?? 'https://eu.posthog.com',
      person_profiles: 'identified_only', // GDPR: only profile identified users
      capture_pageview: false,            // handled manually for App Router
      capture_pageleave: true,
      autocapture: false,                 // privacy-first: no auto DOM scraping
      persistence: 'memory',             // no localStorage cookies → no cookie banner needed
      loaded: (ph) => {
        if (process.env.NODE_ENV === 'development') {
          ph.debug()
        }
      },
    })
  }, [])

  return (
    <PHProvider client={posthog}>
      {children}
    </PHProvider>
  )
}
