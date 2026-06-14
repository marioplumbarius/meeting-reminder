VERSION   ?= 1.0.0
APP        = MeetingReminder
SCHEME     = MeetingReminder
BUILD_DIR  = build
APP_PATH   = $(BUILD_DIR)/Build/Products/Release/$(APP).app
HOMEBREW_CASKROOM = /opt/homebrew/Caskroom/meeting-reminder/local
SYMLINK_PATH = /Applications/$(APP)-Local.app
PKG_NAME   = $(APP)-$(VERSION).pkg
DMG_NAME   = $(APP)-$(VERSION).dmg
DMG_STAGE  = $(BUILD_DIR)/dmg-stage

.PHONY: build dmg pkg installer clean

build:
	xcodebuild \
		-project $(APP).xcodeproj \
		-scheme $(SCHEME) \
		-configuration Release \
		-derivedDataPath $(BUILD_DIR) \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO
	mkdir -p "$(HOMEBREW_CASKROOM)"
	rm -rf "$(HOMEBREW_CASKROOM)/$(APP).app"
	cp -r "$(APP_PATH)" "$(HOMEBREW_CASKROOM)/$(APP).app"
	rm -f "$(SYMLINK_PATH)"
	ln -s "$(HOMEBREW_CASKROOM)/$(APP).app" "$(SYMLINK_PATH)"

# DMG з drag-to-Applications вікном
installer: build
	codesign --force --sign - --deep "$(APP_PATH)"
	rm -f "$(DMG_NAME)"
	create-dmg \
		--volname "$(APP)" \
		--window-size 540 360 \
		--icon-size 120 \
		--icon "$(APP).app" 140 180 \
		--app-drop-link 400 180 \
		"$(DMG_NAME)" \
		"$(APP_PATH)"

clean:
	rm -rf $(BUILD_DIR) $(APP)-*.dmg
