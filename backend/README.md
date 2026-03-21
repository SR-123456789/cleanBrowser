# Backend API

`backend` には `Hono + TypeScript + DDD + Clean Architecture` ベースの API サーバーを配置しています。  
現状の公開用途は以下の 2 つです。

- アプリ起動時の更新判定取得
- AdMob 広告表示可否の取得

## 構成

```text
backend/
├── cmd/api                    # エントリポイント
├── package.json               # Hono / Node runtime
├── internal/application       # usecase / port
├── internal/bootstrap         # DI と設定読み込み
├── internal/domain            # ドメインモデル
├── internal/interface/http    # Hono コントローラー・プレゼンター・ルーター
└── internal/infrastructure    # repository 実装
```

## 起動

```bash
cd backend
npm install
npm run dev
```

デフォルトでは `:4782` で起動します。

## 環境変数

| 変数名 | 既定値 | 説明 |
| --- | --- | --- |
| `PORT` | `4782` | HTTP ポート |
| `HTTP_ADDR` | `:4782` | Listen address |
| `PUBLIC_API_KEYS` | `dev-public-api-key` | 公開APIで許可する API key のカンマ区切り一覧。`production` では必須 |
| `CORS_ALLOW_ORIGINS` | `vscode-webview://*` | ブラウザから許可する Origin のカンマ区切り一覧。末尾 `*` の prefix wildcard を利用可能 |

## API

### Health

- `GET /healthz`

### 公開 API

- `GET /api/v1/public/startup?appVersion=1.0.0`
- `GET /api/v1/public/ads/daily_interstitial/visibility`

`startup` と `ads/{adID}/visibility` は、現時点では DB 接続を行わず、
バックエンド内の repository 実装からレスポンスを返します。

## OpenAPI

- `backend/openapi.yaml`

## リクエスト例

ローカル開発では `PUBLIC_API_KEYS` 未指定時に `dev-public-api-key` が使われます。  
VS Code の OpenAPI preview 用に、`CORS_ALLOW_ORIGINS` 未指定時は `vscode-webview://*` を許可します。

### アプリ起動時の初期情報を取得

```bash
curl "http://localhost:4782/api/v1/public/startup?appVersion=1.0.0" \
  -H "X-API-Key: dev-public-api-key"
```

### 広告表示可否を取得

```bash
curl "http://localhost:4782/api/v1/public/ads/daily_interstitial/visibility" \
  -H "X-API-Key: dev-public-api-key"
```

## 注意

- 公開APIは現時点で固定データを返す repository 実装です。DB に差し替える場合は `internal/infrastructure` の実装だけを差し替えてください。
- iOS / Postman / Swagger UI など、公開APIを呼ぶクライアントは `X-API-Key` ヘッダを付けてください。
