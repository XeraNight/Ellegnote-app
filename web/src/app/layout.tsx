import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'], display: 'swap' })

export const metadata: Metadata = {
  title: 'Ellegnote',
  description: 'Dance practice & routine manager',
  robots: { index: false, follow: false }, // Private app — no indexing
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="sk" className="dark">
      <body className={inter.className}>
        {children}
      </body>
    </html>
  )
}
