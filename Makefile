# Internet Draft Build System
# Supports both local Docker builds and GitHub Actions (i-d-template)

LIBDIR ?= lib
I_D_TEMPLATE_URL ?= https://github.com/martinthomson/i-d-template

# Bootstrap: fetch lib/main.mk if it doesn't exist
$(LIBDIR)/main.mk:
	git clone --depth 1 $(I_D_TEMPLATE_URL) $(LIBDIR)

-include $(LIBDIR)/main.mk

# Local Docker-based build targets (for development without native tools)
DOCKER_COMPOSE ?= docker compose

.PHONY: docker docker-watch docker-shell docker-clean

docker:
	$(DOCKER_COMPOSE) run --rm build

docker-watch:
	$(DOCKER_COMPOSE) run --rm watch

docker-shell:
	$(DOCKER_COMPOSE) run --rm shell

docker-clean:
	$(DOCKER_COMPOSE) down -v
