# GitHub Actions 自動化プラン

## 概要

このドキュメントでは、external_brain_management メタリポジトリでの自動化について説明します。

## 1. サブモジュール自動更新ワークフロー

### 目的
- 子リポジトリ（サブモジュール）が更新された際に、管理リポジトリのポインタを自動更新
- 定期的な更新チェックで、60日間無活動によるスケジュール停止を回避

### ファイル: `.github/workflows/bump-submodules.yml`

```yaml
name: Bump submodules
on:
  repository_dispatch:
    types: [bump]
  workflow_dispatch:
  schedule:
    - cron: '0 21 * * *'  # JST 6:00 (UTC 21:00)

jobs:
  bump:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: recursive
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Configure git
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"

      - name: Update submodules
        run: git submodule update --init --remote --recursive

      - name: Commit and push if changed
        run: |
          git add modules
          git diff --cached --quiet || (git commit -m "chore: bump submodules [skip ci]" && git push)
```

### 動作説明
1. **repository_dispatch**: 子リポジトリから通知を受けて起動
2. **workflow_dispatch**: 手動実行用
3. **schedule**: 毎日6時（JST）に実行してワークフローの有効性を維持
4. `[skip ci]` でコミット時のワークフロー再実行を防止

---

## 2. 子リポジトリからの通知設定

### 各子リポジトリのワークフローに追加

各サブモジュールリポジトリの既存ワークフローに、以下のステップを追加します：

```yaml
- name: Notify management repo
  if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/master'
  run: |
    curl -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${{ secrets.MGMT_PAT }}" \
      https://api.github.com/repos/nishio/external_brain_management/dispatches \
      -d '{"event_type":"bump"}'
```

### 必要な設定
各子リポジトリのSecretsに `MGMT_PAT` を追加：
- Personal Access Token (PAT) を作成
- スコープ: `repo` または `public_repo`
- 管理リポジトリへのアクセス権限が必要

---

## 3. 対象リポジトリと追加箇所

### 3.1 external_brain_in_markdown
- メインブランチ: `main`
- 対象ワークフロー: 既存のビルド/デプロイワークフロー
- 追加タイミング: pushイベント後

### 3.2 from_scrapbox
- メインブランチ: `main`
- 対象ワークフロー: データ取得/変換ワークフロー
- 追加タイミング: 正常完了後

### 3.3 etude-github-actions
- メインブランチ: `main`
- 対象ワークフロー: 実験用ワークフロー
- 追加タイミング: テスト成功後

### 3.4 mem
- メインブランチ: `master`
- 対象ワークフロー: ビルド/デプロイワークフロー
- 追加タイミング: デプロイ成功後

---

## 4. 追加の自動化案

### 4.1 サブモジュールの健全性チェック
定期的に全サブモジュールの状態をチェック：
- ブランチの乗離確認
- マージ競合の検出
- 依存関係の更新チェック

### 4.2 統合レポート生成
全リポジトリの活動状況を集約：
- 最新コミット情報
- ビルドステータス
- デプロイ状況

### 4.3 セキュリティスキャン
定期的なセキュリティチェック：
- Dependabot alerts の集約
- 脆弱性レポートの生成

---

## 5. 実装の優先順位

### Phase 1（必須）
1. ✅ サブモジュール自動更新ワークフロー作成
2. ⬜ 各子リポジトリへの通知ステップ追加
3. ⬜ PAT の作成とSecrets設定

### Phase 2（推奨）
4. ⬜ 健全性チェックワークフロー追加
5. ⬜ エラー通知の設定

### Phase 3（オプション）
6. ⬜ 統合レポート生成
7. ⬜ セキュリティスキャン統合

---

## 6. メンテナンス

### 定期確認項目
- [ ] PATの有効期限チェック（期限切れ前に更新）
- [ ] ワークフローの実行履歴確認（月1回）
- [ ] サブモジュールのポインタと実体の乖離確認（週1回）

### トラブルシューティング
- ワークフローが60日停止した場合 → 手動で1度実行して再開
- 通知が届かない場合 → PATの権限とSecretsを再確認
- マージ競合が発生した場合 → 手動で解決後、ポインタをコミット
