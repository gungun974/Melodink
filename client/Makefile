prebuild:
	mkdir -p lib/generated/pb
	protoc --dart_out=grpc:lib/generated/pb -I../proto -I$$(dirname $$(which protoc))/../include ../proto/*.proto $$(dirname $$(which protoc))/../include/google/protobuf/*.proto

dev: prebuild
	flutter run

build-apk: prebuild
	flutter build apk

build-ios: prebuild
	flutter build ios

migrate-create: 
	@echo -n "Name for migration to create : "
	@read name; \
	migrate create -ext sql -dir ./lib/core/database/migrations -tz UTC $$name

.PHONY: prebuild dev build-apk build-ios migrate-create
