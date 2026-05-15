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
KAFKA_CONTAINER := teamspot-kafka
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

# ── Kafka ────────────────────────────────────────────────────────────────────
kafka-start: ## Start Kafka + Zookeeper containers
	@if docker ps --format '{{.Names}}' | grep -q $(KAFKA_CONTAINER); then \
		echo "$(YELLOW)⚠ Kafka already running$(RESET)"; \
	else \
		echo "$(CYAN)Starting Kafka + Zookeeper...$(RESET)"; \
		$(COMPOSE) up -d zookeeper kafka; \
		echo "$(CYAN)Waiting for Kafka to be ready...$(RESET)"; \
		TRIES=0; \
		while [ $$TRIES -lt 15 ]; do \
			TRIES=$$((TRIES + 1)); \
			sleep 2; \
			if docker exec $(KAFKA_CONTAINER) kafka-broker-api-versions --bootstrap-server $(KAFKA_BOOTSTRAP) > /dev/null 2>&1; then \
				echo "$(GREEN)✓ Kafka ready on $(KAFKA_BOOTSTRAP) (took $$((TRIES * 2))s)$(RESET)"; \
				break; \
			fi; \
			echo "$(YELLOW)  waiting... ($$((TRIES * 2))s)$(RESET)"; \
		done; \
		if ! docker exec $(KAFKA_CONTAINER) kafka-broker-api-versions --bootstrap-server $(KAFKA_BOOTSTRAP) > /dev/null 2>&1; then \
			echo "$(RED)✗ Kafka failed to start — check: make kafka-logs$(RESET)"; \
		fi \
	fi

kafka-stop: ## Stop Kafka + Zookeeper containers
	@echo "$(CYAN)Stopping Kafka + Zookeeper...$(RESET)"
	$(COMPOSE) stop kafka zookeeper
	@echo "$(GREEN)✓ Kafka stopped$(RESET)"

kafka-restart: ## Restart Kafka + Zookeeper containers
	$(COMPOSE) restart zookeeper kafka
	@echo "$(GREEN)✓ Kafka restarted$(RESET)"

kafka-status: ## Check if Kafka container is running
	@if docker ps --format '{{.Names}}' | grep -q $(KAFKA_CONTAINER); then \
		echo "$(GREEN)✓ Kafka is running$(RESET)"; \
		docker ps --filter name=$(KAFKA_CONTAINER) --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'; \
	else \
		echo "$(RED)✗ Kafka is not running$(RESET)"; \
	fi

kafka-logs: ## Tail Kafka container logs
	$(COMPOSE) logs -f --tail=100 kafka

kafka-topics: ## List all Kafka topics
	docker exec $(KAFKA_CONTAINER) kafka-topics --bootstrap-server $(KAFKA_BOOTSTRAP) --list

kafka-create-topics: ## Create all required Kafka topics
	node -e "import('./infrastructure/kafka/kafka.service.js').then(k => k.createTopics())"

kafka-describe: ## Describe a Kafka topic (usage: make kafka-describe topic=my.topic)
	docker exec $(KAFKA_CONTAINER) kafka-topics --bootstrap-server $(KAFKA_BOOTSTRAP) --describe --topic $(topic)

kafka-console: ## Consume messages from a topic (usage: make kafka-console topic=my.topic)
	docker exec $(KAFKA_CONTAINER) kafka-console-consumer --bootstrap-server $(KAFKA_BOOTSTRAP) --topic $(topic) --from-beginning

kafka-clean: ## Remove Kafka container and its volume (destructive — requires kafka-start again)
	@echo "$(YELLOW)⚠ Removing Kafka container and data volume$(RESET)"
	$(COMPOSE) stop kafka zookeeper
	$(COMPOSE) rm -f kafka zookeeper
	$(COMPOSE) down -v --remove-orphans
	@echo "$(GREEN)✓ Kafka cleaned — run 'make kafka-start' to restart$(RESET)"

kafka-setup: kafka-start kafka-create-topics ## One-liner: start Kafka + create all topics
	@echo "$(GREEN)✓ Kafka ready with all topics$(RESET)"

kafka-ui: ## Open Kafka UI in browser
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
