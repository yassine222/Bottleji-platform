# Fix Build Cycle Error

## Problem
Build cycle error: "Thin Binary" script phase depends on files that require the Widget Extension to be embedded first.

## Solution: Reorder Build Phases in Xcode

### Step 1: Open Xcode
```bash
cd botleji/ios
open Runner.xcworkspace
```

### Step 2: Reorder Build Phases for Runner Target

1. **Select "Runner" target** (in left sidebar, under TARGETS)
2. **Click "Build Phases" tab** (top of editor)
3. **Find "Embed Foundation Extensions"** phase
4. **Drag it UP** to be BEFORE "Thin Binary" phase

**Correct Order Should Be:**
1. [CP] Check Pods Manifest.lock
2. Run Script (Flutter)
3. Sources
4. Frameworks
5. Resources
6. Embed Frameworks
7. **Embed Foundation Extensions** ← Move this UP
8. Thin Binary ← Should come AFTER embedding
9. [CP] Embed Pods Frameworks
10. [CP] Copy Pods Resources

### Step 3: Clean Build

1. **Product → Clean Build Folder** (Shift + ⌘ + K)
2. **Delete Derived Data:**
   - Xcode → Settings → Locations
   - Click arrow next to Derived Data path
   - Delete `Runner-*` folders
3. **Close Xcode**
4. **Delete build folder:**
   ```bash
   cd botleji
   rm -rf build/ios
   ```
5. **Reopen Xcode and rebuild**

### Alternative: Build from Xcode Instead of Flutter

If the cycle persists, try building directly from Xcode:

1. **Select "Runner" scheme**
2. **Select your device**
3. **Product → Build** (⌘B)
4. **Product → Run** (⌘R)

This sometimes resolves Flutter build system issues with extensions.

