SERVER_BINARY=melodink_server

GO=go

GOFLAGS=

DEST=build/

DATABASE_URL=sqlite3://./data/melodink.db

all: build

prebuild:
	protoc --proto_path=../proto ../proto/*.proto --go_out=. --go-grpc_out=.

build: prebuild 
	$(GO) build $(GOFLAGS) -o ${DEST}$(SERVER_BINARY) ./cmd/api/.

debug: prebuild
	$(GO) build -tags debug -o ${DEST}$(SERVER_BINARY) ./cmd/api/.

run: build
	@cd ${DEST}; ./$(SERVER_BINARY)

dev:
	@air

clean:
	$(GO) clean
	$(MAKE) clean-build

clean-build:
	rm -rf $(DEST)

lint:
	golangci-lint run ./...

migrate: 
	migrate -database $(DATABASE_URL) \
		-path ./internal/database/migrations up

migrate-down: 
	migrate -database $(DATABASE_URL) \
		-path ./internal/database/migrations down

migrate-create: 
	@echo -n "Name for migration to create : "
	@read name; \
	migrate create -ext sql -dir ./internal/database/migrations -tz UTC $$name

migrate-force: 
	@echo -n "Version to migrate force : "
	@read version; \
	migrate -database $(DATABASE_URL) \
		-path ./internal/database/migrations force $$version

migrate-drop: 
	migrate -database $(DATABASE_URL) \
		-path ./internal/database/migrations drop

.PHONY: all clean prebuild build run watch lint migrate migrate-down migrate-create migrate-force migrate-drop
