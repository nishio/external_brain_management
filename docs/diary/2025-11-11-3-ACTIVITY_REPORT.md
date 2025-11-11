# イラストビュー機能 実装レポート

**日付**: 2025年11月11日  
**担当**: Devin  
**PR**: https://github.com/nishio/mem/pull/2  
**ブランチ**: `devin/1762834682-implement-illust-view`

## 概要

PLAN.md（https://github.com/nishio/mem/blob/master/PLAN.md）に基づき、xkcd風のイラストビュー機能を実装しました。この機能により、Scrapboxのマークダウンファイルから抽出したGyazo画像を、専用のイラストビューで表示できるようになりました。

## 実装した機能

### 1. イラスト個別ページ (`pages/[lang]/illust/[page].tsx`)

**URL形式**: `/ja/illust/001`, `/ja/illust/002`, `/ja/illust/003`

**主な機能**:
- Gyazo画像の自動抽出と表示（正規表現: `/!\[.*?\]\((https:\/\/gyazo\.com\/[a-f0-9]+(?:\/thumb\/\d+)?)\)/i`）
- xkcd風ナビゲーション
  - `|<` : 最初のイラスト
  - `< Prev` : 前のイラスト
  - `Random` : ランダムなイラスト
  - `Next >` : 次のイラスト
  - `>|` : 最後のイラスト
- 短い説明文の表示（最初の2段落または300文字まで）
- 元ページへの「詳細を読む」ボタン
- 言語切り替え対応（日本語/英語）

**レイアウト**:
- タイトル（中央揃え）
- メイン画像（最大幅1200px、最大高さ80vh）
- ナビゲーションボタン
- 短い説明文（最大幅800px）
- 詳細を読むボタン

**レスポンシブ対応**:
- モバイル（768px以下）: タイトルサイズ縮小、説明文の幅を100%に

### 2. イラスト一覧ページ (`pages/[lang]/illust/index.tsx`)

**URL**: `/ja/illust`, `/en/illust`

**主な機能**:
- 画像のみを正方形タイルで表示
- グリッドレイアウト
- 各タイルをクリックすると個別ページへ遷移

**レスポンシブ対応**:
- モバイル/タブレット（768px以下）: 3列固定、gap 0.5rem
- デスクトップ（769px以上）: auto-fitで自動調整、gap 1rem

**実装の特徴**:
- `paddingBottom: "100%"`で正方形のアスペクト比を維持
- 画像は`position: absolute`で中央配置
- `objectFit: "contain"`で画像全体を表示

### 3. 設定ファイル (`illust_config.json`)

**場所**: プロジェクトルート (`/home/ubuntu/repos/mem/illust_config.json`)

**構造**:
```json
{
  "illusts": [
    {
      "id": "001",
      "page_ja": "ブロードリスニング",
      "page_en": null,
      "tags": ["xkcd", "communication", "democracy"]
    },
    {
      "id": "002",
      "page_ja": "ツリーとリゾーム",
      "page_en": null,
      "tags": ["philosophy", "structure"]
    },
    {
      "id": "003",
      "page_ja": "単語を変えると誤解が拡大する",
      "page_en": null,
      "tags": ["communication", "misunderstanding"]
    }
  ]
}
```

**使い方**:
- 新しいイラストを追加する場合は、このファイルに新しいエントリを追加
- `id`は3桁のゼロパディング形式（"001", "002", "003"...）
- `page_ja`はマークダウンファイル名（拡張子なし）
- `page_en`は英語版のページ名（なければnull）
- `tags`は任意のタグ配列

## 技術的な実装詳細

### データフロー

1. `illust_config.json`から設定を読み込み
2. 各イラストの`page_ja`/`page_en`に対応するマークダウンファイルを`data/[lang]/pages/`から読み込み
3. `gray-matter`でフロントマターを解析
4. 正規表現でGyazo画像URLを抽出
5. `marked`でマークダウンをHTMLに変換
6. Next.jsのSSGで静的ページを生成

### 使用技術

- **Next.js**: SSG（Static Site Generation）
- **TypeScript**: 型安全な実装
- **styled-jsx**: コンポーネントスコープのスタイリング
- **gray-matter**: フロントマター解析
- **marked**: マークダウンパース

### ファイル構成

```
mem/
├── illust_config.json          # イラスト設定ファイル
├── pages/
│   └── [lang]/
│       └── illust/
│           ├── index.tsx       # 一覧ページ
│           └── [page].tsx      # 個別ページ
└── data/
    ├── ja/
    │   └── pages/
    │       ├── ブロードリスニング.md
    │       ├── ツリーとリゾーム.md
    │       └── 単語を変えると誤解が拡大する.md
    └── en/
        └── pages/
            └── (英語版ページ)
```

## UI改善の履歴

### 改善1: 一覧ページの正方形タイル表示
- **要望**: 画像だけを正方形のタイルに全体が見えるように並べて
- **実装**: タイトルとタグを削除し、画像のみを正方形タイルで表示

### 改善2: モバイルで3列表示
- **要望**: スマホで見たときに一列しかなくていまいち → モバイル3列がいいな
- **実装**: メディアクエリで768px以下を3列固定に変更

### 改善3: 個別ページの幅広い画面対応
- **要望**: 幅の広いページで個別ページ表示がサイドに空白できるダサい
- **実装**: 
  - 最大幅を1200px → 1400pxに拡大
  - 画像の最大幅を1200px、最大高さを80vhに設定
  - 説明文の最大幅を600px → 800pxに拡大
  - タイポグラフィとスペーシングの改善

## コミット履歴

1. **feat: implement illustration view with xkcd-style navigation**
   - 基本機能の実装
   - 個別ページと一覧ページの作成
   - illust_config.jsonの追加

2. **refactor: update illust index to show only images in square tiles**
   - 一覧ページを画像のみの正方形タイル表示に変更

3. **refactor: improve individual illust page layout**
   - 個別ページのレイアウト改善
   - タイトル、画像、ナビゲーション、短い説明、リンクの順に配置

4. **refactor: improve mobile responsive layout for illust index**
   - モバイルで3列表示に変更

5. **refactor: change mobile layout to 3 columns**
   - メディアクエリの調整

6. **refactor: improve individual page layout for wide screens**
   - 幅広い画面での表示改善

## テスト環境

**プレビューURL**:
- 一覧ページ: https://scrapbox-reader-git-devin-1762834682-im-56f057-nishios-projects.vercel.app/ja/illust
- 個別ページ例: https://scrapbox-reader-git-devin-1762834682-im-56f057-nishios-projects.vercel.app/ja/illust/001

**テスト済み環境**:
- デスクトップ（1024px以上）
- タブレット（768px）
- モバイル（410px）

## 今後の拡張案

### Phase 2（未実装）
- 自動設定生成スクリプト
- 完全な英語対応
- タグによるフィルタリング機能

### Phase 3（未実装）
- データパイプライン統合
- 自動更新機能

## 新しいイラストの追加方法

1. マークダウンファイルを`data/ja/pages/`に配置
2. ファイル内にGyazo画像を含める（`![](https://gyazo.com/...)`形式）
3. `illust_config.json`に新しいエントリを追加:
   ```json
   {
     "id": "004",
     "page_ja": "新しいページ名",
     "page_en": null,
     "tags": ["tag1", "tag2"]
   }
   ```
4. ビルドして確認: `npm run build`
5. 開発サーバーで確認: `npm run dev`

## 注意事項

### ランダム機能について
- 現在の実装では、クライアント側で`Math.random()`を使用してランダムIDを生成
- SSR/CSRのハイドレーションミスマッチが発生する可能性があるが、ユーザーの要望により現状維持
- より安定した実装が必要な場合は、`/[lang]/illust/random`ルートを作成してサーバー側でリダイレクトする方法を推奨

### グローバルスタイル
- `.page`クラスの`max-width`は`assets/app.css`で1200pxに設定されている
- イラストページでは`!important`を使用して1400pxに上書き

## 関連リンク

- **PR**: https://github.com/nishio/mem/pull/2
- **PLAN.md**: https://github.com/nishio/mem/blob/master/PLAN.md
- **Devinセッション**: https://app.devin.ai/sessions/f0c54f6ba90f4844b1ae7bd1a798b116

## 連絡先

質問や問題がある場合は、PRにコメントを残してください。
