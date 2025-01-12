UNAME_S := $(shell uname -s)
deps:
	flutter pub get

prebuild:
ifndef NIX

ifeq ($(UNAME_S),Darwin)
	cd ios; pod install
	cd macos; pod install
endif

	flutter pub run build_runner build --delete-conflicting-outputs
endif

watch-code-generation: 
	@flutter pub run build_runner watch --delete-conflicting-outputs 1>/dev/null &
	@flutter pub run slang watch 1>/dev/null &

dev: prebuild watch-code-generation
	flutter run

build-android: deps prebuild
	flutter build apk --release

build-android-appbundle: deps prebuild
	flutter build appbundle --release

build-ios: deps prebuild
	flutter build ios --release

build-macos: deps prebuild
	flutter build macos --release

build-windows: deps prebuild
	flutter build windows --release

build-linux: deps prebuild
	flutter build linux --release

migrate-create: 
	@echo -n "Name for migration to create : "
	@read name; \
	migrate create -ext sql -dir ./lib/core/database/migrations -tz UTC $$name

.PHONY: deps prebuild watch-code-generation dev build-android build-android-appbundle build-ios build-macos build-windows build-linux migrate-create
