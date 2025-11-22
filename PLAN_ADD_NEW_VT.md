# PLAN: add_new_vt.txtから新しいVisual Thinkingを追加

## 現状

### vt_config.json
- 現在27ページ登録（ID 1-28、ID 13は欠番）
- 最大ID: 28
- **問題**: ID 13が欠番のまま（公開済みなので既存IDはずらせない）

### add_new_vt.txt
- 45個のScrapboxページURLがリスト化されている
- 形式: `ページ名 https://scrapbox.io/nishio/エンコード済みページ名`
- 一部は既にvt_config.jsonに登録済み
- **確認済み**: 最新のScrapboxにおいて全ページに画像が存在

### external_brain_in_markdown
- **更新頻度**: 1日1回
- **問題**: Scrapboxとの時差により、最新画像がまだ反映されていない可能性

## 目標

1. add_new_vt.txtから未登録のページを抽出してvt_config.jsonに追加
2. **ID 13の欠番を埋める**（新規ページのうち1つをID 13に割り当て）
3. **今後欠番が生じないようにする仕組みを計画**
4. **external_brain_in_markdown更新頻度問題の改善を計画**

## 既存ツールの確認

### scripts/add_from_memo.js

**機能**:
- memo.txtからページを読み込み
- 重複チェック
- 新しいIDを自動割り当て
- vt_config.jsonに追加

**動作フロー**:
1. memo.txt読み込み（URLからページ名を抽出）
2. vt_config.json読み込み
3. 既存ページとの重複チェック
4. 新規ページを次のIDで追加
5. vt_config.json保存

## 実行プロセス

### ステップ1: add_from_add_new_vt.js を作成

**目的**: add_from_memo.jsをベースに、add_new_vt.txt専用のスクリプトを作成

**主な変更点**:
1. ファイルパスを `add_new_vt.txt` に変更
2. **欠番を自動的に埋めるロジックを追加**

**実装方針**:
```javascript
// 欠番を検出する関数
function findGaps(illusts) {
  const ids = illusts.map(i => i.id).sort((a, b) => a - b);
  const gaps = [];
  const maxId = ids[ids.length - 1];

  for (let i = 1; i < maxId; i++) {
    if (!ids.includes(i)) {
      gaps.push(i);
    }
  }

  return gaps;
}

// 欠番リストを取得
const gaps = findGaps(config.illusts);
console.log(`Found ${gaps.length} gaps: ${gaps.join(', ')}`);

// 新規ページを追加
for (const pageName of newPages) {
  let nextId;

  if (gaps.length > 0) {
    // 欠番があればそこを使う
    nextId = gaps.shift();
    console.log(`  [${nextId}] ${pageName} (filling gap)`);
  } else {
    // 欠番がなければ最大ID+1を使う
    nextId = Math.max(...config.illusts.map(i => i.id), 0) + 1;
    console.log(`  [${nextId}] ${pageName}`);
  }

  config.illusts.push({
    id: nextId,
    page_ja: pageName,
    page_en: null,
    tags: []
  });
}

// IDでソート（重要！）
config.illusts.sort((a, b) => a.id - b.id);
```

**重要な点**:
- 追加時に連番IDをつける = 欠番があればそこを使い、なければ最大ID+1
- これにより、今後欠番が生じない

### ステップ2: スクリプト実行

```bash
cd /Users/nishio/external_brain_management/modules/mem
node scripts/add_from_add_new_vt.js
```

**期待される出力**:
```
Found 45 pages in add_new_vt.txt

Skipping 15 duplicate pages:
  - 分布の中央から削減される
  - 共通部分を共有する絵
  - DRYと疎結合のトレードオフ
  ...

Adding 30 new pages...
  [13] 改善の解像度 (filling gap)
  [29] パレート改善に幅がある
  [30] フォークできるなら熟議支援は不要
  ...
  [58] 辺縁は移動コストが高い

Successfully added 30 pages!
Total pages: 57 (no more gaps)
```

### ステップ3: 結果確認

```bash
cd /Users/nishio/external_brain_management/modules/mem
git diff vt_config.json
```

追加されたページを確認：
- 新しいID（29-58程度）
- page_ja: 日本語ページ名
- page_en: null（英語版未設定）
- tags: []（タグなし）

### ステップ4: コミット

```bash
cd /Users/nishio/external_brain_management/modules/mem
git add vt_config.json
git commit -m "feat: add XX new VT pages from add_new_vt.txt"
git push
```

### ステップ5: 親リポジトリでポインタ更新

```bash
cd /Users/nishio/external_brain_management
git add modules/mem
git commit -m "chore: update mem submodule with new VT pages"
git push
```

## 追加後のタスク（オプション）

### 英語版の追加

新しく追加されたページの英語版を作成する場合：

```bash
cd /Users/nishio/external_brain_management/modules/mem
pnpm tsx scripts/translate_vt_pages.ts
```

- OpenAI gpt-4oで高品質翻訳を生成
- `translations/vt/` に出力
- レビュー後、external_brain_in_markdown_englishに移動

### タグの追加

vt_config.jsonを手動編集して、関連するタグを追加：
- philosophy
- communication
- democracy
- structure
など

## 詳細な新規ページリスト（予想）

add_new_vt.txtから、vt_config.jsonに未登録のページ：

1. 改善の解像度
2. パレート改善に幅がある
3. フォークできるなら熟議支援は不要
4. 船のメタファー
5. コミュニティのフォークの実例
6. 政策の修正
7. 一時的に悪かったが結果的に良かった
8. 他人が何を知っているかの全体を知ることはできない
9. 異なる観測範囲の複数の視点に支えられた判断
10. 拡大していくプロセスの不確実性
11. 短期的減少と長期的増加
12. 回して切る
13. 落ちてるものを拾う
14. 自他境界
15. 木に感情移入している
16. 締め切り前ブーストが近すぎる締切でぶつかる
17. 自分と価値観が違う他者がいる状況
18. 濃いところだけ見る
19. 濃い薄い円の図
20. 重なる濃い薄い円の図
21. 曖昧な対立の境界が動く
22. 狭義と広義
23. 一つの概念だと思っていたものが入れ子の二つの概念
24. 辺縁は移動コストが高い

**合計**: 約24-30ページ（重複除外後）

## リスクと対策

### リスク1: external_brain_in_markdownに画像がまだない

**問題**:
- add_new_vt.txtのページは最新Scrapboxに存在
- external_brain_in_markdownは1日1回更新なので時差がある

**対策**:
- スクリプト実行後、from_scrapboxのワークフローを手動実行
- または翌日まで待つ（画像は404だが、翌日には自動的に表示される）

### リスク2: 既存ページとの重複

**対策**:
- add_from_add_new_vt.jsが自動で重複チェック
- 重複ページはスキップされる

### リスク3: ID割り当ての順序

**問題**:
- 最初の新規ページがID 13に割り当てられる
- どのページがID 13になるかは実行順による

**対策**:
- add_new_vt.txtの順序を確認
- 重要なページを最初に配置したい場合は順序を調整
- または実行後にvt_config.jsonを手動で微調整

## 次のアクション

### 今回実装

1. ✅ このPLANファイルを作成
2. ⏸️ scripts/add_from_add_new_vt.js を作成（ID 13欠番を埋めるロジック込み）
3. ⏸️ スクリプト実行
4. ⏸️ vt_config.jsonの差分確認（ID 13が埋まっているか確認）
5. ⏸️ memでコミット・プッシュ
6. ⏸️ 親リポジトリでポインタ更新

### 今後の改善（計画のみ）

7. ⏸️ check_vt_gaps.js を作成（欠番検出スクリプト）
8. ⏸️ from_scrapboxにworkflow_dispatch追加（手動トリガー対応）
9. ⏸️ memにScrapbox APIフォールバック機構追加
10. ⏸️ CLAUDE.mdに運用ルールを追加
11. ⏸️ （オプション）英語版翻訳の実行

## 今後欠番を作らない仕組み（今回実装）

### 問題の原因

**ID 13が欠番になった理由**:
- 前回のバッチ追加時、ID 13として追加しようとしたページがあった
- しかし、そのページのMarkdownにGyazo画像が「まだなかった」（external_brain_in_markdown更新頻度問題）
- そのページはスキップされた（追加しなかった）
- **しかしfor文でIDをインクリメントしていたため、ID 13が飛ばされた**
- 次のページがID 14として追加された

**根本原因**:
- external_brain_in_markdown更新頻度問題（1日1回更新なので時差がある）
- 画像がないページをスキップする際、**IDをインクリメントしてしまった**こと

### 解決策（今回実装）

**追加時に連番IDをつける**:
- 欠番があればそこを使う
- 欠番がなければ最大ID+1を使う
- **これにより、今後欠番が生じない**

**重要な理解**:
- 画像がない時に追加することは適切ではない（不完全なデータが生成されるため）
- add_new_vt.txtにあっても、画像がなければ追加しない（スキップ）
- このファイルは使い続けるので、数日後の実行で画像が揃えば追加される
- その際、欠番を自動的に埋めるロジックにより、欠番は生じない

### 実装内容

**add_from_add_new_vt.js**:
1. 欠番を検出する関数 `findGaps()` を追加
2. 新規追加時に欠番から優先的に割り当て
3. 欠番がなければ最大ID+1を使用
4. IDでソート

**これにより、今後は欠番が生じることはない。**

## external_brain_in_markdown更新頻度問題の改善（計画のみ）

### 問題

- Scrapboxは最新状態
- external_brain_in_markdownは1日1回更新
- VTを追加した直後は画像がまだ反映されていない

### 影響

- add_new_vt.txtのページをvt_config.jsonに追加
- memサイトで表示しようとすると画像が404になる
- 翌日のexternal_brain_in_markdown更新まで待つ必要がある

### 解決策（案）

**方針1: 手動トリガーでGitHub Actions実行**
- from_scrapboxリポジトリのワークフローを手動実行
- 必要なときだけ即座に更新

**方針2: Webhook連携**
- ScrapboxからWebhookを受け取る
- ページ更新時に自動的にGitHub Actionsをトリガー

**方針3: memサイトでScrapbox API直接取得**
- external_brain_in_markdownに画像がない場合
- Scrapbox APIから直接画像URLを取得
- フォールバック機構として実装

**推奨**: 方針1 + 方針3の組み合わせ
- 短期的: 手動トリガーで即座に更新
- 長期的: フォールバック機構で自動対応

### 実装タスク（今後）

1. **from_scrapboxにworkflow_dispatch追加**
   ```yaml
   on:
     schedule:
       - cron: '0 0 * * *'  # 毎日0時
     workflow_dispatch:  # 手動トリガー追加
   ```

2. **memサイトにフォールバック機構**
   ```typescript
   async function getImageUrl(pageJa: string): Promise<string | null> {
     // 1. external_brain_in_markdownから取得を試みる
     const localImage = await getLocalImage(pageJa);
     if (localImage) return localImage;

     // 2. Scrapbox APIから直接取得（フォールバック）
     const scrapboxImage = await fetchFromScrapboxAPI(pageJa);
     return scrapboxImage;
   }
   ```

3. **ドキュメント化**
   - 手動トリガーの手順をCLAUDE.mdに追加
   - VT追加時の推奨フローを明記

## 補足

### add_new_vt.txtの形式

```
ページ名 https://scrapbox.io/nishio/エンコード済みページ名
```

例:
```
改善の解像度 https://scrapbox.io/nishio/%E6%94%B9%E5%96%84%E3%81%AE%E8%A7%A3%E5%83%8F%E5%BA%A6
```

### vt_config.jsonの形式

```json
{
  "illusts": [
    {
      "id": 13,
      "page_ja": "改善の解像度",
      "page_en": null,
      "tags": []
    }
  ],
  "skipped": []
}
```

**重要**: 追加後は必ずIDでソートすること
