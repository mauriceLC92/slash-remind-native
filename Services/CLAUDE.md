# Services/

## Files

| File | What | When to read |
| ---- | ---- | ------------ |
| `README.md` | CGEvent tap rationale, protocol-based API design, Sendable patterns, lifecycle invariants, date parsing architecture | Understanding service architecture, debugging concurrency, modifying services |
| `HotKeyService.swift` | CGEvent tap creation, global key capture, Sendable callbacks | Modifying hotkey capture, debugging accessibility permissions, changing event handling |
| `RemindersAPI.swift` | Protocol definition, HTTP implementation, Sendable conformance | Adding API endpoints, changing HTTP behavior, implementing mock for tests |
| `SettingsStore.swift` | UserDefaults wrapper, Observable settings | Adding settings, changing defaults, accessing configuration |
| `NotificationScheduler.swift` | Local notification scheduling | Modifying notification behavior, debugging notification timing |
| `DateParsingService.swift` | Natural language date/time parsing using SoulverCore | Parsing user input, adding date parsing, testing parsing logic |
