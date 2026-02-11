# Repository Structure: Dual-Repo Setup Explained

## Current Situation

This project currently maintains **two separate copies** of the codebase:

### 1. SPM Repository (This Directory)
**Location**: `/Users/mauricelecordier/Documents/slash-remind-native/`

**What it is**:
- Swift Package Manager project
- Defined by `Package.swift`
- Can build via `swift build`
- Can run tests via `swift test`

**Limitations**:
- ❌ **Cannot run as an actual macOS app**
- Missing proper app bundle structure (no Info.plist, no Resources folder)
- Attempting to run causes runtime errors: `bundleProxyForCurrentProcess is nil`
- This is why you can't just do `swift run` and have the app work

**Current Role**:
- Intended as "source of truth" for code
- Used for quick compilation checks and tests
- **Not used for actual development or running the app**

### 2. Xcode Project (The Running App)
**Location**: `/Users/mauricelecordier/Documents/SlashRemindApp/SlashRemind/`

**What it is**:
- Full Xcode project (`.xcodeproj`)
- Proper macOS app bundle structure
- Contains Info.plist, entitlements, app resources
- Has its own **separate copy** of all source files

**Capabilities**:
- ✅ Can build the app
- ✅ Can run the app
- ✅ Can run tests
- ✅ Can manage SPM dependencies (like SoulverCore)
- ✅ Proper code signing and entitlements

**Current Role**:
- **The only way to actually run the app**
- Where `make build` and `make run` execute
- What you open in Xcode for development

## The Problem: File Synchronization Hell

When you make changes, you face a choice:

### Option A: Edit SPM Repository Files
1. Make changes in `/Users/mauricelecordier/Documents/slash-remind-native/`
2. Tests pass with `swift test` ✅
3. Run the app → **Nothing changes** ❌
4. **Why**: The running app uses different files in the Xcode project
5. **Solution**: Manually copy files to `/Users/mauricelecordier/Documents/SlashRemindApp/SlashRemind/`

### Option B: Edit Xcode Project Files
1. Make changes in `/Users/mauricelecordier/Documents/SlashRemindApp/SlashRemind/`
2. Build and run works ✅
3. **Problem**: SPM repository is now out of sync
4. If you forget to sync back, the repos diverge

### What Happened During Date Parsing Implementation

We ran into this exact problem:

1. ✅ Implemented all 6 milestones in the SPM repository
2. ✅ All `swift test` tests passed (13 tests)
3. ✅ Code compiled successfully
4. ❌ Ran `make build && make run` → **No date parsing happened**
5. 🔍 **Root cause**: The running app was loading files from the Xcode project directory, which didn't have the new code
6. 🔧 **Fix**: Manually copied all modified files from SPM repo to Xcode project

**Files that needed manual copying**:
- Services/DateParsingService.swift (NEW)
- Services/RemindersAPI.swift (MODIFIED)
- Services/NotificationScheduler.swift (MODIFIED)
- ViewModels/PaletteViewModel.swift (MODIFIED)
- App/AppDelegate.swift (MODIFIED)
- Utilities/OSLog+Categories.swift (MODIFIED)
- Tests/*.swift (3 test files)

## Why This Setup Exists

### Historical Context

According to the README:

> *"macOS apps using the UserNotifications framework require proper app bundle structure with Info.plist files. Swift Package Manager cannot create these bundles, causing runtime errors."*

This was true in early SPM versions. The solution at the time:
1. Keep SPM for "clean" architecture and testing
2. Maintain separate Xcode project for actually running the app
3. Manually sync files between them

### Why This Is Outdated

**Modern Reality** (2024+):
- ✅ Xcode projects **can** use Swift Package Manager for dependencies
- ✅ Xcode projects **can** run tests just fine (`⌘+U`)
- ✅ Xcode projects **can** be organized cleanly with proper folder structures
- ✅ You don't need a separate SPM project to get SPM benefits

**What changed**:
- Xcode's SPM integration matured significantly
- Xcode test runners work seamlessly
- App bundles and SPM are no longer mutually exclusive

## The Better Approach: Single Repository

### Recommended Structure

**Use only the Xcode project** at `/Users/mauricelecordier/Documents/SlashRemindApp/SlashRemind/`

**What you get**:
1. ✅ Single source of truth (no syncing needed)
2. ✅ Can build and run the app
3. ✅ Can run tests (`⌘+U` in Xcode or `xcodebuild test`)
4. ✅ Can use SPM dependencies (already using SoulverCore)
5. ✅ Proper version control with one `.git` directory
6. ✅ No risk of files getting out of sync

**What you lose**:
- Nothing meaningful
- You can still run `swift test` from the Xcode project directory if needed

### Migration Steps (Recommended)

If you want to consolidate to a single repository:

1. **Verify Xcode project has all latest code**
   ```bash
   # Compare file contents
   diff -r /Users/mauricelecordier/Documents/slash-remind-native/Services \
           /Users/mauricelecordier/Documents/SlashRemindApp/SlashRemind/Services
   ```

2. **Archive (don't delete yet) the SPM repo**
   ```bash
   mv /Users/mauricelecordier/Documents/slash-remind-native \
      /Users/mauricelecordier/Documents/slash-remind-native.archive
   ```

3. **Update documentation** in the Xcode project
   - Remove references to "SPM as source of truth"
   - Update README to reflect single-repo structure

4. **Test everything still works**
   ```bash
   cd /Users/mauricelecordier/Documents/SlashRemindApp/SlashRemind
   xcodebuild -scheme SlashRemind test
   xcodebuild -scheme SlashRemind build
   ```

5. **After 1-2 weeks of successful development, delete the archive**

## If You Keep the Dual-Repo Setup

### Workflow You Must Follow

If you choose to keep both repositories (not recommended):

**1. Choose a Primary Development Location**
- **Option A**: Always edit in Xcode project, sync back to SPM repo
- **Option B**: Always edit in SPM repo, sync forward to Xcode project

**2. Create a Sync Script**

Create `/Users/mauricelecordier/Documents/sync-repos.sh`:

```bash
#!/bin/bash
# Sync from SPM repo to Xcode project

SPM_ROOT="/Users/mauricelecordier/Documents/slash-remind-native"
XCODE_ROOT="/Users/mauricelecordier/Documents/SlashRemindApp/SlashRemind"

# Sync source files
rsync -av --delete \
  --exclude='.git' \
  --exclude='Package.swift' \
  --exclude='.build' \
  "$SPM_ROOT/Services/" "$XCODE_ROOT/Services/"

rsync -av --delete \
  "$SPM_ROOT/ViewModels/" "$XCODE_ROOT/ViewModels/"

rsync -av --delete \
  "$SPM_ROOT/App/" "$XCODE_ROOT/App/"

rsync -av --delete \
  "$SPM_ROOT/Utilities/" "$XCODE_ROOT/Utilities/"

rsync -av --delete \
  "$SPM_ROOT/Tests/" "$XCODE_ROOT/SlashRemindTests/"

echo "✅ Sync complete"
```

**3. Sync After Every Change**
```bash
# After editing SPM files
chmod +x sync-repos.sh
./sync-repos.sh
cd /Users/mauricelecordier/Documents/SlashRemindApp/SlashRemind
xcodebuild -scheme SlashRemind build
```

**4. Add Git Hooks** (if using version control)

Create `.git/hooks/post-commit`:
```bash
#!/bin/bash
echo "⚠️  Remember to sync to Xcode project!"
```

### Risks of Dual-Repo Setup

1. **File Divergence**: Easy to forget syncing, causing code to drift
2. **Confusion**: Which file is the "real" version?
3. **Merge Conflicts**: When syncing back and forth
4. **Duplicate Effort**: Have to fix bugs in both places
5. **Onboarding**: New developers confused by the setup
6. **CI/CD Complexity**: Build pipelines need to sync repos

## Summary

| Aspect | Current Dual-Repo | Recommended Single-Repo |
|--------|-------------------|-------------------------|
| **Source Locations** | 2 separate directories | 1 Xcode project |
| **File Syncing** | Manual copying required | Not needed |
| **Running App** | Only Xcode project works | Works directly |
| **Running Tests** | Both locations | Xcode project |
| **Maintenance** | High (keep in sync) | Low (one source) |
| **Confusion Risk** | High | None |
| **Modern Best Practice** | ❌ No | ✅ Yes |

**Bottom Line**: The dual-repo setup is technical debt from when SPM couldn't handle app bundles. Modern Xcode eliminates this need. You should consolidate to a single Xcode project.

## Questions?

**Q: Will I lose SPM benefits by using only Xcode?**
A: No. Xcode has full SPM integration. You can still add packages, run tests, and build cleanly.

**Q: What about CI/CD that uses `swift build`?**
A: Switch to `xcodebuild` instead:
```bash
xcodebuild -scheme SlashRemind -configuration Release build
xcodebuild -scheme SlashRemind test
```

**Q: Can I still use Package.swift?**
A: You don't need it. Xcode manages SPM dependencies through its own project file.

**Q: What if I prefer command-line development?**
A: You can still use `xcodebuild` from the terminal. No Xcode GUI required for building/testing.

---

**Last Updated**: 2026-01-07
**Status**: Active dual-repo setup, consolidation recommended
