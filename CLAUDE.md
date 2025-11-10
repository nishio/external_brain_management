# external_brain_management - プロジェクト情報

このドキュメントはClaude Code用のプロジェクト固有の指示です。

## プロジェクト概要

このリポジトリは**メタリポジトリ（管理用リポジトリ）**で、Scrapboxを起点とした外部脳システムの関連リポジトリをgit submoduleで統合管理しています。

### データフロー概要

```
Scrapbox (nishio, nishio-en)
    ↓
[from_scrapbox] データ取得・変換
    ↓
[external_brain_in_markdown] Markdown保存

[etude-github-actions] 翻訳パイプライン
    ↓
[mem] Web表示 (mem.nhiro.org)
```

## サブモジュール構成

### 1. external_brain_in_markdown
**役割**: Markdownファイルの保存先
- 24,000+のMarkdownページを含む
- Scrapboxから変換されたコンテンツの最終保存先
- 静的サイトジェネレーターへの入力データとして機能

### 2. from_scrapbox
**役割**: Scrapbox → Markdown変換パイプライン
- Scrapboxプロジェクト（nishio, nishio-en）からデータを取得
- 対応するexternal_brain_in_markdown系リポジトリへ自動変換・プッシュ
- Python/TypeScript製のクローラー・変換スクリプト
- GitHub Actionsで定期実行

**出力先**:
- nishio → external_brain_in_markdown
- nishio-en → external_brain_in_markdown_english

### 3. etude-github-actions
**役割**: Scrapbox自動翻訳システム
- 日本語Scrapbox（/nishio）→ 英語Scrapbox（/nishio-en）への自動翻訳
- DeepL APIを使用した翻訳パイプライン
- 差分検出・キャッシュ機能で効率化
- 2つのワークフロー構成：
  1. Commit: 翻訳してGitHubにコミット
  2. Import: 翻訳結果をScrapboxにインポート

**必要なSecrets**:
- `SID`: Scrapboxセッションキー
- `DEEPL_KEY`: DeepL APIキー

### 4. mem
**役割**: Scrapboxコンテンツの静的配信サイト
- yuta0801/scrapbox-readerのフォーク
- https://mem.nhiro.org/ でホスト
- Vercelにデプロイ
- Next.js製
- Scrapbox APIからデータを取得して静的に配信

**注意**: このリポジトリのデフォルトブランチは`master`（他は`main`）

## 開発ガイドライン

### サブモジュールの更新手順

```bash
# 全サブモジュールを最新化
make update

# または
git submodule update --init --remote --recursive

# 状態確認
make status
```

### サブモジュール内での作業

**重要**: サブモジュールディレクトリ内で直接作業する場合の注意点：

1. サブモジュール内でコミットしても、**管理リポジトリのポインタは自動更新されない**
2. サブモジュールで作業した後は、必ず管理リポジトリでポインタを更新：

```bash
cd modules/サブモジュール名
# 作業してコミット
git add . && git commit -m "何か変更"
git push

# 管理リポジトリに戻る
cd ../..
git add modules/サブモジュール名
git commit -m "chore: bump サブモジュール名"
git push
```

### 新しいマシンでのセットアップ

```bash
# リポジトリをクローン（サブモジュール込み）
git clone --recurse-submodules git@github.com:nishio/external_brain_management.git

# または既にクローン済みの場合
git submodule update --init --recursive
```

### GitHub Actions自動化

各サブモジュールが更新された際に、管理リポジトリのポインタを自動更新する仕組みを実装予定。

詳細は `docs/GITHUB_ACTIONS_PLAN.md` を参照。

## トラブルシューティング

### サブモジュールが最新でない

```bash
# 特定のサブモジュールを更新
git submodule update --remote modules/サブモジュール名

# 全て更新
make update
```

### サブモジュールのブランチ切り替え

```bash
cd modules/サブモジュール名
git checkout ブランチ名
cd ../..
git add modules/サブモジュール名
git commit -m "chore: change branch of サブモジュール名"
```

### デタッチドHEAD状態の解消

サブモジュールはコミットハッシュを指すため、デフォルトでデタッチドHEAD状態になります。

```bash
cd modules/サブモジュール名
git checkout main  # または master
git pull
cd ../..
```

## メンテナンス

### 定期チェック項目

- [ ] 週1回: `make update` で全サブモジュールを最新化
- [ ] 週1回: `make status` で状態確認
- [ ] 月1回: GitHub Actionsワークフローの実行履歴確認
- [ ] 必要に応じて: Secrets（SID, DEEPL_KEY）の有効期限確認

### 各リポジトリのデプロイ・実行環境

| リポジトリ | 実行環境 | URL |
|----------|---------|-----|
| from_scrapbox | GitHub Actions | - |
| etude-github-actions | GitHub Actions | - |
| mem | Vercel | https://mem.nhiro.org/ |
| external_brain_in_markdown | 静的ファイル | - |

## diary（作業記録）について

このリポジトリでは `docs/diary/` ディレクトリに日付ごとの作業記録を保存しています。

- **場所**: `docs/diary/YYYY-MM-DD.md`
- **目的**: このメタリポジトリおよび各サブモジュールでの作業内容、調査結果、学びを記録
- **形式**: Markdown形式の詳細な作業ログ
- **記録内容**:
  - 実施した作業内容
  - 遭遇した問題と解決方法
  - コミット履歴
  - 学びと今後の課題

**重要**: 作業内容を記録する際は、必ず `docs/diary/` に当日の日付でファイルを作成または更新してください。

 **データ管理の哲学**:
  - Scrapbox = 人間がデータを吐き出す場（優れたUI）
  - GitHub Markdown = 人間とAIが共同作業する場
  - `external_brain_in_markdown` = 人間由来データのストレージ
  - AI生成データ = 別フォルダーで管理（混在を防ぐ）

## 注意事項

### ブランチ名の違い

- `mem`: **master** ブランチ
- その他: **main** ブランチ

### 本番ビルドについて

このメタリポジトリでは**本番ビルドを行わない**。各サブモジュールリポジトリで個別にビルド・デプロイを実行する設計。

このリポジトリの役割：
- ✅ 全体の見取り図提供
- ✅ 一括操作（更新、状態確認）
- ✅ 特定バージョンへの固定（再現性の確保）
- ❌ ビルドやデプロイは行わない

## 参考リンク

- [初期設計メモ](./initial_chat.md)
- [GitHub Actions自動化プラン](./docs/GITHUB_ACTIONS_PLAN.md)
- [Scrapbox: From_Scrapbox](https://scrapbox.io/nishio/From_Scrapbox)
- [Scrapbox: etude-github-actions](https://scrapbox.io/nishio/etude-github-actions)
