SHELL := /bin/bash

# Config
PROJECT_NAME ?= pbx-docker
COMPOSE := docker compose
IMAGE_NAME ?= usyeimar/fusionpbx
FS_IMAGE_NAME ?= usyeimar/freeswitch

# Services (match compose.yml)
APP_SERVICE := fusionpbx
DB_SERVICE := postgres

.PHONY: help up down restart start stop ps logs build rebuild pull exec app-shell db-shell init prune clean buildx freeswitch-build freeswitch-rebuild

help:
	@echo "Make targets for $(PROJECT_NAME):"
	@echo "  up         - Start stack in background"
	@echo "  down       - Stop and remove stack"
	@echo "  restart    - Restart services"
	@echo "  start      - Start existing containers"
	@echo "  stop       - Stop containers"
	@echo "  ps         - List containers"
	@echo "  logs       - Tail all logs"
	@echo "  build      - Build images"
	@echo "  rebuild    - Rebuild without cache"
	@echo "  pull       - Pull latest images"
	@echo "  exec       - Exec into a service (usage: make exec S=<service>)"
	@echo "  app-shell  - Shell into $(APP_SERVICE)"
	@echo "  db-shell   - psql shell into $(DB_SERVICE)"
	@echo "  init       - First-time setup helper"
	@echo "  prune      - Remove stopped containers/networks (keeps volumes)"
	@echo "  clean      - Remove everything incl. volumes"
	@echo "  buildx     - Buildx push image tagged $(IMAGE_NAME) (PLATFORM=linux/amd64 by default)"

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

restart:
	$(COMPOSE) restart

start:
	$(COMPOSE) start

stop:
	$(COMPOSE) stop

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f --tail=200

build:
	$(COMPOSE) build

rebuild:
	$(COMPOSE) build --no-cache

pull:
	$(COMPOSE) pull

# Usage: make exec S=fusionpbx or S=postgres
exec:
	@if [ -z "$$S" ]; then echo "Set S=<service>"; exit 1; fi; $(COMPOSE) exec $$S /bin/sh || $(COMPOSE) exec $$S /bin/bash

app-shell:
	$(COMPOSE) exec $(APP_SERVICE) /bin/bash || $(COMPOSE) exec $(APP_SERVICE) /bin/sh

db-shell:
	$(COMPOSE) exec $(DB_SERVICE) psql -U fusionpbx -d fusionpbx

# First time convenience: pull, up, show status
init: pull up ps

prune:
	$(COMPOSE) down --remove-orphans

clean:
	$(COMPOSE) down -v --remove-orphans

fusionpbx-buildx:
	@echo "Using image tag: $(IMAGE_NAME)"
	@echo "Building and pushing with buildx"
	@if [ -z "$$PLATFORM" ]; then PLATFORM=linux/amd64; else PLATFORM="$$PLATFORM"; fi; \
	  docker buildx build --platform $$PLATFORM --push -t $(IMAGE_NAME) .

# Build FreeSWITCH image using freeswitch/Dockerfile
freeswitch-build:
	docker build -t $(FS_IMAGE_NAME) -f freeswitch/Dockerfile .

freeswitch-rebuild:
	docker build --no-cache -t $(FS_IMAGE_NAME) -f freeswitch/Dockerfile .

