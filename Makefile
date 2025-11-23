.PHONY: update status vt-add vt-translate vt-move vt-update-config vt-commit vt-all vt-status

update:
	git submodule update --init --remote --recursive

status:
	git submodule foreach 'echo $$name && git rev-parse --abbrev-ref HEAD && git log -1 --oneline'

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
	@echo "=== Committing and pushing changes ==="
	@echo "--- Committing to external_brain_in_markdown_english ---"
	cd modules/external_brain_in_markdown_english && \
		git add . && \
		git commit -m "Add new VT translations" && \
		git push origin main
	@echo "--- Committing to mem ---"
	cd modules/mem && \
		git add vt_config.json && \
		git commit -m "Update vt_config.json with new VT pages" && \
		git push origin main
	@echo "--- Committing to external_brain_management ---"
	git add modules/mem modules/external_brain_in_markdown_english add_new_vt.txt && \
		git commit -m "chore: update VT translations and config" && \
		git push origin main

# Full VT translation workflow (all steps)
vt-all: vt-add vt-translate vt-move vt-update-config vt-commit
	@echo "=== VT translation workflow completed ==="
