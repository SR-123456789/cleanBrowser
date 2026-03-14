import type { Metadata } from 'next'
import { GeistSans } from 'geist/font/sans'
import { GeistMono } from 'geist/font/mono'
import './globals.css'

const SITE_NAME = 'av-brower'

export const metadata: Metadata = {
  title: '覗き見防止ブラウザav-brower｜履歴削除不要', // 30字以内
  description: '覗き見防止・PINロック・予測変換抑制・即ミュート搭載iOSプライベートブラウザ。公共の場でも落ち着いて閲覧。', // 70字以内目安
  generator: 'v0.dev',
  alternates: { canonical: '/' },
  openGraph: {
    title: '覗き見と音漏れリスクを減らす iOSブラウザ av-brower',
    description: 'ブラックアウト / PINロック / 予測変換抑制 / 履歴自動処理 / ワンタップ即ミュート で日常の覗き見・音漏れリスクを低減。',
    type: 'website',
    url: 'https://example.com/',
    siteName: SITE_NAME,
    locale: 'ja_JP'
  },
  twitter: {
    card: 'summary_large_image',
    title: '覗き見防止×即ミュート av-brower',
    description: '公共の場や端末貸与時の視線・音対策。ブラックアウトとPINロック搭載。'
  },
  other: {
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
        <script
          type="application/ld+json"
          // eslint-disable-next-line react/no-danger
          dangerouslySetInnerHTML={{
            __html: JSON.stringify({
              '@context': 'https://schema.org',
              '@type': 'SoftwareApplication',
              name: SITE_NAME,
              applicationCategory: 'UtilitiesApplication',
              operatingSystem: 'iOS',
              description:
                '覗き見・音漏れ日常リスクを減らすiOS向けプライベートブラウザ。ブラックアウト、PINロック、予測変換抑制、履歴自動処理、ワンタップ即ミュートを搭載。',
              featureList: [
                'アプリ切替時ブラックアウト表示',
                '起動時PINロック',
                '予測変換に入力が残りにくい仕組み',
                '履歴の自動処理で手動削除負担を軽減',
                'ワンタップ即ミュート'
              ],
              inLanguage: 'ja',
              isAccessibleForFree: true,
              url: 'https://example.com/',
              publisher: { '@type': 'Organization', name: SITE_NAME }
            })
          }}
        />
      </head>
      <body>{children}</body>
    </html>
  )
}
