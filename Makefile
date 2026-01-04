.PHONY: help build release run clean test

XCODE_PROJECT := ../SlashRemindApp/SlashRemind/SlashRemind.xcodeproj
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
	@open ~/Library/Developer/Xcode/DerivedData/SlashRemind-*/Build/Products/Debug/SlashRemind.app || \
		echo "Error: Could not find built app. Try 'make build' first."

clean:
	xcodebuild -project $(XCODE_PROJECT) -scheme $(SCHEME) clean

test:
	xcodebuild -project $(XCODE_PROJECT) -scheme $(SCHEME) test
