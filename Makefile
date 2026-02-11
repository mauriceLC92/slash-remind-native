.PHONY: help build release run clean test

XCODE_PROJECT := SlashRemind.xcodeproj
SCHEME := SlashRemind

help:
	@echo "Available targets:"
	@echo "  make build   - Build Debug configuration"
	@echo "  make release - Build Release configuration"
	@echo "  make run     - Build and launch the app"
	@echo "  make clean   - Clean build artifacts"
	@echo "  make test    - Run unit tests"

build:
	xcodebuild -project $(XCODE_PROJECT) -scheme $(SCHEME) -configuration Debug

release:
	xcodebuild -project $(XCODE_PROJECT) -scheme $(SCHEME) -configuration Release

run: build
	@echo "Launching SlashRemind..."
	# Important: multiple SlashRemind DerivedData folders can exist.
	# Opening all glob matches launches multiple app instances (duplicate menu bar icons).
	# Pick the newest app bundle only.
	@APP_PATH="$$(ls -td $$HOME/Library/Developer/Xcode/DerivedData/SlashRemind-*/Build/Products/Debug/SlashRemind.app 2>/dev/null | head -n 1)"; \
	if [ -n "$$APP_PATH" ]; then \
		open "$$APP_PATH"; \
	else \
		echo "Error: Could not find built app. Try 'make build' first."; \
	fi

clean:
	xcodebuild -project $(XCODE_PROJECT) -scheme $(SCHEME) clean

test:
	xcodebuild -project $(XCODE_PROJECT) -scheme $(SCHEME) test
