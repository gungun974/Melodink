SERVER_BINARY=melodink_server

GO=go

GOFLAGS=

DEST=build/

DATABASE_URL=sqlite3://./data/melodink.db

all: build

prebuild:

build: prebuild 
	$(GO) build $(GOFLAGS) -o ${DEST}$(SERVER_BINARY) ./cmd/api/.

debug: prebuild
	$(GO) build -tags debug -o ${DEST}$(SERVER_BINARY) ./cmd/api/.

debug-run: debug
	${DEST}$(SERVER_BINARY)

run: build
	@cd ${DEST}; ./$(SERVER_BINARY)

dev:
	gonova watchexec \
    -i "assets" \
    -i "build" \
    -i "vendor" \
    -i "/data" \
    -i "storage" \
    -i "mails" \
    -i "node_modules" \
    -i "resources/scripts" \
    -i "resources/mails/.react-email" \
    -i "resources/mails/out" \
    -i "resources/mails/node_modules" \
    -i "*_templ.go" \
    -e go \
    -e tpl \
    -e tmpl \
    -e html \
	${MAKE} debug-run


clean:
	$(GO) clean
	$(MAKE) clean-build

clean-build:
	rm -rf $(DEST)

lint:
	golangci-lint run ./...

migrate: 
	gonova migrate up

migrate-down: 
	gonova migrate down --force

migrate-create: 
	gonova migrate create

migrate-force: 
	gonova migrate force --force

migrate-drop: 
	gonova migrate drop --force

.PHONY: all clean prebuild build run watch lint migrate migrate-down migrate-create migrate-force migrate-drop debug debug-run
