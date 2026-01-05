# Building Vigil

Complete guide to building and running the Vigil system monitor for macOS.

## Quick Start

### Option 1: Run Directly (Fastest)
```bash
cd my-istat-app
swift run vigil
```
App launches immediately in menu bar.

### Option 2: Build Release Binary
```bash
cd my-istat-app
swift build -c release
.build/release/vigil
```
Binary at: `.build/release/vigil` (~50MB)

### Option 3: Create Distributable .app Bundle
```bash
cd my-istat-app
./scripts/build-app.sh
```
Creates: `build/Vigil.app` (ready to distribute)

---

## Prerequisites

- **macOS 13.0** or later
- **Swift 5.9+** (included with Xcode 14+)
- For development: **Xcode 14+** (optional)

Check versions:
```bash
swift --version
swiftc --version
```

---

## Build Methods

### Method 1: Swift Package Manager (Recommended)

#### Debug Build (faster, includes debugging symbols)
```bash
cd my-istat-app
swift build
.build/debug/vigil
```

#### Release Build (optimized, smaller)
```bash
cd my-istat-app
swift build -c release
.build/release/vigil
```

#### Run Directly (compile + execute in one step)
```bash
cd my-istat-app
swift run vigil
```

---

### Method 2: Create macOS App Bundle

**Why**: Distributable .app that behaves like a native macOS app

#### Automated Script

Create `my-istat-app/scripts/build-app.sh`:

```bash
#!/bin/bash
set -e

cd "$(dirname "$0")/.."

echo "🔨 Building release binary..."
swift build -c release

echo "📦 Creating app bundle..."
APP_NAME="Vigil"
APP_DIR="build/$APP_NAME.app/Contents"
BINARY_PATH=".build/release/vigil"

# Create directory structure
mkdir -p "$APP_DIR/MacOS"
mkdir -p "$APP_DIR/Resources"

# Copy binary
cp "$BINARY_PATH" "$APP_DIR/MacOS/$APP_NAME"

# Copy Info.plist
cp "my-istat/Info.plist" "$APP_DIR/Info.plist"

# Make executable
chmod +x "$APP_DIR/MacOS/$APP_NAME"

# Create .icns from SF Symbol (optional - uses system default)
# This would require icon generation tooling

echo "✅ Bundle created: build/$APP_NAME.app"
echo "🚀 To run: open build/$APP_NAME.app"
echo "📂 To install: cp -r build/$APP_NAME.app /Applications/"
```

#### Run It

```bash
chmod +x my-istat-app/scripts/build-app.sh
./my-istat-app/scripts/build-app.sh
```

#### Launch the App
```bash
# Run directly
open build/Vigil.app

# Or install to Applications
cp -r build/Vigil.app /Applications/
# Then launch from Launchpad or Applications folder
```

---

### Method 3: Xcode Project

For development in Xcode:

```bash
cd my-istat-app
swift package generate-xcodeproj
open vigil.xcodeproj
```

Then in Xcode:
- **Build**: Cmd+B
- **Run**: Cmd+R
- **Release Build**: Product → Scheme → Edit Scheme → Build Configuration → Release

---

## Troubleshooting

### Error: "main attribute cannot be used in a module that contains top-level code"

**Cause**: Preview blocks or other top-level code in source files

**Fix**: Rebuild with `-parse-as-library` flag (already in Package.swift)

```bash
swift build -c release  # Uses the flag automatically
```

### Error: "MenuBarExtra is only available in macOS 13.0 or newer"

**Fix**: Ensure minimum deployment target is 13.0
- Check `Package.swift`: `.macOS(.v13)`
- Check `Info.plist`: `<string>13.0</string>`

### Warning: "found 1 file(s) which are unhandled"

This is Info.plist, which is included but not used by SPM. Harmless warning.

---

## File Size Reference

| Build Type | Binary Size | Disk Used |
|------------|-------------|-----------|
| Debug      | ~200MB      | 500MB+ (with symbols) |
| Release    | ~50MB       | 50MB |
| .app Bundle | ~50MB       | 50MB |

---

## What Gets Built

### Release Binary (.build/release/vigil)
- Stripped symbols
- Optimized for performance
- Ready for distribution
- Runs from terminal or scripts

### .app Bundle (build/Vigil.app)
- Native macOS application
- Runnable from Finder/Launchpad
- Installable to /Applications/
- Proper macOS app structure:
  ```
  Vigil.app/
  ├── Contents/
  │   ├── MacOS/
  │   │   └── Vigil        (executable binary)
  │   ├── Resources/
  │   └── Info.plist       (app metadata)
  ```

---

## Running the App

### From Terminal
```bash
# Debug build
./.build/debug/vigil

# Release build
./.build/release/vigil

# Via swift run
swift run vigil

# Via open command
open build/Vigil.app
```

### From Finder
1. Navigate to `build/Vigil.app`
2. Double-click or press Space to preview

### From Applications Folder
```bash
cp -r build/Vigil.app /Applications/
# Then open from Applications folder or Spotlight (Cmd+Space)
```

### Launch at Login
1. System Preferences → General → Login Items
2. Add `/Applications/Vigil.app`
3. Or use the app's preferences window (when implemented)

---

## Development Workflow

### Making Changes
```bash
# Edit source files
vim my-istat-app/my-istat/App/main.swift

# Rebuild and run immediately
swift run vigil

# Or build and run from Xcode if you prefer the IDE
open vigil.xcodeproj
```

### Testing Changes
```bash
swift build  # Compile
.build/debug/vigil  # Run the debug build
```

### Before Distribution
```bash
swift build -c release  # Optimize
./my-istat-app/scripts/build-app.sh  # Create .app
# Test: open build/Vigil.app
```

---

## GitHub Actions / CI

To build in CI (GitHub Actions, etc.):

```yaml
name: Build Vigil

on: [push]

jobs:
  build:
    runs-on: macos-13
    steps:
      - uses: actions/checkout@v3
      - name: Build
        run: |
          cd my-istat-app
          swift build -c release
      - name: Upload Artifact
        uses: actions/upload-artifact@v3
        with:
          name: vigil-release
          path: my-istat-app/.build/release/vigil
```

---

## System Requirements

- **macOS 13.0** (Ventura) or later
- **Apple Silicon** (M1+) - primary target
- **Intel** - supported but less tested
- **Free disk space**: 1GB (for build artifacts)

---

## Next Steps

- **First Run**: Menu bar icon appears in top-right
- **Open Dropdown**: Click icon to see CPU/Memory details
- **Preferences**: Click gear icon for settings
- **Quit**: Click icon → Quit Vigil

See [SPECIFICATION.md](docs/SPECIFICATION.md) for feature roadmap.
