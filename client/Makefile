prebuild:
ifndef NIX
	dart run build_runner build --delete-conflicting-outputs
endif

watch-code-generation: 
	@dart run build_runner watch --delete-conflicting-outputs 1>/dev/null &

dev: prebuild watch-code-generation
	flutter run

dev-test: prebuild watch-code-generation
	flutter run integration_test/app_test.dart -d pixel | awk ' \
	/Warning: integration_test plugin was not detected./ {skip=1} \
		/https:\/\/flutter.dev\/docs\/testing\/integration-tests#testing-on-firebase-test-lab/ {skip=0; next} \
		/Performing hot restart.../ {system("clear"); next} \
		skip {next} \
		{print} \
	'

build-apk: prebuild
	flutter build apk

build-ios: prebuild
	flutter build ios

migrate-create: 
	@echo -n "Name for migration to create : "
	@read name; \
	migrate create -ext sql -dir ./lib/core/database/migrations -tz UTC $$name

.PHONY: prebuild dev dev-test watch-code-generation build-apk build-ios migrate-create
