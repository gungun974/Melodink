UNAME_S := $(shell uname -s)
deps:
	flutter pub get

prebuild:
ifndef NIX

ifeq ($(UNAME_S),Darwin)
	cd ios; pod install
	cd macos; pod install
endif

	flutter pub run slang
endif

watch-code-generation: 
	flutter pub run slang watch

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

debug-build-melodink-player:
	cd ./melodink_player && zig build
	cp melodink_player/zig-out/lib/libmelodink_player.so build/linux/x64/release/bundle/lib/libmelodink_player.so
	build/linux/x64/release/bundle/melodink_client

migrate-create: 
	@echo -n "Name for migration to create : "
	@read name; \
	migrate create -ext sql -dir ./lib/core/database/migrations -tz UTC $$name

clean:
	flutter clean
ifeq ($(UNAME_S),Darwin)
	cd ios/MelodinkPlayer; make clean
	cd macos/MelodinkPlayer; make clean
endif
	rm -rf ./melodink_player/zig-out
	rm -rf ./melodink_player/.zig-cache

.PHONY: deps prebuild watch-code-generation dev build-android build-android-appbundle build-ios build-macos build-windows build-linux migrate-create debug-build-melodink-player clean
