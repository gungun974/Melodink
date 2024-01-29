SERVER_BINARY=melodink_server

GO=go

GOFLAGS=

DEST=build/

all: build

prebuild:

build: prebild
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

.PHONY: all clean prebuild build run watch lint
