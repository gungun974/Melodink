prebuild:
ifndef NIX
	flutter pub run pigeon --input ./pigeon/native_communication.dart
	flutter pub run build_runner build --delete-conflicting-outputs
endif

watch-code-generation: 
	@flutter pub run build_runner watch --delete-conflicting-outputs 1>/dev/null &

dev: prebuild watch-code-generation
	flutter run

build-apk: prebuild
	flutter build apk

build-ios: prebuild
	flutter build ios

.PHONY: prebuild dev build-apk build-ios
