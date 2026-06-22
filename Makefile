# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 Steve Clarke <stephenlclarke@mac.com> - https://xyzzy.tools

SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := ci

PROJECT := MyTimeBuddy.xcodeproj
SCHEME := MyTimeBuddy
CONFIGURATION ?= Debug
BUILD_DESTINATION ?= generic/platform=iOS Simulator
TEST_DESTINATION ?=
DERIVED_DATA ?= build/DerivedData
RESULT_BUNDLE ?= build/MyTimeBuddy.xcresult
COVERAGE_XML ?= coverage.xml
TYPECHECK_DIR ?= build/Typecheck
REQUIRE_SIMULATOR ?= 0
SWIFTFORMAT ?= swiftformat
SWIFTLINT ?= swiftlint
TEST_FRAMEWORK ?= /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks
TEST_PLUGIN ?= /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing/libTestingMacros.dylib

.PHONY: ci build build-for-testing build-for-testing-if-simulator test test-if-simulator coverage coverage-if-simulator clean lint format sonar-scan print-toolchain typecheck xcodeproj

ci: print-toolchain typecheck build-for-testing-if-simulator

xcodeproj:
	ruby Tools/generate-xcodeproj.rb

print-toolchain:
	swift --version
	xcodebuild -version

build:
	xcodebuild \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-configuration "$(CONFIGURATION)" \
		-destination "$(BUILD_DESTINATION)" \
		-derivedDataPath "$(DERIVED_DATA)" \
		CODE_SIGNING_ALLOWED=NO \
		build

build-for-testing:
	xcodebuild \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-configuration "$(CONFIGURATION)" \
		-destination "$(BUILD_DESTINATION)" \
		-derivedDataPath "$(DERIVED_DATA)" \
		CODE_SIGNING_ALLOWED=NO \
		build-for-testing

build-for-testing-if-simulator:
	@simulator_name="$$(xcrun simctl list devices available | awk -F '[()]' '/iPhone/ { gsub(/^[[:space:]]+|[[:space:]]+$$/, "", $$1); print $$1; exit }')"; \
	if [[ -n "$$simulator_name" ]]; then \
		printf 'Using simulator: %s\n' "$$simulator_name"; \
		$(MAKE) build-for-testing BUILD_DESTINATION="platform=iOS Simulator,name=$$simulator_name"; \
	elif [[ "$(REQUIRE_SIMULATOR)" == "1" ]]; then \
		printf 'No available iPhone simulator found.\n' >&2; \
		xcrun simctl list devices available >&2; \
		exit 1; \
	else \
		printf 'No available iPhone simulator found; typecheck completed.\n'; \
	fi

test:
	@if [[ -z "$(TEST_DESTINATION)" ]]; then \
		printf 'TEST_DESTINATION is required for make test, for example platform=iOS Simulator,name=iPhone 16\n' >&2; \
		exit 2; \
	fi
	rm -rf "$(RESULT_BUNDLE)"
	xcodebuild \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-configuration "$(CONFIGURATION)" \
		-destination "$(TEST_DESTINATION)" \
		-derivedDataPath "$(DERIVED_DATA)" \
		-resultBundlePath "$(RESULT_BUNDLE)" \
		CODE_SIGNING_ALLOWED=NO \
		test

coverage:
	@if [[ -z "$(TEST_DESTINATION)" ]]; then \
		printf 'TEST_DESTINATION is required for make coverage, for example platform=iOS Simulator,name=iPhone 16\n' >&2; \
		exit 2; \
	fi
	rm -rf "$(RESULT_BUNDLE)" "$(COVERAGE_XML)"
	xcodebuild \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-configuration "$(CONFIGURATION)" \
		-destination "$(TEST_DESTINATION)" \
		-derivedDataPath "$(DERIVED_DATA)" \
		-resultBundlePath "$(RESULT_BUNDLE)" \
		-enableCodeCoverage YES \
		-parallel-testing-enabled NO \
		CODE_SIGNING_ALLOWED=NO \
		test
	python3 Tools/coverage/xccov-to-sonarqube-generic.py "$(RESULT_BUNDLE)" "$(COVERAGE_XML)" "$$(pwd)"

test-if-simulator:
	@simulator_name="$$(xcrun simctl list devices available | awk -F '[()]' '/iPhone/ { gsub(/^[[:space:]]+|[[:space:]]+$$/, "", $$1); print $$1; exit }')"; \
	if [[ -n "$$simulator_name" ]]; then \
		printf 'Using simulator: %s\n' "$$simulator_name"; \
		$(MAKE) test TEST_DESTINATION="platform=iOS Simulator,name=$$simulator_name"; \
	elif [[ "$(REQUIRE_SIMULATOR)" == "1" ]]; then \
		printf 'No available iPhone simulator found.\n' >&2; \
		xcrun simctl list devices available >&2; \
		exit 1; \
	else \
		printf 'No available iPhone simulator found; typecheck completed.\n'; \
	fi

coverage-if-simulator:
	@simulator_name="$$(xcrun simctl list devices available | awk -F '[()]' '/iPhone/ { gsub(/^[[:space:]]+|[[:space:]]+$$/, "", $$1); print $$1; exit }')"; \
	if [[ -n "$$simulator_name" ]]; then \
		printf 'Using simulator: %s\n' "$$simulator_name"; \
		$(MAKE) coverage TEST_DESTINATION="platform=iOS Simulator,name=$$simulator_name"; \
	elif [[ "$(REQUIRE_SIMULATOR)" == "1" ]]; then \
		printf 'No available iPhone simulator found.\n' >&2; \
		xcrun simctl list devices available >&2; \
		exit 1; \
	else \
		printf 'No available iPhone simulator found; coverage not generated.\n'; \
	fi

typecheck:
	rm -rf "$(TYPECHECK_DIR)"
	mkdir -p "$(TYPECHECK_DIR)"
	xcrun --sdk iphonesimulator swiftc \
		-typecheck \
		-target arm64-apple-ios17.0-simulator \
		$$(find MyTimeBuddy -name '*.swift' | sort)
	xcrun --sdk iphonesimulator swiftc \
		-emit-module \
		-parse-as-library \
		-enable-testing \
		-module-name MyTimeBuddy \
		-target arm64-apple-ios17.0-simulator \
		-F "$(TEST_FRAMEWORK)" \
		$$(find MyTimeBuddy -name '*.swift' | sort) \
		-emit-module-path "$(TYPECHECK_DIR)/MyTimeBuddy.swiftmodule"
	xcrun --sdk iphonesimulator swiftc \
		-typecheck \
		-target arm64-apple-ios17.0-simulator \
		-I "$(TYPECHECK_DIR)" \
		-F "$(TEST_FRAMEWORK)" \
		-load-plugin-library "$(TEST_PLUGIN)" \
		$$(find MyTimeBuddyTests -name '*.swift' | sort)

lint:
	@if command -v "$(SWIFTLINT)" >/dev/null 2>&1; then \
		"$(SWIFTLINT)" lint --strict --quiet MyTimeBuddy MyTimeBuddyTests; \
	else \
		printf 'swiftlint not installed; skipping SwiftLint.\n'; \
	fi
	@if command -v "$(SWIFTFORMAT)" >/dev/null 2>&1; then \
		"$(SWIFTFORMAT)" MyTimeBuddy MyTimeBuddyTests --lint --swift-version 6.0; \
	else \
		printf 'swiftformat not installed; skipping SwiftFormat lint.\n'; \
	fi

format:
	@if command -v "$(SWIFTFORMAT)" >/dev/null 2>&1; then \
		"$(SWIFTFORMAT)" MyTimeBuddy MyTimeBuddyTests --swift-version 6.0; \
	else \
		printf 'swiftformat not installed; cannot format.\n' >&2; \
		exit 2; \
	fi

sonar-scan:
	@if [[ -z "$${SONAR_TOKEN:-}" ]]; then \
		printf 'SONAR_TOKEN is not set; skipping SonarQube scan.\n'; \
	elif [[ ! -f "$(COVERAGE_XML)" ]]; then \
		printf '$(COVERAGE_XML) is missing; run make coverage or make coverage-if-simulator before make sonar-scan\n' >&2; \
		exit 2; \
	elif command -v sonar-scanner >/dev/null 2>&1; then \
		sonar-scanner; \
	else \
		printf 'sonar-scanner is not installed.\n' >&2; \
		exit 2; \
	fi

clean:
	rm -rf build "$(COVERAGE_XML)"
