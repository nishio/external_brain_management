# External Brain Management

[![GitHub](https://img.shields.io/badge/github-nishio%2Fexternal__brain__management-blue.svg)](https://github.com/nishio/external_brain_management)

このリポジトリは、Scrapboxを起点とした外部脳（External Brain）システムの関連リポジトリを統合管理するメタリポジトリです。

## 概要

複数のリポジトリに散在する外部脳関連のプロジェクトを、git submoduleで一元管理しています。

### システム構成

```
┌─────────────────────────────────────────┐
│  Scrapbox (nishio, nishio-en)          │
└─────────────────┬───────────────────────┘
                  │
         ┌────────┴────────┐
         │                 │
         ▼                 ▼
┌──────────────────┐  ┌─────────────────────┐
│ from_scrapbox    │  │ etude-github-actions│
│ データ取得・変換  │  │ 日英翻訳パイプライン  │
└────────┬─────────┘  └─────────────────────┘
         │
         ▼
┌──────────────────────────┐
│ external_brain_in_markdown│
│ Markdownファイル保存       │
└──────────┬───────────────┘
           │
           ▼
     ┌─────────┐
     │   mem   │
     │ Web表示  │
     └─────────┘
```

## 管理対象リポジトリ

| リポジトリ | 役割 | 言語 | 実行環境 |
|----------|-----|------|---------|
| [external_brain_in_markdown](https://github.com/nishio/external_brain_in_markdown) | Markdownコンテンツ保存 (24,000+ページ) | - | - |
| [from_scrapbox](https://github.com/nishio/from_scrapbox) | Scrapbox→Markdown変換 | Python/TypeScript | GitHub Actions |
| [etude-github-actions](https://github.com/nishio/etude-github-actions) | 日英自動翻訳パイプライン | Python/TypeScript | GitHub Actions |
| [mem](https://github.com/nishio/mem) | Scrapbox静的配信サイト | TypeScript/Next.js | Vercel |

## セットアップ

### 初回クローン

```bash
# サブモジュール込みでクローン
git clone --recurse-submodules git@github.com:nishio/external_brain_management.git
cd external_brain_management
```

### 既存リポジトリでサブモジュール初期化

```bash
git submodule update --init --recursive
```

## 使い方

### サブモジュールの更新

全てのサブモジュールを最新版に更新：

```bash
make update
```

または：

```bash
git submodule update --init --remote --recursive
```

### 状態確認

全サブモジュールの現在の状態を確認：

```bash
make status
```

### ポインタの固定

サブモジュールを最新版に更新してコミット：

```bash
make update
git add modules/*
git commit -m "chore: bump submodules"
git push
```

## ディレクトリ構造

```
external_brain_management/
├── docs/                           # ドキュメント
│   └── GITHUB_ACTIONS_PLAN.md     # 自動化プラン
├── scripts/                        # 管理スクリプト
├── modules/                        # サブモジュール
│   ├── external_brain_in_markdown/
│   ├── from_scrapbox/
│   ├── etude-github-actions/
│   └── mem/
├── Makefile                        # 管理コマンド
├── README.md                       # このファイル
└── CLAUDE.md                       # Claude Code向け詳細情報
```

## 主な機能

### 1. データパイプライン管理

Scrapboxからコンテンツを取得し、Markdownに変換、Web配信するまでの一連のパイプラインを管理。

### 2. 自動翻訳

日本語Scrapboxコンテンツを英語に自動翻訳し、英語版Scrapboxに自動投稿。

### 3. 一括操作

分散した複数のリポジトリを一箇所から更新・管理。

### 4. バージョン固定

各リポジトリを特定コミットに固定することで、システム全体の再現性を確保。

## GitHub Actions自動化

将来的に以下の自動化を実装予定：

- サブモジュールの自動更新
- 子リポジトリからの変更通知
- 定期的な健全性チェック

詳細は [`docs/GITHUB_ACTIONS_PLAN.md`](./docs/GITHUB_ACTIONS_PLAN.md) を参照。

## メンテナンス

### 定期タスク

- **週1回**: サブモジュールの更新 (`make update`)
- **週1回**: 状態確認 (`make status`)
- **月1回**: GitHub Actions実行履歴確認
- **必要に応じて**: API キー・Secrets の更新

### トラブルシューティング

#### サブモジュールがデタッチドHEAD状態

```bash
cd modules/<submodule-name>
git checkout main  # または master (memの場合)
git pull
cd ../..
```

#### 特定のサブモジュールのみ更新

```bash
git submodule update --remote modules/<submodule-name>
```

## デプロイ環境

| サービス | URL | リポジトリ |
|---------|-----|-----------|
| mem.nhiro.org | https://mem.nhiro.org/ | mem |

## ライセンス

各サブモジュールのライセンスに従います。

## 関連リンク

- [Scrapbox: From_Scrapbox](https://scrapbox.io/nishio/From_Scrapbox)
- [Scrapbox: etude-github-actions](https://scrapbox.io/nishio/etude-github-actions)
- [mem.nhiro.org](https://mem.nhiro.org/)

## 開発者向け情報

詳細な開発ガイドラインは [`CLAUDE.md`](./CLAUDE.md) を参照してください。

---

**Note**: このリポジトリはメタリポジトリのため、ここで本番ビルドやデプロイは行いません。各サブモジュールリポジトリで個別に実行します。
