backendのapiサーバーをfrontに繋いで

{{baseUrl}}/api/v1/public/startup?appVersion=
だけ繋いで

{
    "update": {
        "mustUpdate": false,
        "shouldUpdate": false,
        "repeatUpdatePrompt": false,
        "updateLink": "https://apps.apple.com/app/id1234567890",
        "message": "現在のバージョンは最新です。"
    },
    "ads": [
        {
            "adID": "daily_interstitial",
            "isShow": false
        }
    ]
}

mustUpdateがtrueの時は updateしないと起動できないようにしたい(ダイアログが消えない)
shouldUpdateは updateしてくださいってダイアログをアプリ起動時に出す。キャンセルを押したらダイアログを閉じたらUser月開ける
repeatUpdatePromptはこれがtrueならアプリが毎回起動した時に上記のメッセージを毎回出す
falseなら一回だけ出しておしまい(各version&&message,ごとにね)