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

### リポジトリの同期（整理＆プッシュ）

変更を簡潔なコミットメッセージで整理してプッシュします。長いコミットメッセージによるエラーを回避します。

```bash
# 全リポジトリを一括同期（推奨）
make sync-all

# 個別のリポジトリを同期
make sync-mem           # memのみ
make sync-english       # external_brain_in_markdown_englishのみ
make sync-japanese      # external_brain_in_markdownのみ
make sync-main          # メインリポジトリのみ
```

**動作**:
- 変更がある場合のみコミット＆プッシュ
- 変更がない場合はスキップ
- コミットメッセージは簡潔（"chore: update ..."形式）
- エラーを適切に処理

### Scrapbox同期に関する重要な概念の区別

**⚠️ 混同してはいけない2つの操作**

#### A: GitHubにあるMarkdownをpull（軽量・高頻度）
```bash
cd modules/external_brain_in_markdown
git pull origin main
```
- **目的**: 他の環境（GitHub Actions等）で既に更新されたMarkdownを取得
- **所要時間**: 数秒
- **頻度**: 高い（VTワークフローでは毎回実行）
- **使用例**: `make vt-add` の中で自動実行

#### B: ScrapboxからMarkdown化してGitHubにpush（重い・低頻度）
```bash
make scrapbox-sync
```
- **実際の処理**:
  1. Scrapbox APIからJSONをexport
  2. JSONをMarkdownに変換
  3. external_brain_in_markdownリポジトリにpush
- **所要時間**: 数分～十数分（Scrapboxの全ページを処理）
- **頻度**: 低い（1日1回の自動実行、または手動で最新を即座に取得したい時のみ）
- **使用例**: Scrapboxで新しいVTページを作成した直後に、即座にmemで表示したい場合

**通常のVTワークフロー**:
- **A (git pull)** で十分（1日1回の自動同期が動いているため）
- **B (scrapbox-sync)** は「今すぐ最新のScrapboxデータが必要」な場合のみ手動実行

**例**:
```bash
# 通常のワークフロー（A: git pullのみ）
make vt-add  # 内部で git pull origin main を実行

# 今すぐScrapboxの最新データが必要な場合（B → A）
make scrapbox-sync  # B: Scrapboxから取得してpush
make vt-add         # A: GitHubからpullして追加
```

### Scrapbox即時同期（Manual Sync）- B操作の詳細

**目的**: 1日1回の自動同期を待たずに、最新のScrapboxデータを即座に取得してGitHubにpush

#### 前提条件

`modules/from_scrapbox/.env` ファイルが必要です。以下の内容を作成してください：

```bash
# modules/from_scrapbox/.env
SID=your_scrapbox_session_id
```

**SIDの取得方法**:
1. Scrapboxにログイン
2. ブラウザの開発者ツールを開く（F12）
3. Application → Cookies → `https://scrapbox.io`
4. `connect.sid` の値をコピー

#### 使い方

```bash
# 日本語Scrapbox (nishio) → external_brain_in_markdown
make scrapbox-sync

# 英語Scrapbox (nishio-en) → external_brain_in_markdown_english
make scrapbox-sync-en
```

#### 動作

1. Scrapboxから最新のJSONをエクスポート（Python）
2. JSONをMarkdownに変換（Deno）
3. external_brain_in_markdown（または_english）にコピー
4. 自動的にコミット＆プッシュ

#### 注意事項

- **サブモジュールポインタは自動更新されません**
- 実行後、メインリポジトリで `make sync-main` を実行してポインタを更新してください

#### ユースケース

- Scrapboxで新しいVTページを作成した直後に、memで即座に表示したい
- 翻訳パイプラインの動作確認（1日待たずにテスト）
- Markdown変換の動作確認

#### 依存関係

- Python 3.10+ (requirements.txtに記載)
- Deno v1.x
- Git認証設定（GitHub push用）

### VT（Visual Thinking）翻訳ワークフロー

VTページを追加する方法は2つあります：

#### 方法1: Web UI（推奨） - URL-based関連ページ発見

開発環境で `/admin/vt` にアクセスして、関連ページを視覚的に選択して追加：

```bash
# 開発サーバーを起動
cd modules/mem
yarn dev
# http://localhost:3000/admin/vt にアクセス
```

**使い方**:
1. Scrapbox URLを入力（例: `https://scrapbox.io/nishio/すべての人は最先端`）
2. 「Fetch Related Pages」ボタンをクリック
3. 関連ページが画像付きで表示される:
   - → forward: このページがリンクしている先
   - ← backward: このページにリンクしている元
   - ↔ 2-hop: 2ホップ先のページ
4. チェックボックスで複数選択 or 個別に「Add」ボタン
5. 「Add Selected」で一括追加

**特徴**:
- 画像を見ながら選択できる
- 追加済み・スキップ済みページはグレーアウト表示
- 重複は自動排除
- 開発環境のみアクセス可能（本番では404）

#### 方法2: テキストファイル経由（従来方式）

`add_new_vt.txt` に追加したVTページを翻訳し、vt_config.jsonを更新して全リポジトリにコミットするワークフロー：

```bash
# 1. add_new_vt.txtにページを追加
echo "ページ名 https://scrapbox.io/nishio/..." >> add_new_vt.txt

# 2. 追加・翻訳・pushを一括実行
make vt-quick
```

**`vt-quick`の動作**:
1. add_new_vt.txtからVTページを追加
2. OpenAI gpt-4oで翻訳
3. 翻訳ファイルをexternal_brain_in_markdown_englishに移動
4. vt_config.jsonを自動更新
5. 全リポジトリをcommit & push（rebase付き）

**メリット**:
- 翻訳を忘れることがない
- 自動的にgit pull --rebaseでコンフリクト回避
- 1コマンドで全工程完了

#### その他の使い方

```bash
# 現在の状態を確認
make vt-status

# 全ステップを個別に実行（トラブルシューティング時）
make vt-all
```

#### 個別ステップの実行

トラブルシューティングや部分的な実行が必要な場合は、個別のステップを実行できます：

```bash
# ステップ1: add_new_vt.txt からvt_config.jsonに新規ページを追加
make vt-add

# ステップ2: 未翻訳ページを翻訳（OpenAI gpt-4o使用、時間がかかります）
make vt-translate

# ステップ3: 翻訳ファイルをexternal_brain_in_markdown_englishに移動
make vt-move

# ステップ4: 翻訳ファイルからタイトルを抽出してvt_config.jsonを更新
make vt-update-config

# ステップ5: 全リポジトリにコミット＆プッシュ
make vt-commit
```

#### 注意事項

- `vt-translate` はOpenAI APIを使用するため、クレジットが必要です
  - `.env`ファイルに`OPENAI_API_KEY`を設定する必要があります
  - API quotaエラーが発生した場合は、OpenAIのダッシュボードで確認してください
- `vt-all` は全ステップを順次実行するため、翻訳ページ数によっては時間がかかります
  - 大量のページ（100+）を翻訳する場合、バックグラウンド実行を推奨
- 途中でエラーが発生した場合は、個別ステップで該当箇所から再実行できます
  - スクリプトは冪等性を持つため、同じステップを複数回実行しても安全です

#### ワークフロー完了後の確認

翻訳完了後は以下を確認してください：

```bash
# 1. vt_config.jsonでpage_enがnullのエントリを確認
cd modules/mem
node -e "const c=require('./vt_config.json'); c.illusts.filter(i=>!i.page_en).forEach(i=>console.log('ID',i.id,':',i.page_ja))"

# 2. 翻訳ファイルがすべて移動されたか確認
ls translations/vt/ | wc -l  # 0になっているはず

# 3. 各リポジトリの状態確認
cd /Users/nishio/external_brain_management
make status
```

### サブモジュール内での作業

**重要**: サブモジュールディレクトリ内で直接作業する場合の注意点：

1. サブモジュール内でコミットしても、**管理リポジトリのポインタは自動更新されない**
2. サブモジュールで作業した後は、必ず管理リポジトリでポインタを更新：

#### 方法A: Makefileを使う（推奨）

```bash
cd modules/サブモジュール名
# 作業してコミット
git add . && git commit -m "何か変更"
git push

# 管理リポジトリに戻る
cd ../..

# Makefileで自動更新（推奨）
make sync-main
# または全リポジトリを一括同期
make sync-all
```

#### 方法B: 手動で更新

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

**Makefileを使う利点**:
- コミットメッセージが自動生成される（簡潔で統一）
- 変更がない場合は自動スキップ
- エラー処理が適切に行われる

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

### 大文字小文字の重複ファイル問題

macOSのファイルシステムは大文字小文字を区別しませんが、Gitは区別するため、Git上に大文字版と小文字版のファイルが同時に存在する場合があります（例: `Bashi.md` と `bashi.md`）。

この問題を自動的に解決するスクリプトを用意しています：

```bash
# external_brain_in_markdownリポジトリで実行
cd modules/external_brain_in_markdown
../../scripts/fix_case_duplicates.sh

# または他のサブモジュールで実行
cd modules/サブモジュール名
../../scripts/fix_case_duplicates.sh
```

**スクリプトの動作:**
1. Git上の大文字小文字の重複ファイルを検出
2. 各ファイルの最終コミット日時を確認
3. 古い方を削除、新しい方を保持
4. 確認プロンプトを表示（安全のため）

**手動で確認する場合:**

```bash
# 重複ファイルの検出
git ls-files | sort | tr '[:upper:]' '[:lower:]' | uniq -d

# 特定ファイルの最終更新日時を確認
git log -1 --format="%ai %s" -- pages/ファイル名.md
```

**コミット後:**

```bash
# 変更をコミット
git commit -m "chore: remove duplicate files with case differences"
git push origin main

# メインリポジトリでサブモジュールポインタを更新
cd ../..
git add modules/サブモジュール名
git commit -m "chore: update submodule after case cleanup"
git push origin main
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

## 環境変数の設定

このプロジェクトでは2種類の`.env`ファイルが必要です：

### 1. プロジェクトルートの `.env`（VT翻訳用）

VT翻訳スクリプトを使用する場合：

```bash
# .env (このリポジトリのルート)
OPENAI_API_KEY=sk-xxx...  # OpenAI API Key（VT翻訳に使用）
```

**確認方法**:
```bash
cd modules/mem
node -e "require('dotenv').config({path:'../../.env'}); console.log('OPENAI_API_KEY:', process.env.OPENAI_API_KEY ? '設定済み' : '未設定')"
```

### 2. from_scrapboxの `.env`（Scrapbox同期用）

Scrapbox即時同期（`make scrapbox-sync`）を使用する場合：

```bash
# modules/from_scrapbox/.env
SID=your_scrapbox_session_id
```

**SID取得方法**:
1. Scrapboxにログイン
2. ブラウザの開発者ツール（F12）
3. Application → Cookies → `https://scrapbox.io`
4. `connect.sid` の値をコピー

### 重要事項

- **両方の`.env`ファイルは`.gitignore`に含まれており、Gitにコミットされません**
- **API Key/SIDは絶対に公開リポジトリにコミットしないでください**
- サブモジュール（`modules/mem`など）からもルートの`.env`を参照できます

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

## Visual Thinking Gallery (mem)

memサブモジュールの詳細は `modules/mem/CLAUDE.md` を参照してください。

### 重要なポイント

- **デフォルトブランチ**: `master`（他のリポジトリは`main`）
- **デプロイ前の必須チェック**: `yarn build` で型エラーがないことを確認
- **デプロイ**: masterにpushすると自動的にVercelデプロイ

### Featured Illustrations機能（2025-11-25実装）

**目的**: 初回訪問者が最初の一歩を踏み出しやすくする

**実装**:
- `vt_config.json` に `featured?: boolean` フラグを追加可能
- `/[lang]/vt` エントランスページ上部にFeatured専用セクションを表示
- 青いボーダーで視覚的に区別、タイトルは非表示（「図を先に見る」哲学を維持）

**テスト待ち**:
- `featured: true` を追加してローカルで確認: `cd modules/mem && yarn dev`
- 問題なければ、Vercelで自動デプロイ（既にmasterにpush済み）

**実装ファイル**: `modules/mem/pages/[lang]/vt/index.tsx`

## ドキュメント管理

### 現在進行中のPLAN

- **PLAN.md**: Visual Thinking Gallery改善の実装計画（Week 1-4）

### 完了したPLAN

完了したPLANファイルは `docs/diary/completed_plans/` に保管しています：

- **PLAN_ADD_NEW_VT.md**: add_new_vt.txtからVTページ追加（2025-11-22完了）
- **PLAN_ENGLISH_VT.md**: 英語版VTページ検出とvt_config.json更新（2025-11-22完了）
- **PLAN_VT_HIGH_QUALITY_TRANSLATION.md**: OpenAI gpt-4o翻訳移行（2025-11-15完了）
- **PLAN_ILLUST_IMPROVEMENT.md**: illustからVTへのブランド移行（2025-11-12完了）

詳細は `docs/diary/completed_plans/README.md` を参照してください。

### ドキュメントの役割分担

- **CLAUDE.md**: 永続的な知識ベース（常に参照）
- **PLAN.md**: 現在進行中の実装計画
- **docs/vision.md**: プロジェクトの哲学と原則
- **docs/diary/**: 時系列の作業記録
- **docs/diary/completed_plans/**: 完了した計画の保管

## 参考リンク

- [初期設計メモ](./initial_chat.md)
- [GitHub Actions自動化プラン](./docs/GITHUB_ACTIONS_PLAN.md)
- [Visual Thinking実装計画](./PLAN.md)
- [プロジェクトビジョン](./docs/vision.md)
- [完了したPLAN](./docs/diary/completed_plans/)
- [Scrapbox: From_Scrapbox](https://scrapbox.io/nishio/From_Scrapbox)
- [Scrapbox: etude-github-actions](https://scrapbox.io/nishio/etude-github-actions)
