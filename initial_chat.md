nishio: 色々なリポジトリに情報が散っているので、external_brain_managementみたいなrepoを作ってgit submoduleで関連したrepoを全部子要素にすると言うのはどう？

gpt5:
あり。**“管理用メタリポジトリ＋git submodule”** は、散らばった外部脳系リポを一箇所から見渡して操作するのに向いてます。ただし**“制御盤”用途に限る**のがコツ（そこ自体で本番ビルドしない）。

# どう組むか（最小構成）

```
external_brain_management/
  docs/               # 流れ図・運用メモ
  scripts/            # 一括操作スクリプト
  modules/            # サブモジュール置き場
    external_brain_in_markdown/  (submodule)
    from_scrapbox/                (submodule)
    etude-github-actions/         (submodule)
    mem/                          (submodule)
  Makefile or justfile
  .gitmodules
```

## 初期化コマンド

```bash
mkdir external_brain_management && cd $_
git init

# サブモジュール追加（mainブランチ追従設定付き）
git submodule add -b main https://github.com/nishio/external_brain_in_markdown modules/external_brain_in_markdown
git submodule add -b main https://github.com/nishio/from_scrapbox            modules/from_scrapbox
git submodule add -b main https://github.com/nishio/etude-github-actions     modules/etude-github_actions
git submodule add -b main https://github.com/nishio/mem                      modules/mem

# 追従ブランチを .gitmodules に明記（将来の混乱防止）
git submodule set-branch --branch main modules/external_brain_in_markdown
git submodule set-branch --branch main modules/from_scrapbox
git submodule set-branch --branch main modules/etude-github_actions
git submodule set-branch --branch main modules/mem

git add . && git commit -m "chore: add submodules"
```

## 使い方（自分用フロー）

* クローン：`git clone --recurse-submodules git@github.com:nishio/external_brain_management.git`
* まとめて最新化：`git submodule update --init --remote --recursive`
* **更新を固定**（ポインタ更新を記録）：

  ```bash
  git submodule update --remote --recursive
  git add modules/*            # ポインタの差分が乗る
  git commit -m "chore: bump submodules"
  git push
  ```

  > 注意：サブモジュール側に直接コミットしただけでは**管理リポのポインタは動かない**。上の「bump」コミットが必要。

## Makefile（最小）

```make
update:
\tgit submodule update --init --remote --recursive

status:
\tgit submodule foreach 'echo $$name && git rev-parse --abbrev-ref HEAD && git log -1 --oneline'
```

# メリット / デメリット

**◎ メリット**

* ワンコマンドで**全体を取得・更新**できる
* それぞれを**特定コミットに固定**でき、再現性が高い
* docs/ に**全体図・手順・Secrets一覧**を集中管理できる

**△ デメリット（運用で回避可）**

* **ポインタ更新の二度手間**（各リポにPush→管理リポもBump）
  → 毎週またはイベント時に Make `update` を回してBump
* Vercel/GitHub Actionsの**ビルド対象**は各リポのままに（管理リポで本番ビルドはしない）
* 60日無活動でスケジュールが止まる問題
  → 管理リポに**受け口Workflow**を作り、他リポの更新時に `repository_dispatch` で **自動Bump**して活動継続

### 受け口Workflow例（管理リポ）

```yaml
# .github/workflows/bump-submodules.yml
name: Bump submodules
on:
  repository_dispatch:
    types: [bump]
  workflow_dispatch:
  schedule:
    - cron: '0 21 * * *' # JST 6:00（必要なら）

jobs:
  bump:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: recursive
      - run: git config user.name "nhiro-bot" && git config user.email "bot@example.com"
      - run: git submodule update --init --remote --recursive
      - run: |
          git add modules
          git diff --cached --quiet || git commit -m "chore: bump submodules" && git push
```

### 通知側（各子リポ）からのフック例

```yaml
# push時に管理リポへ通知（PAT を secrets.MGMT_PAT に）
- name: Notify management repo
  run: |
    curl -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${{ secrets.MGMT_PAT }}" \
      https://api.github.com/repos/nishio/external_brain_management/dispatches \
      -d '{"event_type":"bump"}'
```

# 代案（用途次第で検討）

* **git subtree**：ポインタ管理の煩雑さは減るが、履歴が混ざる／双方向運用が面倒。
* **GitHub Projects**：コード連携ではなく**タスク/リリースの俯瞰**に向く。
* **Monorepo**：密結合なら有効だが、今回のような**別用途の自動処理/サイト**は切り分けの方が安全。

---

## 結論

**管理用メタリポ＋submodule**は適切。
「本番ビルドは各リポ」「管理リポは**見取り図＋一括操作＋ポインタ固定**」に徹して、上の `update`/`bump` フローと `repository_dispatch` を入れておけば、**散在の可視化と再現性**が一気に上がります。
