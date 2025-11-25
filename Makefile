.PHONY: update status sync-mem sync-english sync-japanese sync-main sync-all vt-add vt-translate vt-move vt-update-config vt-commit vt-all vt-quick vt-status scrapbox-sync scrapbox-sync-en

update:
	git submodule update --init --remote --recursive

status:
	git submodule foreach 'echo $$name && git rev-parse --abbrev-ref HEAD && git log -1 --oneline'

# Repository Sync (簡潔なコミットメッセージで整理＆プッシュ)
# ========================================================

# Sync mem repository
sync-mem:
	@echo "=== Syncing mem ==="
	@cd modules/mem && \
		(git add . && git diff --cached --quiet || \
		(git commit -m "chore: update mem" && git push origin main)) || \
		echo "No changes in mem"

# Sync external_brain_in_markdown_english repository
sync-english:
	@echo "=== Syncing external_brain_in_markdown_english ==="
	@cd modules/external_brain_in_markdown_english && \
		(git add . && git diff --cached --quiet || \
		(git commit -m "chore: update pages" && git push origin main)) || \
		echo "No changes in english"

# Sync external_brain_in_markdown repository
sync-japanese:
	@echo "=== Syncing external_brain_in_markdown ==="
	@cd modules/external_brain_in_markdown && \
		(git add . && git diff --cached --quiet || \
		(git commit -m "chore: update pages" && git push origin main)) || \
		echo "No changes in japanese"

# Sync main repository
sync-main:
	@echo "=== Syncing main repository ==="
	@git add -A && \
		(git diff --cached --quiet || \
		(git commit -m "chore: sync submodules" && git push origin main)) || \
		echo "No changes in main"

# Sync all repositories (サブモジュール→メインの順)
sync-all: sync-mem sync-english sync-japanese sync-main
	@echo "=== All repositories synced ==="

# VT Translation Workflow
# =======================

# Check VT translation status
vt-status:
	@echo "=== VT Translation Status ==="
	@cd modules/mem && node scripts/add_from_add_new_vt.js --dry-run || echo "No new VT pages to add"
	@echo ""
	@echo "=== Untranslated VT Pages ==="
	@cd modules/mem && node -e "const config = require('./vt_config.json'); const untranslated = config.illusts.filter(i => i.page_en === null); console.log('Untranslated pages:', untranslated.length); untranslated.slice(0, 5).forEach(i => console.log('  ID', i.id + ':', i.page_ja));"

# Step 1: Add new VT pages from add_new_vt.txt to vt_config.json
vt-add:
	@echo "=== Adding new VT pages from add_new_vt.txt ==="
	cd modules/mem && node scripts/add_from_add_new_vt.js

# Step 2: Translate untranslated VT pages using OpenAI
vt-translate:
	@echo "=== Translating VT pages (this may take a while) ==="
	cd modules/mem && pnpm tsx scripts/translate_vt_pages.ts

# Step 3: Move translation files to external_brain_in_markdown_english
vt-move:
	@echo "=== Moving translation files ==="
	cd modules/mem && pnpm tsx scripts/move_vt_translations.ts

# Step 4: Auto-update vt_config.json with English titles from translations
vt-update-config:
	@echo "=== Updating vt_config.json with English titles ==="
	cd modules/mem && node scripts/update_page_en_from_translations.js

# Step 5: Commit and push all changes across repos
vt-commit:
	@echo "=== Committing and pushing VT changes ==="
	@cd modules/external_brain_in_markdown_english && \
		(git add . && git diff --cached --quiet || \
		(git commit -m "Add VT translations" && git push origin main))
	@cd modules/mem && \
		(git add vt_config.json && git diff --cached --quiet || \
		(git commit -m "Update VT config" && git push origin main))
	@git add modules/mem modules/external_brain_in_markdown_english add_new_vt.txt && \
		(git diff --cached --quiet || \
		(git commit -m "chore: update VT" && git push origin main))

# Full VT translation workflow (all steps)
vt-all: vt-add vt-translate vt-move vt-update-config vt-commit
	@echo "=== VT translation workflow completed ==="

# Quick VT add+translate+push workflow
# Usage: echo "ページ名 https://scrapbox.io/nishio/..." >> add_new_vt.txt && make vt-quick
vt-quick:
	@echo "=== Quick VT workflow: add → translate → push ==="
	@cd modules/mem && node scripts/add_from_add_new_vt.js
	@cd modules/mem && pnpm tsx scripts/translate_vt_pages.ts
	@cd modules/mem && pnpm tsx scripts/move_vt_translations.ts
	@cd modules/mem && node scripts/update_page_en_from_translations.js
	@cd modules/external_brain_in_markdown_english && \
		(git pull --rebase && git add . && git diff --cached --quiet || \
		(git commit -m "feat: add VT translations" && git push origin main))
	@cd modules/mem && \
		(git add vt_config.json && git diff --cached --quiet || \
		(git commit -m "feat: update VT config with new pages and translations" && git push origin master))
	@git add -A && \
		(git diff --cached --quiet || \
		(git commit -m "chore: sync submodules after VT updates" && git push origin main))
	@echo "=== Quick VT workflow completed ==="

# Scrapbox Sync (Manual)
# ======================
# 1日1回の自動同期を待たずに、最新のScrapboxデータを即座に取得してGitHubにpush

# Sync Japanese Scrapbox (nishio) → external_brain_in_markdown
scrapbox-sync:
	@echo "=== Syncing from Scrapbox (nishio) to external_brain_in_markdown ==="
	@if [ ! -f modules/from_scrapbox/.env ]; then \
		echo "ERROR: modules/from_scrapbox/.env not found"; \
		echo "Please create .env with SID variable"; \
		exit 1; \
	fi
	@cd modules/from_scrapbox && bash tasks/update_markdown/run.sh
	@echo "=== Scrapbox sync completed ==="
	@echo "Note: Changes have been pushed to external_brain_in_markdown repository"
	@echo "To update submodule pointer in main repo, run: make sync-main"

# Sync English Scrapbox (nishio-en) → external_brain_in_markdown_english
scrapbox-sync-en:
	@echo "=== Syncing from Scrapbox (nishio-en) to external_brain_in_markdown_english ==="
	@if [ ! -f modules/from_scrapbox/.env ]; then \
		echo "ERROR: modules/from_scrapbox/.env not found"; \
		echo "Please create .env with SID variable"; \
		exit 1; \
	fi
	@cd modules/from_scrapbox && bash tasks/update_markdown_english/run.sh
	@echo "=== Scrapbox English sync completed ==="
	@echo "Note: Changes have been pushed to external_brain_in_markdown_english repository"
	@echo "To update submodule pointer in main repo, run: make sync-main"
