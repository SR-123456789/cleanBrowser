"use client"

import { Lock } from "lucide-react"

export default function IphoneMock() {
  return (
    <div
      role="img"
      aria-label="iPhoneモック上に検索履歴リストとロックアイコンのイメージ"
      className="relative mx-auto w-full max-w-[360px]"
    >
      {/* Phone frame */}
      <div className="relative rounded-[2rem] border border-gray-200 bg-gray-900 p-2 shadow-2xl shadow-violet-200/30">
        {/* Notch */}
        <div className="mx-auto mb-2 h-5 w-28 rounded-b-2xl bg-black/70" />
        {/* Screen */}
        <div className="relative overflow-hidden rounded-[1.6rem] bg-white">
          {/* Top bar */}
          <div className="flex items-center justify-between border-b px-4 py-3">
            <div className="h-3 w-20 rounded bg-gray-200" />
            <div className="h-3 w-12 rounded bg-gray-200" />
          </div>
          {/* Search bar */}
          <div className="px-4 py-3">
            <div className="h-9 rounded-full border border-gray-200 bg-gray-50" />
          </div>
          {/* History list */}
          <ul className="divide-y">
            {["最近の検索A", "レシピ：〇〇", "店舗：□□□", "記事：△△△", "ツール：☆☆☆"].map((t, i) => (
              <li key={i} className="flex items-center justify-between px-4 py-3">
                <div className="flex items-center gap-3">
                  <span className="h-2.5 w-2.5 rounded-full bg-violet-500" aria-hidden="true" />
                  <span className="text-sm text-gray-700">{t}</span>
                </div>
                <span className="h-3 w-12 rounded bg-gray-100" aria-hidden="true" />
              </li>
            ))}
          </ul>
          {/* Bottom safe area */}
          <div className="p-3">
            <div className="mx-auto h-1 w-24 rounded-full bg-gray-200" />
          </div>
        </div>
      </div>

      {/* Overlay lock */}
      <div
        aria-hidden="true"
        className="pointer-events-none absolute -right-3 -top-3 flex h-12 w-12 items-center justify-center rounded-2xl bg-white shadow-lg ring-1 ring-gray-200"
      >
        <Lock className="h-5 w-5 text-violet-600" />
      </div>
    </div>
  )
}
