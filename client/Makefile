prebuild:
ifndef NIX
	flutter pub run pigeon --input ./pigeon/native_communication.dart
endif

dev: prebuild
	flutter run

build-apk: prebuild
	flutter build apk

build-ios: prebuild
	flutter build ios

.PHONY: prebuild dev build-apk build-ios
