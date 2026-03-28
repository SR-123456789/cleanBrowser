import type { Metadata } from 'next'
import { X, PlayCircle, Menu, Search, MoreVertical, ThumbsUp, ThumbsDown, Share2, PlusSquare } from 'lucide-react'
import Link from 'next/link'

export const metadata: Metadata = {
  title: 'MyVideoTube - Funny Cats Compilation',
  description: 'Ad heavy video page for screenshot',
}

export default function AdDemoPage() {
  return (
    <div className="min-h-screen bg-[#f1f1f1] font-sans pb-32 text-gray-800 relative overflow-hidden">
      
      {/* Header */}
      <header className="bg-white border-b border-gray-200 sticky top-0 z-40 h-14 flex justify-between items-center px-4">
        <div className="flex items-center gap-4">
          <Menu className="text-gray-600" size={24} />
          <div className="font-extrabold text-xl tracking-tighter text-red-600 flex items-center gap-1">
            <PlayCircle size={24} className="fill-red-600 text-white" />
            V-Tube
          </div>
        </div>
        <div className="flex items-center gap-4 text-gray-600">
          <Search size={22} />
          <div className="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center text-white font-bold">U</div>
        </div>
      </header>

      <main className="w-full max-w-md mx-auto bg-white min-h-screen relative shadow-sm pb-10">
        
        {/* Top sticky ad (just below header) */}
        <Link href="https://nopeek.org" target="_blank" className="block w-full bg-yellow-100 border-b border-yellow-300 px-2 py-2 text-center text-xs text-gray-700 font-bold z-30 relative">
          <span className="bg-gray-400 text-white px-1 text-[9px] rounded-sm mr-2 absolute left-2">Ad</span>
          <span className="text-blue-700 underline">スマホのギガ不足に悩んでいませんか？詳細はこちら</span>
        </Link>

        {/* Video Player Area */}
        <div className="w-full aspect-video bg-black relative flex items-center justify-center">
          {/* Fake Video Content */}
          <div className="absolute inset-0 flex flex-col items-center justify-center text-white opacity-80 z-0">
            <PlayCircle size={48} className="mb-2" />
            <span className="text-sm">2:34 / 10:05</span>
          </div>

          {/* Ad overlay on video (very annoying) */}
          <div className="absolute bottom-4 left-1/2 -translate-x-1/2 w-[90%] bg-white/95 rounded shadow-lg p-2 z-20 flex items-center justify-between border-2 border-yellow-400">
            <button aria-label="Close Ad" className="absolute -top-3 -right-3 bg-gray-800 text-white rounded-full p-1 border-2 border-white pointer-events-auto">
              <X size={12} />
            </button>
            <div className="flex items-center gap-2">
              <div className="w-10 h-10 bg-green-500 rounded flex items-center justify-center text-white font-bold text-[10px] text-center leading-tight">APP</div>
              <div className="text-left">
                <span className="bg-gray-200 text-gray-500 px-1 text-[8px] rounded-sm mb-1 inline-block">スポンサー</span>
                <p className="text-xs font-bold text-gray-900 leading-tight">新作爽快パズル！</p>
                <p className="text-[10px] text-gray-600">今すぐプレイ</p>
              </div>
            </div>
            <Link href="https://nopeek.org" target="_blank" className="bg-blue-600 text-white text-[10px] font-bold px-3 py-1.5 rounded-full whitespace-nowrap">
              インストール
            </Link>
          </div>
        </div>

        {/* Video Info */}
        <div className="p-3 border-b border-gray-200">
          <h1 className="text-base font-bold text-gray-900 leading-snug mb-2">
            最高に癒やされる猫のハプニング集 2026年最新版！
          </h1>
          <div className="text-xs text-gray-500 mb-3 flex items-center gap-2">
            <span>245万回視聴</span>
            <span>•</span>
            <span>2ヶ月前</span>
          </div>
          
          <div className="flex justify-between items-center mb-3 overflow-x-auto pb-2 gap-4 whitespace-nowrap scrollbar-hide">
            <div className="flex items-center gap-1 text-gray-700 bg-gray-100 px-3 py-1.5 rounded-full shrink-0">
              <ThumbsUp size={18} /> <span className="text-sm font-medium">1.2万</span>
              <div className="w-px h-4 bg-gray-300 mx-1"></div>
              <ThumbsDown size={18} />
            </div>
            <div className="flex items-center gap-1 text-gray-700 bg-gray-100 px-3 py-1.5 rounded-full shrink-0">
              <Share2 size={18} /> <span className="text-sm font-medium">共有</span>
            </div>
            <div className="flex items-center gap-1 text-gray-700 bg-gray-100 px-3 py-1.5 rounded-full shrink-0">
              <PlusSquare size={18} /> <span className="text-sm font-medium">保存</span>
            </div>
          </div>

          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <div className="w-9 h-9 bg-orange-200 rounded-full flex items-center justify-center text-xl">🐱</div>
              <div className="flex flex-col">
                <span className="font-bold text-sm">にゃんこCh</span>
                <span className="text-xs text-gray-500">チャンネル登録者数 12万人</span>
              </div>
            </div>
            <button className="bg-black text-white px-4 py-2 rounded-full text-sm font-bold">登録する</button>
          </div>
        </div>

        {/* Banner Ad below video info */}
        <Link href="https://nopeek.org" target="_blank" className="block w-full bg-blue-50 border-y border-blue-200 p-4 relative my-2">
          <div className="absolute top-1 right-1 bg-white/80 px-1 py-[1px] text-[9px] text-gray-500 border border-gray-200 rounded">PR</div>
          <div className="flex gap-3 items-center">
             <div className="w-16 h-16 bg-gradient-to-br from-purple-400 to-pink-500 rounded-md shadow flex items-center justify-center text-white font-black text-xl">SALE</div>
             <div className="flex-1">
               <h3 className="font-extrabold text-[#d91e18] text-sm leading-tight mb-1">【本日限定】有名ブランド<br/>最大80%オフセール開催中！</h3>
               <p className="text-[10px] text-gray-600">在庫なくなり次第終了</p>
             </div>
             <div className="bg-[#d91e18] text-white font-bold p-2 text-xs rounded shadow shadow-red-200">
               詳細&gt;
             </div>
          </div>
        </Link>

        {/* Recommended Videos List */}
        <div className="px-3 py-4 flex flex-col gap-3">
          
          {/* Item 1 */}
          <div className="flex gap-2">
            <div className="w-[140px] aspect-video bg-gray-200 rounded relative shrink-0">
              <span className="absolute bottom-1 right-1 bg-black/80 text-white text-[10px] px-1 rounded">12:30</span>
              <div className="absolute inset-0 flex items-center justify-center text-gray-400 text-xs">Thumbnail</div>
            </div>
            <div className="flex-1 pt-1">
              <h4 className="text-sm font-medium text-gray-900 leading-tight line-clamp-2">絶対に見るべき！面白い動物まとめ #52</h4>
              <p className="text-xs text-gray-500 mt-1">どうぶつTV</p>
              <p className="text-xs text-gray-500">10万回視聴 • 1日前</p>
            </div>
            <MoreVertical size={16} className="text-gray-400 mt-1 shrink-0" />
          </div>

          {/* Inline Native-like Ad */}
          <Link href="https://nopeek.org" target="_blank" className="flex gap-2 bg-yellow-50 p-2 rounded border border-yellow-200 relative">
            <div className="absolute top-1 left-1 bg-yellow-400 text-black px-1 text-[9px] font-bold rounded">広告</div>
            <div className="w-[140px] aspect-video bg-indigo-600 rounded flex items-center justify-center text-white font-bold text-lg mt-3 shrink-0">
              副業
            </div>
            <div className="flex-1 pt-3">
              <h4 className="text-sm font-bold text-indigo-900 leading-tight line-clamp-2">スマホ1つで月収+10万円!? 秘密の副業術を無料公開</h4>
              <p className="text-xs text-gray-600 mt-1">株式会社リッチライフ</p>
              <div className="mt-1 flex items-center justify-between">
                <span className="text-[10px] text-indigo-600 bg-indigo-100 px-1 rounded">PR</span>
                <span className="text-xs text-indigo-600 font-bold flex items-center">開く <PlayCircle size={12} className="ml-1"/></span>
              </div>
            </div>
          </Link>

          {/* Item 2 */}
          <div className="flex gap-2">
            <div className="w-[140px] aspect-video bg-gray-200 rounded relative shrink-0">
              <span className="absolute bottom-1 right-1 bg-black/80 text-white text-[10px] px-1 rounded">8:45</span>
              <div className="absolute inset-0 flex items-center justify-center text-gray-400 text-xs">Thumbnail</div>
            </div>
            <div className="flex-1 pt-1">
              <h4 className="text-sm font-medium text-gray-900 leading-tight line-clamp-2">失敗しない！初めての子猫のお迎えガイド</h4>
              <p className="text-xs text-gray-500 mt-1">にゃんこCh</p>
              <p className="text-xs text-gray-500">3万回視聴 • 5日前</p>
            </div>
            <MoreVertical size={16} className="text-gray-400 mt-1 shrink-0" />
          </div>

          {/* Huge Square Ad */}
          <Link href="https://nopeek.org" target="_blank" className="w-full bg-slate-800 text-white flex flex-col rounded overflow-hidden my-2 relative">
             <div className="absolute top-0 right-0 bg-black/50 text-white px-1.5 py-0.5 text-[10px] z-10">広告</div>
             <div className="w-full h-[200px] bg-red-600 flex flex-col items-center justify-center p-4 text-center">
                 <p className="text-xl font-black italic mb-2 drop-shadow">「もっと早く知りたかった...」</p>
                 <h3 className="text-3xl font-extrabold text-yellow-300 drop-shadow-md leading-tight mb-4">劇的に変わる<br/>〇〇メソッド</h3>
                 <p className="bg-white text-red-600 font-bold px-4 py-1 rounded inline-block text-sm shadow">今なら無料公開中</p>
             </div>
             <div className="p-3 bg-gray-100 text-gray-800 flex justify-between items-center">
               <div className="flex flex-col">
                 <span className="text-sm font-bold">話題沸騰のメソッド</span>
                 <span className="text-[10px] text-gray-500">example.com</span>
               </div>
               <span className="bg-blue-600 text-white text-xs px-4 py-2 font-bold rounded hover:bg-blue-700 shadow">詳細を見る</span>
             </div>
          </Link>
          
        </div>
      </main>

      {/* Backdrop for the popup fake interstitial -- extremely annoying */}
      <div className="fixed inset-0 bg-black/70 z-[60] flex items-center justify-center px-4">
        {/* Fake Interstitial / Popup Ad connecting to nopeek.org */}
        <Link href="https://nopeek.org" target="_blank" className="w-full max-w-[320px] bg-white rounded-lg shadow-2xl relative overflow-hidden animate-in fade-in zoom-in duration-300 block pointer-events-auto">
          
          <div className="w-full bg-gradient-to-r from-red-500 to-orange-500 p-6 flex flex-col items-center justify-center text-white text-center">
            <span className="text-yellow-200 font-bold text-sm mb-1">＼おめでとうございます！／</span>
            <h4 className="font-black text-2xl mb-2 leading-tight drop-shadow">特別ボーナス<br/>獲得のチャンス</h4>
            <div className="bg-white/20 p-3 rounded mt-2">
              <p className="text-sm font-bold mb-1">今すぐタップして確認</p>
              <p className="text-[10px]">※期間限定のキャンペーンです</p>
            </div>
          </div>
          <div className="p-4 bg-gray-50 flex justify-center">
            <div className="w-[80%] bg-red-600 hover:bg-red-700 text-white font-bold py-3 text-center rounded-full shadow-lg border-b-4 border-red-800 text-lg animate-pulse pointer-events-none">
              今すぐGET！
            </div>
          </div>
          
          <div className="absolute top-2 right-2 flex items-center gap-1 z-10">
            <span className="text-[10px] text-white/70">広告</span>
            <div className="bg-black/40 text-white rounded-full p-1 border border-white/30 cursor-pointer pointer-events-auto" aria-label="Close">
              <X size={16} />
            </div>
          </div>
        </Link>
      </div>

      {/* Ad: Sticky Bottom Ad (Extremely annoying) */}
      <div className="fixed bottom-0 left-0 w-full h-[70px] bg-white border-t border-gray-300 shadow-[0_-5px_15px_rgba(0,0,0,0.15)] z-[70] flex items-center px-2 py-1 box-border">
        {/* Tiny close button placed awkwardly */}
        <div className="absolute -top-6 right-0 bg-white/90 text-gray-500 p-0.5 border border-gray-300 rounded-tl shadow-sm z-10 cursor-pointer">
          <X size={14} />
        </div>
        <div className="absolute top-0 right-1 text-[8px] text-gray-400 bg-white px-1 font-sans pointer-events-none">PR</div>
        
        <Link href="https://nopeek.org" target="_blank" className="flex items-center w-full h-full gap-2">
          <div className="w-[50px] h-[50px] bg-green-500 rounded-lg shrink-0 flex items-center justify-center text-white font-bold text-xs shadow-inner overflow-hidden relative border border-green-600">
            <span className="z-10 text-[10px] text-center leading-tight">人気<br/>マンガ</span>
          </div>
          
          <div className="flex-1 mt-1">
            <p className="text-[12px] font-black text-gray-900 leading-tight">大人気コミックが全巻無料!?<br/>期間限定の特大キャンペーン実施中</p>
            <p className="text-[10px] text-red-600 font-bold mt-0.5">※会員登録不要</p>
          </div>
          
          <div className="bg-green-600 text-white font-bold px-3 py-2 rounded text-xs shrink-0 shadow mt-1 pointer-events-none">
            読む ＞
          </div>
        </Link>
      </div>

    </div>
  )
}
