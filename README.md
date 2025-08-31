# Slash Remind Native

A native macOS menu bar utility that exposes a Spotlight–style command palette to create reminders via a backend API.

## Permissions

- **Input Monitoring / Accessibility** – required for capturing the global hotkey. The app prompts when the event tap fails and offers a shortcut to System Settings > Privacy & Security.
- **Notifications** – requested on first launch when sync is enabled.

## Building

Open the project in Xcode 15+ (macOS 13+). The package contains an Xcode-compatible project structure. Run the `SlashRemind` scheme to build the menu bar app.

## Hotkey

Press `/` twice quickly to reveal the command palette from anywhere on macOS. Type a reminder and hit Return to send it to the configured backend.
