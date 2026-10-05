import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'
import { PostHogProvider } from '@/components/PostHogProvider'
import { Analytics } from '@vercel/analytics/next'

const inter = Inter({ subsets: ['latin'], display: 'swap' })

export const metadata: Metadata = {
  title: {
    default: 'Encore — Umenie tanca. Dokonalosť tréningu.',
    template: '%s | Encore',
  },
  description: 'Prémiový digitálny asistent pre tanečné páry, trénerov a tanečníkov, ktorí chcú napredovať čo najrýchlejšie a najefektívnejšie.',
  icons: {
    icon: '/logo_mark.svg',
    apple: '/logo_full.svg',
  },
  robots: { index: true, follow: true },
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="sk" className="dark">
      <body className={inter.className}>
        <PostHogProvider>
          {children}
        </PostHogProvider>
        <Analytics />
      </body>
    </html>
  )
}
