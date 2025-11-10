.PHONY: update status

update:
	git submodule update --init --remote --recursive

status:
	git submodule foreach 'echo $$name && git rev-parse --abbrev-ref HEAD && git log -1 --oneline'
