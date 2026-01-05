# Vigil

A lightweight macOS system monitoring application for the menu bar, inspired by iStat Menus.

## Overview

Vigil displays real-time CPU and memory usage in your macOS menu bar with detailed dropdown panels showing historical graphs and system information.

## Phase 1 MVP Features

### Core Monitoring
- **CPU Usage**: Real-time usage percentage, core count, load averages, uptime
- **Memory Usage**: Real-time usage percentage, used/free/total breakdown, compressed memory
- **System Metrics**: Load averages (1m, 5m, 15m), system uptime

### User Interface
- **Menu Bar Integration**: Compact display of CPU and memory metrics with icons (SF Symbols)
- **Dropdown Panels**: Detailed views with system information accessible via menu bar
- **Historical Graphs**: Simple graph visualization of CPU and memory trends over 2 minutes
- **Quick Actions**: Direct access to Activity Monitor and app quit

### Preferences
- **General Settings**: Launch at login, update frequency control (0.5s - 5s)
- **Menu Bar Configuration**: Toggle visibility of individual metrics, display mode selection
- **Alert Settings**: Enable/disable notifications with customizable CPU/memory thresholds

## Architecture

### Project Structure
```
my-istat-app/
├── my-istat/
│   ├── App/
│   │   └── main.swift              # SwiftUI app entry point + AppDelegate
│   ├── Models/
│   │   └── SystemMetrics.swift     # Data structures for metrics
│   ├── Services/
│   │   ├── CPUMonitor.swift        # CPU usage calculations (IOKit)
│   │   ├── MemoryMonitor.swift     # Memory stats (mach/vm_statistics64)
│   │   └── HistoryManager.swift    # Historical data tracking with RingBuffer
│   └── UI/
│       ├── MenuBarViews/
│       │   └── MenuContentView.swift # Menu bar dropdown content
│       ├── DropdownPanels/
│       │   └── DetailPanelView.swift # Detailed metrics with graphs
│       ├── Preferences/
│       │   └── PreferencesWindow.swift # Settings window (3 tabs)
│       └── Components/
│           └── SimpleGraph.swift   # Graph rendering component
```

### Key Components

**SystemMetricsProvider**: Observable object that manages CPU and memory data collection at 1-second intervals

**CPUMonitor**: Uses `host_statistics` API to calculate actual CPU usage from tick counts

**MemoryMonitor**: Uses `host_statistics64` API to fetch real memory stats (active, inactive, wired, compressed)

**HistoryManager**: Ring buffer-based history store keeping 3600 data points (1 hour at 1-second interval)

## Building

### Option 1: Using Swift Package Manager (Easiest)

```bash
cd my-istat-app
swift build -c release
```

The compiled binary will be at: `.build/release/vigil`

### Option 2: Create Xcode Project

If you want an Xcode project for development:

```bash
cd my-istat-app
swift package generate-xcodeproj
open vigil.xcodeproj
```

Then build using Xcode (Cmd+B) or the Product menu.

### Option 3: Build & Run Directly

```bash
cd my-istat-app
swift run vigil
```

### Option 4: Create Standalone App Bundle

```bash
cd my-istat-app
mkdir -p build
swift build -c release
cp .build/release/vigil build/
# Create Vigil.app structure (see below)
```

### Creating a Proper macOS App Bundle

To create a distributable `.app` bundle:

```bash
#!/bin/bash
cd my-istat-app

# Build release binary
swift build -c release

# Create app structure
APP_NAME="Vigil"
APP_DIR="build/$APP_NAME.app/Contents"
BINARY_PATH=".build/release/vigil"

mkdir -p "$APP_DIR/MacOS"
mkdir -p "$APP_DIR/Resources"

# Copy binary
cp "$BINARY_PATH" "$APP_DIR/MacOS/$APP_NAME"

# Copy Info.plist
cp my-istat/Info.plist "$APP_DIR/Info.plist"

# Make it executable
chmod +x "$APP_DIR/MacOS/$APP_NAME"

echo "Created: build/$APP_NAME.app"
```

After creating the bundle, you can:
- Double-click to launch
- Move to `/Applications/` folder
- Use `open build/Vigil.app` to run from terminal

### System Requirements

- macOS 11.0 (Big Sur) or later
- Xcode 13+ (if using Xcode method)
- Swift 5.9+

## Next Phases

**Phase 2**: Network and disk monitoring, notification system, combined menu bar mode
**Phase 3**: Sensor monitoring (fan speeds), weather integration, per-app breakdowns
**Phase 4**: Performance optimization, accessibility, localization, auto-updates

See [SPECIFICATION.md](docs/SPECIFICATION.md) for detailed requirements and design decisions.

## Licensing

Free/open-source - MIT or Apache 2.0 (TBD)
