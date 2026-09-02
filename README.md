# あれどこだっけ？ — 社内ファイルポータル

ケイクリエイトの「★ケイクリエイトのあれどこだっけ？★」インデックスシートをもとにした、
よく使う媒体資料をひと目で探せる社内向けポータルです。

**公開URL**: https://hirayama-byte.github.io/are-doko/

## できること

- 媒体資料9点をサムネイル付きのカードで一覧表示
- ファイル名・キーワード・管理者での絞り込み検索
- 種別（PDF / スプシ / スライド / ドキュメント）でのフィルタ
- ☆→★ のお気に入り登録（**ブラウザごとに保存**。共有はされません）
- カードをクリックすると Google ドライブの格納先フォルダが開きます

## 格納先

Gドライブ ／ BOXからの移行データ → ★媒体資料★ → 1.よく使う媒体資料

## 構成

```
.
├── index.html                  ← 公開用（build.js の生成物）
├── build.js                    ← テンプレート＋サムネイル → index.html
├── src/
│   └── file-portal.tpl.html    ← 中身を直すのはこのファイル
├── tools/
│   └── make-thumbs.ps1         ← PDF の1ページ目を JPEG 化
└── thumbs/
    └── 33.jpg 〜 41.jpg        ← サムネイル（数字はシートの行番号）
```

## 更新のしかた

シートの内容が変わったら、次の順で作り直します。

1. **サムネイルを作り直す**（PDF が差し替わったときだけ）
   ```powershell
   powershell -ExecutionPolicy Bypass -File tools\make-thumbs.ps1
   ```
   ⚠️ `make-thumbs.ps1` は **UTF-8 BOM付き**で保存すること。BOMなしだと Windows PowerShell 5.1 が
   ANSI として読み、スクリプト内の日本語パスが文字化けして全ファイルが MISSING になります。

2. **HTML を組み立てる**
   ```bash
   node build.js
   ```

3. **push する**
   ```bash
   git add -A && git commit -m "資料を更新" && git push
   ```
   数十秒で GitHub Pages に反映されます。

## 実装メモ

- サムネイルは **data URI（base64）で HTML に埋め込んでいます**。
  外部画像は CSP や Google ドライブの認証で表示できないためです。
  そのぶん `index.html` は約 1MB になりますが、依存ファイルなしの1枚で完結します。
- 配色は素の CSS 変数で実装しています（ライト／ダーク／システムの3状態に対応するため、
  Tailwind は使っていません）。
- カード全体をリンクにするため、リンクは `position:absolute; inset:0` のオーバーレイ（`.card-hit`）に
  しています。★ボタンはリンクの外に置き `z-index` で上に重ねています。
  **カード内にボタンを直接置くと、★を押したつもりでドライブに飛びます。**
- お気に入りは `localStorage` のキー `portal-fav-v1` に保存しています。端末・ブラウザをまたいで
  共有されず、サイトデータを削除すると消えます。
