# ============================================================================
# TeamSpot — Makefile
# Development & deployment orchestration
# ============================================================================

.PHONY: help dev dev-local dev-tools start stop restart logs shell restart-api build \
	logs-all logs-rabbitmq logs-kafka logs-kafka-ui \
	docker-up docker-down docker-logs docker-build docker-clean docker-restart docker-up-all \
        db-shell db-status db-seed db-backup \
        redis-cli redis-flush redis-monitor \
        kafka-start kafka-stop kafka-restart kafka-status kafka-logs \
        kafka-topics kafka-create-topics kafka-describe kafka-console kafka-clean kafka-setup kafka-ui kafka-ui-stop kafka-ui-local \
        rabbitmq-start rabbitmq-stop rabbitmq-restart rabbitmq-status rabbitmq-ui rabbitmq-setup \
        clean-all health health-detailed infra

APP_NAME        := teamspot-backend
COMPOSE         := docker compose -p teamspot
KAFKA_HOME      := /usr/local/kafka
KAFKA_BIN       := $(KAFKA_HOME)/bin
KAFKA_CFG       := $(KAFKA_HOME)/config
KAFKA_BOOTSTRAP  := localhost:9092
RABBITMQ_HOME    := /usr/local/opt/rabbitmq
RABBITMQ_SBIN    := $(RABBITMQ_HOME)/sbin
RABBITMQ_PORT    := 5672
RABBITMQ_UI_PORT := 15672
RABBITMQ_USER    := teamspot
RABBITMQ_PASS    := teamspot0000

# Colors
CYAN  := \033[36m
GREEN := \033[32m
YELLOW:= \033[33m
RED   := \033[31m
RESET := \033[0m
BOLD  := \033[1m

# ── Help ─────────────────────────────────────────────────────────────────────
help: ## Show this help
	@echo "╔══════════════════════════════════════════════════════╗"
	@echo "║  TeamSpot Backend — Command Reference                ║"
	@echo "╚══════════════════════════════════════════════════════╝"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ── Development ──────────────────────────────────────────────────────────────
install: ## Install dependencies
	npm install

dev: ## Start full stack in Docker (default — hot-reload, Kafka+RabbitMQ in containers)
	@echo "$(CYAN)Starting TeamSpot in Docker...$(RESET)"
	$(COMPOSE) up --build --remove-orphans -d
	@echo "$(CYAN)Waiting for services to be healthy...$(RESET)"
	@sleep 5
	@$(COMPOSE) ps
	@echo "$(GREEN)✓ Stack running — logs: make logs$(RESET)"
	@echo "  API         → http://localhost:3000"
	@echo "  Kafka UI    → http://localhost:8080"
	@echo "  RabbitMQ UI → http://localhost:15672  (teamspot/teamspot0000)"
	@open http://localhost:3000/health 2>/dev/null || true
	@open http://localhost:8080 2>/dev/null || true
	@open http://localhost:15672 2>/dev/null || true
	$(COMPOSE) logs -f api

dev-local: kafka-start rabbitmq-start ## Start locally without Docker (fallback — uses nodemon)
	@$(MAKE) kafka-ui-local --no-print-directory &
	@$(MAKE) rabbitmq-ui --no-print-directory &
	npm run dev

dev-tools: ## Start full stack + Mongo Express (Docker + dev-tools profile)
	$(COMPOSE) --profile dev-tools up --build --remove-orphans -d
	@echo "$(GREEN)✓ Dev tools up — Mongo Express → http://localhost:8081$(RESET)"

logs: ## Tail API container logs (follow)
	$(COMPOSE) logs -f api

logs-all: ## Tail all Docker service logs (follow)
	$(COMPOSE) logs -f

logs-rabbitmq: ## Tail RabbitMQ container logs (follow)
	$(COMPOSE) logs -f rabbitmq

logs-kafka: ## Tail Kafka container logs (follow)
	$(COMPOSE) logs -f kafka

logs-kafka-ui: ## Tail Kafka UI container logs (follow)
	$(COMPOSE) logs -f kafka-ui

shell: ## Open shell in the running api container
	$(COMPOSE) exec api sh

stop: ## Stop all Docker services
	$(COMPOSE) down

restart-api: ## Rebuild + restart only the api container
	$(COMPOSE) up --build -d api

build: ## Build production Docker image
	docker build --target production -t $(APP_NAME):latest .

start: ## Start production server
	npm start

test: ## Run tests
	npm test

test-watch: ## Run tests in watch mode
	npm run test:watch

lint: ## Run ESLint
	npm run lint

lint-fix: ## Run ESLint with auto-fix
	npm run lint:fix

format: ## Run Prettier
	npm run format

# ── Docker ───────────────────────────────────────────────────────────────────
docker-up: ## Start all infrastructure (brokers + kafka-ui) in Docker
	$(COMPOSE) up -d

docker-up-all: dev-tools ## Start all services including dev-tools (mongo-express)

docker-down: ## Stop and remove all containers
	$(COMPOSE) down

docker-restart: ## Restart all Docker services
	$(COMPOSE) down && $(COMPOSE) up -d --build

docker-logs: ## View docker logs
	$(COMPOSE) logs -f

docker-build: ## Build the app container
	docker build -t $(APP_NAME) .

docker-clean: ## Remove all volumes and containers
	$(COMPOSE) down -v --remove-orphans

clean-volumes: ## Remove orphan volumes from old project-name prefixes (one-time migration)
	@echo "$(YELLOW)Removing stale volumes with old project-name prefixes...$(RESET)"
	@docker volume ls --format '{{.Name}}' | \
	  grep -E '^(backend_realtime_workspace|flutter_realtime_workspace)_' | \
	  xargs -r docker volume rm
	@echo "$(GREEN)✓ Stale volumes removed$(RESET)"

# ── Database ─────────────────────────────────────────────────────────────────
db-shell: ## Open MongoDB shell
	docker exec -it teamspot-mongodb mongosh -u teamspot -p teamspot_dev_password teamspot_dev

db-status: ## Check MongoDB replica status
	docker exec -it teamspot-mongodb mongosh --eval "db.adminCommand('ping')"

db-seed: ## Run database seed script
	node scripts/seed.js

db-backup: ## Backup MongoDB data
	docker exec teamspot-mongodb mongodump --out=/dump --db=teamspot_dev -u teamspot -p teamspot_dev_password
	docker cp teamspot-mongodb:/dump ./backups/$(shell date +%Y%m%d_%H%M%S)

# ── Redis ────────────────────────────────────────────────────────────────────
redis-cli: ## Open Redis CLI
	docker exec -it teamspot-redis redis-cli

redis-flush: ## Flush all Redis data
	docker exec -it teamspot-redis redis-cli FLUSHALL

redis-monitor: ## Monitor Redis commands
	docker exec -it teamspot-redis redis-cli MONITOR

# ── Kafka (local install at /usr/local/kafka, KRaft mode — no Zookeeper) ──────
kafka-start: ## Start local Kafka broker (KRaft mode)
	@if nc -z localhost 9092 2>/dev/null; then \
		echo "$(YELLOW)⚠ Kafka already running on $(KAFKA_BOOTSTRAP)$(RESET)"; \
	else \
		if [ ! -f /tmp/kraft-combined-logs/meta.properties ]; then \
			echo "$(CYAN)Formatting KRaft storage (first run)...$(RESET)"; \
			KAFKA_CLUSTER_ID=$$($(KAFKA_BIN)/kafka-storage.sh random-uuid); \
			$(KAFKA_BIN)/kafka-storage.sh format --standalone -t $$KAFKA_CLUSTER_ID -c $(KAFKA_CFG)/server.properties; \
		fi; \
		echo "$(CYAN)Starting Kafka broker (KRaft)...$(RESET)"; \
		$(KAFKA_BIN)/kafka-server-start.sh -daemon $(KAFKA_CFG)/server.properties; \
		echo "$(CYAN)Waiting for Kafka to be ready...$(RESET)"; \
		TRIES=0; \
		while [ $$TRIES -lt 15 ]; do \
			TRIES=$$((TRIES + 1)); \
			sleep 2; \
			if nc -z localhost 9092 2>/dev/null; then \
				echo "$(GREEN)✓ Kafka ready on $(KAFKA_BOOTSTRAP) (took $$((TRIES * 2))s)$(RESET)"; \
				break; \
			fi; \
			echo "$(YELLOW)  waiting... ($$((TRIES * 2))s)$(RESET)"; \
		done; \
		if ! nc -z localhost 9092 2>/dev/null; then \
			echo "$(RED)✗ Kafka failed to start — check: make kafka-logs$(RESET)"; \
		fi \
	fi

kafka-stop: ## Stop local Kafka broker
	@echo "$(CYAN)Stopping Kafka...$(RESET)"
	@$(KAFKA_BIN)/kafka-server-stop.sh 2>/dev/null || true
	@echo "$(GREEN)✓ Kafka stopped$(RESET)"

kafka-restart: kafka-stop kafka-start ## Restart local Kafka

kafka-status: ## Check if local Kafka is running
	@if nc -z localhost 9092 2>/dev/null; then \
		echo "$(GREEN)✓ Kafka is running on $(KAFKA_BOOTSTRAP)$(RESET)"; \
		lsof -i :9092 -sTCP:LISTEN 2>/dev/null | head -5; \
	else \
		echo "$(RED)✗ Kafka is not running$(RESET)"; \
	fi

kafka-logs: ## Tail Kafka broker log
	@tail -f /tmp/kafka-logs/server.log 2>/dev/null || \
		tail -f $(KAFKA_HOME)/logs/server.log 2>/dev/null || \
		echo "$(RED)Log file not found — check /tmp/kafka-logs/ or $(KAFKA_HOME)/logs/$(RESET)"

kafka-topics: ## List all Kafka topics
	$(KAFKA_BIN)/kafka-topics.sh --bootstrap-server $(KAFKA_BOOTSTRAP) --list

kafka-create-topics: ## Create all required Kafka topics (works in Docker or local)
	@if docker ps --format '{{.Names}}' 2>/dev/null | grep -q teamspot-kafka; then \
		echo "$(CYAN)Creating topics via Docker container...$(RESET)"; \
		docker exec teamspot-kafka bash -c \
			'kafka-topics.sh --bootstrap-server localhost:9092 --create --if-not-exists --topic notifications --partitions 3 --replication-factor 1 && \
			kafka-topics.sh --bootstrap-server localhost:9092 --create --if-not-exists --topic messages --partitions 3 --replication-factor 1 && \
			kafka-topics.sh --bootstrap-server localhost:9092 --create --if-not-exists --topic ai-tasks --partitions 3 --replication-factor 1 && \
			kafka-topics.sh --bootstrap-server localhost:9092 --create --if-not-exists --topic analytics --partitions 3 --replication-factor 1'; \
		echo "$(GREEN)✓ Kafka topics created$(RESET)"; \
	else \
		node --input-type=module <<< "import { initKafka, createTopics } from './infrastructure/kafka/kafka.service.js'; await initKafka(); await createTopics(); process.exit(0);"; \
	fi

kafka-describe: ## Describe a Kafka topic (usage: make kafka-describe topic=my.topic)
	$(KAFKA_BIN)/kafka-topics.sh --bootstrap-server $(KAFKA_BOOTSTRAP) --describe --topic $(topic)

kafka-console: ## Consume messages from a topic (usage: make kafka-console topic=my.topic)
	$(KAFKA_BIN)/kafka-console-consumer.sh --bootstrap-server $(KAFKA_BOOTSTRAP) --topic $(topic) --from-beginning

kafka-clean: ## Delete Kafka log data (destructive — run kafka-stop first)
	@echo "$(YELLOW)⚠ Removing Kafka + Zookeeper data directories$(RESET)"
	@$(MAKE) kafka-stop 2>/dev/null || true
	@rm -rf /tmp/kafka-logs /tmp/zookeeper
	@echo "$(GREEN)✓ Kafka data cleaned — run 'make kafka-start' to restart$(RESET)"

kafka-setup: kafka-start kafka-create-topics ## One-liner: start Kafka + create all topics
	@echo "$(GREEN)✓ Kafka ready with all topics$(RESET)"

AKHQ_JAR     := $(HOME)/.local/share/akhq/akhq.jar
AKHQ_VERSION := 0.27.1
AKHQ_URL     := https://github.com/tchiotludo/akhq/releases/download/$(AKHQ_VERSION)/akhq-$(AKHQ_VERSION)-all.jar
AKHQ_CFG     := $(CURDIR)/tools/akhq.yml
AKHQ_PID     := /tmp/akhq.pid
JAVA         := /usr/local/opt/openjdk@21/bin/java

kafka-ui: ## Open Kafka UI in browser (provectus — runs in Docker, http://localhost:8080)
	@if nc -z localhost 8080 2>/dev/null; then \
		echo "$(GREEN)✓ Kafka UI → http://localhost:8080$(RESET)"; \
		open http://localhost:8080 2>/dev/null || true; \
	else \
		echo "$(YELLOW)Kafka UI not yet running — starting Docker stack with: make dev$(RESET)"; \
	fi

kafka-ui-local: ## Start AKHQ Kafka UI for local dev (no Docker)
	@if nc -z localhost 8080 2>/dev/null; then \
		echo "$(YELLOW)⚠ Kafka UI already running → http://localhost:8080$(RESET)"; \
		open http://localhost:8080 2>/dev/null || true; \
	else \
		if [ ! -f "$(AKHQ_JAR)" ]; then \
			echo "$(CYAN)Downloading AKHQ $(AKHQ_VERSION) (~50 MB, one-time)...$(RESET)"; \
			mkdir -p $$(dirname $(AKHQ_JAR)); \
			curl -L --progress-bar "$(AKHQ_URL)" -o "$(AKHQ_JAR)"; \
		fi; \
		echo "$(CYAN)Starting Kafka UI (AKHQ) on :8080...$(RESET)"; \
		$(JAVA) -Dmicronaut.config.files=$(AKHQ_CFG) -jar $(AKHQ_JAR) > /tmp/akhq.log 2>&1 & echo $$! > $(AKHQ_PID); \
		TRIES=0; \
		while [ $$TRIES -lt 20 ]; do \
			TRIES=$$((TRIES + 1)); \
			sleep 2; \
			if nc -z localhost 8080 2>/dev/null; then \
				echo "$(GREEN)✓ Kafka UI ready → http://localhost:8080$(RESET)"; \
				open http://localhost:8080 2>/dev/null || true; \
				break; \
			fi; \
			echo "$(YELLOW)  waiting... ($$((TRIES * 2))s)$(RESET)"; \
		done; \
		if ! nc -z localhost 8080 2>/dev/null; then \
			echo "$(RED)✗ Kafka UI failed — check: tail /tmp/akhq.log$(RESET)"; \
		fi \
	fi

kafka-ui-stop: ## Stop AKHQ Kafka UI
	@if [ -f $(AKHQ_PID) ]; then \
		kill $$(cat $(AKHQ_PID)) 2>/dev/null && rm -f $(AKHQ_PID) && echo "$(GREEN)✓ Kafka UI stopped$(RESET)"; \
	else \
		echo "$(YELLOW)Kafka UI not running$(RESET)"; \
	fi

# ── RabbitMQ (local brew install at /usr/local/opt/rabbitmq) ────────────────
rabbitmq-start: ## Start local RabbitMQ broker (brew)
	@if nc -z localhost $(RABBITMQ_PORT) 2>/dev/null; then \
		echo "$(YELLOW)⚠ RabbitMQ already running on :$(RABBITMQ_PORT)$(RESET)"; \
	else \
		echo "$(CYAN)Starting RabbitMQ...$(RESET)"; \
		$(RABBITMQ_SBIN)/rabbitmq-server -detached; \
		TRIES=0; \
		while [ $$TRIES -lt 15 ]; do \
			TRIES=$$((TRIES + 1)); \
			sleep 2; \
			if nc -z localhost $(RABBITMQ_PORT) 2>/dev/null; then \
				echo "$(GREEN)✓ RabbitMQ ready on :$(RABBITMQ_PORT) (took $$((TRIES * 2))s)$(RESET)"; \
				break; \
			fi; \
			echo "$(YELLOW)  waiting... ($$((TRIES * 2))s)$(RESET)"; \
		done; \
		if ! nc -z localhost $(RABBITMQ_PORT) 2>/dev/null; then \
			echo "$(RED)✗ RabbitMQ failed to start$(RESET)"; \
		fi \
	fi

rabbitmq-stop: ## Stop local RabbitMQ broker
	@echo "$(CYAN)Stopping RabbitMQ...$(RESET)"
	@$(RABBITMQ_SBIN)/rabbitmqctl stop 2>/dev/null || true
	@echo "$(GREEN)✓ RabbitMQ stopped$(RESET)"

rabbitmq-restart: rabbitmq-stop rabbitmq-start ## Restart local RabbitMQ

rabbitmq-status: ## Check RabbitMQ status
	@if nc -z localhost $(RABBITMQ_PORT) 2>/dev/null; then \
		echo "$(GREEN)✓ RabbitMQ is running on :$(RABBITMQ_PORT)$(RESET)"; \
		$(RABBITMQ_SBIN)/rabbitmqctl list_queues 2>/dev/null | head -20; \
	else \
		echo "$(RED)✗ RabbitMQ is not running$(RESET)"; \
	fi

rabbitmq-ui: ## Open RabbitMQ management UI in browser
	@echo "$(CYAN)RabbitMQ UI → http://localhost:$(RABBITMQ_UI_PORT) ($(RABBITMQ_USER)/$(RABBITMQ_PASS))$(RESET)"
	@open http://localhost:$(RABBITMQ_UI_PORT) 2>/dev/null || true

rabbitmq-setup: rabbitmq-start ## Ensure user + vhost are configured
	@$(RABBITMQ_SBIN)/rabbitmqctl add_user $(RABBITMQ_USER) $(RABBITMQ_PASS) 2>/dev/null || true
	@$(RABBITMQ_SBIN)/rabbitmqctl set_user_tags $(RABBITMQ_USER) administrator
	@$(RABBITMQ_SBIN)/rabbitmqctl set_permissions -p / $(RABBITMQ_USER) ".*" ".*" ".*"
	@$(RABBITMQ_SBIN)/rabbitmq-plugins enable rabbitmq_management 2>/dev/null | tail -1
	@echo "$(GREEN)✓ RabbitMQ user '$(RABBITMQ_USER)' configured$(RESET)"

# ── Cleanup ──────────────────────────────────────────────────────────────────
clean: ## Clean node_modules and build artifacts
	rm -rf node_modules
	rm -rf coverage
	rm -rf dist

clean-all: clean docker-clean ## Clean everything

# ── Compound / Workflow ──────────────────────────────────────────────────────
infra: dev ## Start full infrastructure (Docker-first)
	@echo "$(GREEN)✓ Infrastructure ready (Docker)$(RESET)"

infra-local: docker-up kafka-start rabbitmq-start ## Start infra locally (no API in Docker)
	@echo "$(GREEN)✓ Local infrastructure ready$(RESET)"

setup: install ## First-time project setup (install dependencies)
	@echo "$(GREEN)✓ Setup complete. Run 'make dev' to start.$(RESET)"

# ── Health ───────────────────────────────────────────────────────────────────
health: ## Check server health
	@curl -s http://localhost:3000/health | node -e "process.stdin.on('data',d=>console.log(JSON.parse(d)))"

health-detailed: ## Detailed health check
	@curl -s http://localhost:3000/health/detailed | node -e "process.stdin.on('data',d=>console.log(JSON.stringify(JSON.parse(d),null,2)))"
