import type { Metadata } from 'next'
import { GeistSans } from 'geist/font/sans'
import { GeistMono } from 'geist/font/mono'
import './globals.css'

const SITE_NAME = 'NoPeek'
const APP_STORE_URL = 'https://apps.apple.com/us/app/nopeek-%E6%9C%80%E5%BC%B7%E3%81%AE%E3%83%97%E3%83%A9%E3%82%A4%E3%83%99%E3%83%BC%E3%83%88%E3%83%96%E3%83%A9%E3%82%A6%E3%82%B6/id6749825483'

export const metadata: Metadata = {
  title: '覗き見防止ブラウザNoPeek｜履歴削除不要', // 30字以内
  description: '覗き見防止・PINロック・予測変換抑制・即ミュート搭載iOSプライベートブラウザ。公共の場でも落ち着いて閲覧。', // 70字以内目安
  generator: 'v0.dev',
  alternates: { canonical: '/' },
  openGraph: {
    title: '覗き見と音漏れリスクを減らす iOSブラウザ NoPeek',
    description: 'ブラックアウト / PINロック / 予測変換抑制 / 履歴自動処理 / ワンタップ即ミュート で日常の覗き見・音漏れリスクを低減。',
    type: 'website',
    url: 'https://example.com/',
    siteName: SITE_NAME,
    locale: 'ja_JP'
  },
  twitter: {
    card: 'summary_large_image',
    title: '覗き見防止×即ミュート NoPeek',
    description: '公共の場や端末貸与時の視線・音対策。ブラックアウトとPINロック搭載。'
  },
  other: {
    'apple-itunes-app': 'app-id=6749825483, app-argument=https://apps.apple.com/app/id6749825483'
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
              alternateName: 'ノーピーク',
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
              downloadUrl: APP_STORE_URL,
              publisher: { '@type': 'Organization', name: SITE_NAME }
            })
          }}
        />
      </head>
      <body>{children}</body>
    </html>
  )
}
