# 完了したPLAN

このディレクトリには、完了したPLANファイルを保管しています。

## ファイル一覧

### PLAN_ADD_NEW_VT.md
- **完了日**: 2025-11-22
- **内容**: add_new_vt.txtから新しいVTページを追加する仕組み
- **実装**: `scripts/add_from_add_new_vt.js`
- **使用方法**: `make vt-add`

### PLAN_ENGLISH_VT.md
- **完了日**: 2025-11-22
- **内容**: 英語版VTページの検出とvt_config.json更新
- **実装**: `scripts/update_page_en_from_translations.js`
- **使用方法**: `make vt-update-config`

### PLAN_VT_HIGH_QUALITY_TRANSLATION.md
- **完了日**: 2025-11-15
- **内容**: DeepLからOpenAI gpt-4oへの翻訳エンジン移行
- **実装**: `scripts/translate_vt_pages.ts`, `scripts/move_vt_translations.ts`
- **使用方法**: `make vt-translate` → `make vt-move`

### PLAN_ILLUST_IMPROVEMENT.md
- **完了日**: 2025-11-12
- **内容**: "illust"から"Visual Thinking (VT)"へのブランド移行
- **実装**: VTへの完全移行完了

## 現在進行中のPLAN

現在進行中のPLANは `/PLAN.md` を参照してください。

## 移動理由

完了したPLANファイルをルートディレクトリに残すと、プロジェクト構造が煩雑になるため、このディレクトリに移動しました。

実装内容は以下に統合されています：
- `CLAUDE.md`: 永続的な知識ベース
- `Makefile`: 実行可能なコマンド
- `modules/mem/CLAUDE.md`: memサブモジュール固有の情報
