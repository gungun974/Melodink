prebuild:
ifndef NIX
	dart run build_runner build --delete-conflicting-outputs
endif

watch-code-generation: 
	@dart run build_runner watch --delete-conflicting-outputs 1>/dev/null &

dev: prebuild watch-code-generation
	flutter run


build-apk: prebuild
	flutter build apk

build-ios: prebuild
	flutter build ios

migrate-create: 
	@echo -n "Name for migration to create : "
	@read name; \
	migrate create -ext sql -dir ./lib/core/database/migrations -tz UTC $$name

.PHONY: prebuild dev watch-code-generation build-apk build-ios migrate-create
