.PHONY: debug release build-apk build-ios analyze test

debug:
	flutter run --debug

release:
	flutter run --release

build-apk:
	flutter build apk --release

build-ios:
	flutter build ios --release

analyze:
	flutter analyze

test:
	flutter test
