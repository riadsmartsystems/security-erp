import type { Metadata } from 'next'
import Script from 'next/script'
import QueryProvider from '@/components/QueryProvider'
import './globals.css'

export const metadata: Metadata = {
  title: 'RIAD Smart System',
  description: 'Security ERP Platform',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="uk">
      <head>
        <Script
          src="https://challenges.cloudflare.com/turnstile/v0/api.js"
          strategy="afterInteractive"
        />
      </head>
      <body><QueryProvider>{children}</QueryProvider></body>
    </html>
  )
}
