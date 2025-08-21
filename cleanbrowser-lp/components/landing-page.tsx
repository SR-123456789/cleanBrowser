"use client"

import type React from "react"
import { motion, useReducedMotion } from "framer-motion"
import {
  Lock,
  Keyboard,
  AppWindow,
  Clock,
  Search,
  Square,
  Unlock,
  CheckCircle2,
  XCircle,
  ChevronRight,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from "@/components/ui/accordion"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Badge } from "@/components/ui/badge"
import { Separator } from "@/components/ui/separator"
import Link from "next/link"
import { cn } from "@/lib/utils"
import IphoneMock from "./iphone-mock"
import { FadeUp } from "./motion-pieces"

// ブランド名（将来名称変更があってもここだけ直せば済むように）
const BRAND = "NoPeek"
// App Store 配信URL（後で他コンポーネントでも使えるよう定数化）
const APP_STORE_URL = "https://apps.apple.com/us/app/nopeek-%E6%9C%80%E5%BC%B7%E3%81%AE%E3%83%97%E3%83%A9%E3%82%A4%E3%83%99%E3%83%BC%E3%83%88%E3%83%96%E3%83%A9%E3%82%A6%E3%82%B6/id6749825483" as const

type Props = {
  fontClassName?: string
}

const navItems = [
  { href: "#benefits", label: "ベネフィット" },
  { href: "#how", label: "使い方" },
  { href: "#compare", label: "比較" },
  { href: "#faq", label: "FAQ" },
  { href: "#download", label: "ダウンロード" },
]

export default function LandingPage({ fontClassName = "" }: Props) {
  const prefersReducedMotion = useReducedMotion()

  return (
    <div className={cn("min-h-dvh bg-white text-gray-900 scroll-smooth", fontClassName)}>
      <Header />

      <main>
        {/* Hero */}
        <section id="hero" className="relative overflow-hidden" aria-labelledby="hero-title">
          {/* Animated rainbow gradient backdrop */}
          <AnimatedHeroBackground />

          <div className="relative mx-auto max-w-7xl px-6 pt-28 pb-16 md:pt-36 md:pb-24">
            <div className="grid items-center gap-12 md:grid-cols-2">
              <div>
                <FadeUp as="div" delay={0.05}>
                  <h1
                    id="hero-title"
                    className="text-3xl font-extrabold tracking-tight text-gray-900 sm:text-5xl leading-tight"
                  >
                    {"最強シークレットブラウザ"}
                  </h1>
                </FadeUp>

                <FadeUp as="p" className="mt-4 max-w-xl text-base leading-relaxed text-gray-600 sm:text-lg" delay={0.1}>
                  {
                    "キーボードの予測変換に残らない、PINロックと黒画面で覗き見を防止。貸しても安心、見られないブラウザ。"
                  }
                </FadeUp>

                <FadeUp as="div" className="mt-8 flex flex-wrap gap-3" delay={0.15}>
                  <RainbowBorderButton asChild>
                    <a
                      href={APP_STORE_URL}
                      target="_blank"
                      rel="noopener noreferrer"
                      data-cta="download-app-store-hero"
                      aria-label={`${BRAND} をApp Storeで開く（新しいタブ）`}
                    >
                      <Lock className="mr-2 h-4 w-4" aria-hidden="true" />
                      {"今すぐはじめる"}
                    </a>
                  </RainbowBorderButton>
                  <Button asChild variant="ghost" className="rounded-2xl border border-gray-200 hover:bg-gray-50">
                    <a href="#benefits" data-cta="learn" aria-label="詳しく見るへ移動">
                      {"詳しく見る"}
                      <ChevronRight className="ml-1 h-4 w-4" aria-hidden="true" />
                    </a>
                  </Button>
                </FadeUp>

                {/* <FadeUp className="mt-6">
                  <p className="text-xs text-gray-500">{"B案: 便利な履歴。見せない安心。"}</p>
                </FadeUp> */}
              </div>

              <FadeUp className="relative">
                {/* Glow light */}
                <div
                  aria-hidden="true"
                  className="pointer-events-none absolute -right-8 -top-8 h-40 w-40 rounded-full bg-gradient-to-tr from-violet-500 via-fuchsia-500 to-pink-500 opacity-40 blur-3xl"
                />
                <IphoneMock />
              </FadeUp>
            </div>
          </div>
        </section>

        {/* Benefits */}
        <section id="benefits" className="scroll-mt-24" aria-labelledby="benefits-title">
          <div className="mx-auto max-w-7xl px-6 py-12 md:py-20">
            <FadeUp>
              <h2 id="benefits-title" className="text-2xl font-bold tracking-tight text-gray-900 sm:text-3xl">
                {"貸せる・安心・誇れる。4つのベネフィット"}
              </h2>
            </FadeUp>
            <div className="mt-8 grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
              <BenefitCard
                icon={<Keyboard className="h-5 w-5 text-violet-600" aria-hidden="true" />}
                title="予測変換に残さない"
                desc="独自キーボードで入力しても、候補は静かなまま。"
                delay={0.05}
              />
              <BenefitCard
                icon={<Lock className="h-5 w-5 text-violet-600" aria-hidden="true" />}
                title="勝手に開けない"
                desc="PINロックで、あなた以外はブラウザを開けない。"
                delay={0.1}
              />
              <BenefitCard
                icon={<AppWindow className="h-5 w-5 text-violet-600" aria-hidden="true" />}
                title="切り替え時は黒画面"
                desc="App Switchのプレビューは真っ黒。覗き見ゼロ。"
                delay={0.15}
              />
              <BenefitCard
                icon={<Clock className="h-5 w-5 text-violet-600" aria-hidden="true" />}
                title="履歴は残す。でも見せない"
                desc="便利な履歴を守りつつ、第三者には一切見せない。"
                delay={0.2}
              />
            </div>
          </div>
        </section>

        {/* How it works */}
        <section id="how" className="scroll-mt-24 bg-gray-50" aria-labelledby="how-title">
          <div className="mx-auto max-w-7xl px-6 py-12 md:py-20">
            <FadeUp>
              <h2 id="how-title" className="text-2xl font-bold tracking-tight text-gray-900 sm:text-3xl">
                {"使い方は、3ステップ"}
              </h2>
            </FadeUp>
            <div className="mt-8 grid gap-6 md:grid-cols-3">
              <StepCard
                icon={<Search className="h-5 w-5 text-violet-600" aria-hidden="true" />}
                title="検索"
                desc="予測変換は静か。心は軽い。"
                delay={0.05}
              />
              <StepCard
                icon={<Square className="h-5 w-5 text-violet-600" aria-hidden="true" />}
                title="切替"
                desc="サムネは黒。落とす手間なし。"
                delay={0.1}
              />
              <StepCard
                icon={<Unlock className="h-5 w-5 text-violet-600" aria-hidden="true" />}
                title="再開"
                desc="PIN解除で続きから。"
                delay={0.15}
              />
            </div>
          </div>
        </section>

        {/* Comparison */}
        <section id="compare" className="scroll-mt-24" aria-labelledby="compare-title">
          <div className="mx-auto max-w-7xl px-6 py-12 md:py-20">
            <FadeUp>
              <h2 id="compare-title" className="text-2xl font-bold tracking-tight text-gray-900 sm:text-3xl">
                {"他のプライバシーブラウザと比較"}
              </h2>
            </FadeUp>
            <div className="mt-8 overflow-x-auto rounded-2xl border border-gray-200 bg-white shadow-sm">
              <Table>
                <TableHeader>
                  <TableRow className="bg-gray-50/60">
                    <TableHead className="w-48">{"項目"}</TableHead>
                    <TableHead>{"ブラウザC"}</TableHead>
                    <TableHead>{"ブラウザS"}</TableHead>
                    <TableHead>{"ブラウザD"}</TableHead>
                    <TableHead>{BRAND}</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {/* <CompareRow
                    label="履歴・Cookie非保存"
                    cells={[
                      <Good key="c1" />,
                      <Good key="c2" />,
                      <Good key="c3" />,
                      <Bad key="c4" note="（履歴は残す）" />,
                    ]}
                  /> */}
                  <CompareRow
                    label="キーボードの予測変換履歴"
                                        cells={[<Bad key="b1" />, <Bad key="b2" />, <Bad key="b3" />, <Good key="b4" />]}

                  />
                  <CompareRow
                    label="切替時の黒画面"
                    cells={[<Bad key="b1" />, <Bad key="b2" />, <Bad key="b3" />, <Good key="b4" />]}
                  />
                  <CompareRow
                    label="パスワード"
                    cells={[<Bad key="l1" />, <Bad key="l2" />, <Bad key="l3" />, <Good key="l4" />]}
                  />
                </TableBody>
              </Table>
            </div>
          </div>
        </section>

        {/* FAQ */}
        <section id="faq" className="scroll-mt-24 bg-gray-50" aria-labelledby="faq-title">
          <div className="mx-auto max-w-7xl px-6 py-12 md:py-20">
            <FadeUp>
              <h2 id="faq-title" className="text-2xl font-bold tracking-tight text-gray-900 sm:text-3xl">
                {"FAQ"}
              </h2>
            </FadeUp>
            <FadeUp delay={0.05}>
              <Accordion type="single" collapsible className="mt-6 rounded-2xl border bg-white px-2">
                <AccordionItem value="q1">
                  <AccordionTrigger className="text-left">{"Q: 履歴は残るのですか？"}</AccordionTrigger>
                  <AccordionContent>
                    {"A: はい。後で見返せる便利さは残しつつ、第三者に見せない設計です。"}
                  </AccordionContent>
                </AccordionItem>
                <Separator />
                <AccordionItem value="q2">
                  <AccordionTrigger className="text-left">{"Q: アプリを開きっぱなしでも平気？"}</AccordionTrigger>
                  <AccordionContent>{"A: 切り替え時は真っ黒、戻るとロックで安全です。"}</AccordionContent>
                </AccordionItem>
              </Accordion>
            </FadeUp>
          </div>
        </section>

        {/* Final CTA */}
        <section id="download" className="scroll-mt-24" aria-labelledby="download-title">
          <div className="mx-auto max-w-7xl px-6 py-16 md:py-24">
            <FadeUp className="relative overflow-hidden rounded-2xl border border-violet-200 bg-gradient-to-br from-white to-violet-50 p-8 shadow-sm sm:p-12">
              {/* Subtle moving rainbow border */}
              <div
                aria-hidden="true"
                className="pointer-events-none absolute inset-0 rounded-2xl ring-1 ring-inset ring-violet-200"
              />
              <div className="mx-auto max-w-3xl text-center">
                <h3 id="download-title" className="text-2xl font-bold text-gray-900 sm:text-3xl">
                  {"貸せるスマホ。見られないブラウザ。"}
                </h3>
        <p className="mt-3 text-gray-600">{`履歴の便利さも、見せない安心も。${BRAND}で両立しよう。`}</p>
                <div className="mt-8 flex items-center justify-center gap-3">
                  <RainbowBorderButton asChild>
                    <a
                      href={APP_STORE_URL}
                      target="_blank"
                      rel="noopener noreferrer"
                      data-cta="download-app-store-final"
                      aria-label={`${BRAND} をApp Storeで開く（新しいタブ）`}
                    >
                      <Lock className="mr-2 h-4 w-4" aria-hidden="true" />
                      {"今すぐはじめる"}
                    </a>
                  </RainbowBorderButton>
                  <Button variant="outline" className="rounded-2xl bg-transparent">
                    {"リリース通知を受け取る"}
                  </Button>
                </div>
              </div>
            </FadeUp>
          </div>
        </section>
      </main>

      <Footer />
    </div>
  )
}

function Header() {
  return (
    <header className="sticky top-0 z-50 w-full border-b border-transparent bg-white/70 backdrop-blur supports-[backdrop-filter]:bg-white/60">
      <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-6">
        <Link href="#hero" className="flex items-center gap-2" aria-label={`${BRAND} ホームへ`}>
          <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-violet-600 text-white shadow-sm">
            <Lock className="h-4 w-4" aria-hidden="true" />
          </div>
          <span className="text-sm font-bold tracking-tight text-gray-900">{BRAND}</span>
        </Link>

        <nav aria-label="メインナビゲーション" className="hidden items-center gap-6 md:flex">
          {navItems.map((item) => (
            <a key={item.href} href={item.href} className="text-sm text-gray-600 transition-colors hover:text-gray-900">
              {item.label}
            </a>
          ))}
        </nav>

        <div className="hidden md:block">
          <RainbowBorderButton asChild>
            <a
              href={APP_STORE_URL}
              target="_blank"
              rel="noopener noreferrer"
              data-cta="download-app-store-header"
              aria-label={`${BRAND} をApp Storeで開く（新しいタブ）`}
            >
              {"今すぐはじめる"}
            </a>
          </RainbowBorderButton>
        </div>
      </div>
    </header>
  )
}

function Footer() {
  return (
    <footer className="border-t bg-white">
      <div className="mx-auto flex max-w-7xl flex-col items-center justify-between gap-4 px-6 py-10 sm:flex-row">
        <div className="flex items-center gap-2 text-sm text-gray-500">
          <Lock className="h-4 w-4 text-violet-600" aria-hidden="true" />
          <span>
            {"© "} {new Date().getFullYear()} {` ${BRAND}`}
          </span>
        </div>
        <div className="flex items-center gap-6 text-sm text-gray-600">
          <a href="#faq" className="hover:text-gray-900">
            {"サポート"}
          </a>
          <a href="#" className="hover:text-gray-900">
            {"利用規約"}
          </a>
          <a href="#" className="hover:text-gray-900">
            {"プライバシー"}
          </a>
        </div>
      </div>
    </footer>
  )
}

function AnimatedHeroBackground() {
  const prefersReducedMotion = useReducedMotion()

  if (prefersReducedMotion) {
    return (
      <div aria-hidden="true" className="absolute inset-0 bg-gradient-to-br from-violet-50 via-fuchsia-50 to-pink-50" />
    )
  }

  return (
    <motion.div
      aria-hidden="true"
      className="absolute inset-0"
      initial={{ backgroundPosition: "0% 50%" }}
      animate={{ backgroundPosition: ["0% 50%", "100% 50%", "0% 50%"] }}
      transition={{ duration: 18, repeat: Number.POSITIVE_INFINITY, ease: "linear" }}
      style={{
        backgroundImage:
          "radial-gradient(1200px 600px at 10% -10%, rgba(124,58,237,0.18), transparent 60%), radial-gradient(1000px 500px at 90% 10%, rgba(236,72,153,0.18), transparent 60%), linear-gradient(120deg, #faf5ff 0%, #fff 40%, #fff 60%, #fdf2f8 100%)",
        backgroundSize: "200% 200%",
      }}
    />
  )
}

function BenefitCard({
  icon,
  title,
  desc,
  delay = 0,
}: {
  icon: React.ReactNode
  title: string
  desc: string
  delay?: number
}) {
  return (
    <FadeUp delay={delay}>
      <Card className="h-full rounded-2xl border-gray-200 shadow-sm transition-shadow hover:shadow-md">
        <CardHeader className="flex flex-row items-center gap-3 space-y-0">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-violet-50">{icon}</div>
          <CardTitle className="text-base">{title}</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-gray-600">{desc}</p>
        </CardContent>
      </Card>
    </FadeUp>
  )
}

function StepCard({
  icon,
  title,
  desc,
  delay = 0,
}: {
  icon: React.ReactNode
  title: string
  desc: string
  delay?: number
}) {
  return (
    <FadeUp delay={delay}>
      <Card className="h-full rounded-2xl border-gray-200 bg-white shadow-sm">
        <CardHeader className="flex flex-row items-center gap-3 space-y-0">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-violet-50">{icon}</div>
          <CardTitle className="text-base">{title}</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-gray-600">{desc}</p>
        </CardContent>
      </Card>
    </FadeUp>
  )
}

function CompareRow({
  label,
  cells,
}: {
  label: string
  cells: React.ReactNode[]
}) {
  return (
    <TableRow>
      <TableCell className="font-medium">{label}</TableCell>
      {cells.map((c, i) => (
        <TableCell key={i} className="align-middle">
          {c}
        </TableCell>
      ))}
    </TableRow>
  )
}

function Good() {
  return (
    <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-50 px-2 py-1 text-xs font-medium text-emerald-700">
      <CheckCircle2 className="h-4 w-4" aria-hidden="true" />
      {"✅"}
    </span>
  )
}

function Bad({ note }: { note?: string }) {
  return (
    <span className="inline-flex items-center gap-1.5 rounded-full bg-rose-50 px-2 py-1 text-xs font-medium text-rose-700">
      <XCircle className="h-4 w-4" aria-hidden="true" />
      <span>
        {"❌"}
        {note ? " " + note : ""}
      </span>
    </span>
  )
}

function RainbowBorderButton({
  children,
  asChild = false,
}: {
  children: React.ReactNode
  asChild?: boolean
}) {
  const Inner: any = asChild ? "span" : "button"
  return (
    <span className="relative inline-flex">
      <span className="absolute -inset-[2px] rounded-2xl bg-[linear-gradient(90deg,#8b5cf6, #d946ef, #ec4899)] [background-size:200%_100%] transition-[background-position] duration-500 group-hover:[background-position:100%_0%]" />
      <Button
        asChild={asChild}
        className="relative rounded-2xl bg-violet-600 px-5 py-2.5 text-white shadow-sm hover:bg-violet-700"
      >
        <Inner className="group relative rounded-2xl">{children}</Inner>
      </Button>
    </span>
  )
}
