# Internet Draft Build System
# Uses containerized i-d-template toolchain

DOCKER_COMPOSE ?= docker compose

.PHONY: all build watch shell clean help

# Default target - build all drafts
all: build

# Build drafts using container
build:
	$(DOCKER_COMPOSE) run --rm build

# Watch for changes and rebuild automatically
watch:
	$(DOCKER_COMPOSE) run --rm watch

# Open interactive shell in container
shell:
	$(DOCKER_COMPOSE) run --rm shell

# Clean build artifacts
clean:
	rm -f draft-*.txt draft-*.html draft-*.xml
	rm -rf lib .gems .venv .refcache .targets.mk

# Remove cached container volumes
clean-all: clean
	$(DOCKER_COMPOSE) down -v

# Show help
help:
	@echo "Internet Draft Build System"
	@echo ""
	@echo "Usage:"
	@echo "  make          Build all drafts (HTML + TXT)"
	@echo "  make watch    Watch for changes and rebuild automatically"
	@echo "  make shell    Open interactive shell in build container"
	@echo "  make clean    Remove build artifacts"
	@echo "  make clean-all  Remove artifacts and cached volumes"
	@echo ""
	@echo "Prerequisites: Docker"
