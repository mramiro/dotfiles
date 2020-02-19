INSTALL_DIR := "${HOME}/.local/bin"

help:
	@echo "Run make install to install utility scripts"

install:
	@for i in $$(find "utils" -type f); do \
		target_name=$$(basename $$i | sed 's/\.sh$$//'); \
		dest="${INSTALL_DIR}/$$target_name"; \
		echo "Copying to $$dest"; \
		cp $$i $$dest; \
	done

