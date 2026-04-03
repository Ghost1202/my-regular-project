.PHONY: help unit-test integration-test lint swag wire-mongo wire-redis docker-mongo-start docker-mongo-stop docker-redis-start docker-redis-stop format

help: ## Show available make targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "%-22s %s\n", $$1, $$2}'

unit-test: ## Run unit tests for internal packages
	go test -cover ./internal/... -covermode=atomic

integration-test: ## Run integration tests with test dependencies
	@docker compose -f ./docker-compose.test.yml up -d
	@sleep 1 && \
	MONGO_URL="mongodb://127.0.0.1:27017/" \
	MONGO_TODO_DB=TodoDbTest \
	MONGO_CONNECTION_TIMEOUT=20 \
	MONGO_MAX_POOL_SIZE=10 \
	JAEGER_DISABLED=true \
	go test -coverpkg ./... ./test/...
	@docker compose -f ./docker-compose.test.yml down

lint: ## Run golangci-lint and apply automatic fixes
	golangci-lint run --fix -v

swag: ## Generate Swagger documentation
	swag init -g ./cmd/api/main.go -o ./docs

wire-mongo: ## Generate wire dependencies for Mongo implementation
	wire ./internal/wired/mongo.go

wire-redis: ## Generate wire dependencies for Redis implementation
	wire ./internal/wired/redis.go

docker-mongo-start: ## Build and start application with Mongo profile
	docker compose up --build

docker-mongo-stop: ## Stop Mongo profile containers
	docker compose down

docker-redis-start: ## Build and start application with Redis profile
	docker compose -f ./docker-compose.redis.yml up --build

docker-redis-stop: ## Stop Redis profile containers
	docker compose -f ./docker-compose.redis.yml down

format: ## Format Go sources
	go fmt ./internal/...
