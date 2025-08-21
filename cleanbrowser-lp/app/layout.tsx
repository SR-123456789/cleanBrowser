import type { Metadata } from 'next'
import { GeistSans } from 'geist/font/sans'
import { GeistMono } from 'geist/font/mono'
import './globals.css'

export const metadata: Metadata = {
  title: 'NoPeek',
  description: 'NoPeek - 徹底的に隠す。最強のシークレットブラウザ。',
  generator: 'v0.dev',
  alternates: {
    canonical: '/',
  },
  other: {
    // iOS Smart App Banner
    'apple-itunes-app': 'app-id=6749825483, affiliate-data=, app-argument=https://apps.apple.com/app/id6749825483'
  }
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
  <html lang="ja">
      <head>
        <style>{`
html {
  font-family: ${GeistSans.style.fontFamily};
  --font-sans: ${GeistSans.variable};
  --font-mono: ${GeistMono.variable};
}
        `}</style>
      </head>
      <body>{children}</body>
    </html>
  )
}
