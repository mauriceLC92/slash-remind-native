# Palette

Command palette window triggered by double-press hotkey detection.

## Architecture

The palette subsystem separates timing detection from window management:

- **DoublePressDetector**: Pure timing logic without CGEvent dependencies
- **CommandPaletteWindowController**: Window lifecycle and positioning
- **CommandPaletteView**: SwiftUI presentation layer

This separation enables unit testing of double-press logic without event infrastructure.

## Design Decisions

### Why Separate DoublePressDetector

The detector is extracted from HotKeyService to:
- Enable isolated unit testing of timing windows without CGEvent mocking
- Allow configuration of key codes and thresholds without touching event tap logic
- Simplify reasoning about stateful timing logic separate from system event handling

### Why DispatchTime for Timing

`DispatchTime.now().uptimeNanoseconds` provides monotonic time unaffected by system clock changes. Using `Date()` or `CFAbsoluteTimeGetCurrent()` could cause false positives/negatives if the user changes system time.

### Double-Press Reset Logic

When double-press succeeds, `lastPress` is set to `nil` (not `now`). This prevents triple-press from triggering a second palette open. The user must wait `threshold` seconds before the next detection window starts.

## Invariants

- **Repeat Key Suppression**: `isRepeat` parameter must be checked; holding `/` key should not trigger palette
- **Threshold Precision**: Timing uses nanoseconds to avoid rounding errors in sub-second thresholds
- **Weak Controller Reference**: HotKeyService holds weak reference to CommandPaletteWindowController to prevent retain cycles
