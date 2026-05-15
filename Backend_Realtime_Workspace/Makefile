# ============================================================================
# TeamSpot — Makefile
# Development & deployment orchestration
# ============================================================================

.PHONY: help dev start stop restart logs clean test lint install \
        docker-up docker-down docker-logs docker-build docker-clean docker-restart docker-up-all \
        db-shell db-status db-seed db-backup \
        redis-cli redis-flush redis-monitor \
        kafka-start kafka-stop kafka-restart kafka-status kafka-logs \
        kafka-topics kafka-create-topics kafka-describe kafka-console kafka-clean kafka-setup kafka-ui \
        rabbitmq-ui clean-all health health-detailed infra

APP_NAME        := teamspot-backend
COMPOSE         := docker compose
KAFKA_HOME      := /usr/local/kafka
KAFKA_BIN       := $(KAFKA_HOME)/bin
KAFKA_CFG       := $(KAFKA_HOME)/config
KAFKA_BOOTSTRAP := localhost:9092

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

dev: kafka-start ## Start Kafka + dev server with nodemon
	npm run dev

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
docker-up: ## Start all infrastructure services
	$(COMPOSE) up -d

docker-up-all: ## Start all services including dev tools
	$(COMPOSE) --profile dev-tools up -d

docker-down: ## Stop all services
	$(COMPOSE) down

docker-restart: ## Restart all services
	$(COMPOSE) down && $(COMPOSE) up -d

docker-logs: ## View docker logs
	$(COMPOSE) logs -f

docker-build: ## Build the app container
	docker build -t $(APP_NAME) .

docker-clean: ## Remove all volumes and containers
	$(COMPOSE) down -v --remove-orphans

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

kafka-create-topics: ## Create all required Kafka topics
	node --input-type=module <<< "import { initKafka, createTopics } from './infrastructure/kafka/kafka.service.js'; await initKafka(); await createTopics(); process.exit(0);"

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

kafka-ui: ## Open Kafka UI in browser (if running)
	@open http://localhost:8080 2>/dev/null || echo "Kafka UI: http://localhost:8080"

# ── RabbitMQ ─────────────────────────────────────────────────────────────────
rabbitmq-ui: ## Open RabbitMQ management UI
	@echo "RabbitMQ UI: http://localhost:15672 (teamspot/teamspot_dev_password)"

# ── Cleanup ──────────────────────────────────────────────────────────────────
clean: ## Clean node_modules and build artifacts
	rm -rf node_modules
	rm -rf coverage
	rm -rf dist

clean-all: clean docker-clean ## Clean everything

# ── Compound / Workflow ──────────────────────────────────────────────────────
infra: docker-up kafka-start ## Start all infrastructure (Docker services + Kafka ready)
	@echo "$(GREEN)✓ Infrastructure ready$(RESET)"

setup: install ## First-time project setup (install dependencies)
	@echo "$(GREEN)✓ Setup complete. Run 'make dev' to start.$(RESET)"

# ── Health ───────────────────────────────────────────────────────────────────
health: ## Check server health
	@curl -s http://localhost:5000/health | node -e "process.stdin.on('data',d=>console.log(JSON.parse(d)))"

health-detailed: ## Detailed health check
	@curl -s http://localhost:5000/health/detailed | node -e "process.stdin.on('data',d=>console.log(JSON.stringify(JSON.parse(d),null,2)))"
