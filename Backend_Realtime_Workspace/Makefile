# ============================================================================
# TeamSpot — Makefile
# Development & deployment orchestration
# ============================================================================

.PHONY: help dev start stop restart logs clean test lint install docker-up docker-down docker-logs db-shell redis-cli kafka-topics seed

APP_NAME := teamspot-backend
COMPOSE := docker compose

# ── Help ─────────────────────────────────────────────────────────────────────
help: ## Show this help
	@echo "╔══════════════════════════════════════════════════════╗"
	@echo "║  TeamSpot Backend — Command Reference                ║"
	@echo "╚══════════════════════════════════════════════════════╝"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ── Development ──────────────────────────────────────────────────────────────
install: ## Install dependencies
	npm install

dev: ## Start dev server with nodemon
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
kafka-topics: ## List Kafka topics
	docker exec teamspot-kafka kafka-topics --bootstrap-server localhost:9092 --list

kafka-create-topics: ## Create all required Kafka topics
	node -e "import('./infrastructure/kafka/kafka.service.js').then(k => k.createTopics())"

# ── RabbitMQ ─────────────────────────────────────────────────────────────────
rabbitmq-ui: ## Open RabbitMQ management UI
	@echo "RabbitMQ UI: http://localhost:15672 (teamspot/teamspot_dev_password)"

# ── Cleanup ──────────────────────────────────────────────────────────────────
clean: ## Clean node_modules and build artifacts
	rm -rf node_modules
	rm -rf coverage
	rm -rf dist

clean-all: clean docker-clean ## Clean everything

# ── Health ───────────────────────────────────────────────────────────────────
health: ## Check server health
	@curl -s http://localhost:5000/health | node -e "process.stdin.on('data',d=>console.log(JSON.parse(d)))"

health-detailed: ## Detailed health check
	@curl -s http://localhost:5000/health/detailed | node -e "process.stdin.on('data',d=>console.log(JSON.stringify(JSON.parse(d),null,2)))"
