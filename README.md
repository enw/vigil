# Vigil

A lightweight macOS system monitoring application for the menu bar, inspired by iStat Menus.

## Overview

Vigil displays real-time CPU and memory usage in your macOS menu bar with detailed dropdown panels showing historical graphs and system information.

## Implemented Features

### System Monitoring
- **CPU Monitoring**: Real-time usage %, individual core tracking, load averages (1m/5m/15m), system uptime
- **Memory Monitoring**: Usage %, memory pressure, free/used/total/compressed breakdown, historical graphs
- **Network Monitoring**: Real-time bandwidth (up/down in Mbps), total bytes, IP addresses, DNS servers, cached for performance
- **Disk Monitoring**: Per-volume space breakdown (used/free/total), health indicators, S.M.A.R.T. status checking
- **Battery Monitoring**: Charge %, health status, charging state, cycle count, time remaining, Bluetooth device batteries
- **Sensor Monitoring**: CPU/GPU temperatures, fan speeds (RPM), color-coded temperature warnings
- **Process Monitoring**: Top processes by CPU and memory usage, PID tracking
- **Weather Integration**: OpenWeatherMap API with temperature, conditions, humidity, wind, sunrise/sunset

### User Interface
- **Menu Bar Integration**: Dynamic combined mode showing "CPU XX% MEM XX%" or individual metric items
- **Dropdown Panels**: 8 detailed views accessible via menu bar click with comprehensive system information
- **Historical Graphs**: 2-minute trend visualization for CPU and memory using Canvas rendering
- **Color-Coded Status**: Temperature warnings (blue/green/orange/red), disk usage (green/yellow/orange/red)
- **Quick Actions**: Activity Monitor, Preferences window, Quit

### Alerts & Notifications
- Rule-based macOS notifications with configurable thresholds
- CPU/Memory high alerts with 60-second cooldown to prevent spam
- Notification history tracking (max 100 entries)
- Graceful initialization avoiding app startup crashes

### Preferences Window
- **General**: Launch at login, update frequency (0.5s - 5s configurable)
- **Menu Bar**: Toggle per-metric visibility, display mode selection
- **Alerts**: Enable/disable notifications, CPU/memory threshold customization (defaults: 80%/85%)

## Architecture

### Project Structure
```
vigil/
├── my-istat/
│   ├── App/
│   │   └── main.swift              # SwiftUI app entry point + AppDelegate
│   ├── Models/
│   │   └── SystemMetrics.swift     # Data structures for metrics
│   ├── Services/
│   │   ├── CPUMonitor.swift        # CPU usage calculations (IOKit)
│   │   ├── MemoryMonitor.swift     # Memory stats (mach/vm_statistics64)
│   │   ├── NetworkMonitor.swift    # Network bandwidth and IP info
│   │   ├── DiskMonitor.swift       # Disk space and volumes
│   │   ├── BatteryMonitor.swift    # Battery status and health
│   │   ├── SMARTMonitor.swift      # Disk health status
│   │   ├── SensorMonitor.swift     # CPU/GPU temps and fan speeds
│   │   ├── ProcessMonitor.swift    # Top processes by CPU/memory
│   │   ├── WeatherService.swift    # OpenWeatherMap integration
│   │   ├── AlertManager.swift      # Notifications and alert rules
│   │   ├── HistoryManager.swift    # Historical data with RingBuffer
│   │   └── [other monitors]
│   └── UI/
│       ├── MenuBarViews/
│       │   └── MenuContentView.swift # Combined menu bar label
│       ├── DropdownPanels/
│       │   ├── DetailPanelView.swift # CPU/Memory details
│       │   ├── NetworkPanelView.swift # Network metrics
│       │   ├── DiskPanelView.swift   # Disk space by volume
│       │   ├── BatteryPanelView.swift # Battery status
│       │   ├── SMARTPanelView.swift   # Disk health
│       │   ├── SensorPanelView.swift  # Temps and fans
│       │   ├── TopProcessesPanelView.swift # Top processes
│       │   ├── WeatherPanelView.swift # Weather display
│       │   └── [other panels]
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

### Quick Start

```bash
cd vigil
swift run vigil
```

The menu bar app will launch immediately.

### Release Build

```bash
cd vigil
swift build -c release
.build/release/vigil
```

### Creating a Proper macOS App Bundle

To create a distributable `.app` bundle:

```bash
#!/bin/bash
cd vigil

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

After creating the bundle:
- Double-click to launch
- Move to `/Applications/` folder
- Use `open build/Vigil.app` to run from terminal

### System Requirements

- macOS 13.0 (Ventura) or later (required for MenuBarExtra)
- Swift 5.9+

## Architecture Notes

### Performance Optimizations
- **Caching**: NetworkMonitor caches address info (5s TTL), DiskMonitor caches disk info (10s TTL)
- **Polling Frequencies**: CPU/Memory/Network/Disk/Processes updated every 1s, Sensors every 5s, Weather every 10min (with internal cache)
- **Threading**: Metrics updates on background threads, UI updates on MainActor via @Published properties
- **History Management**: RingBuffer with NSLock for thread-safe 1-hour history (3600 points)

### API Integrations
- **OpenWeatherMap**: Free tier supports 1000 calls/day (sufficient for single user with 10min cache)
- **macOS System APIs**: IOKit, mach, SystemConfiguration, DiskArbitration, UserNotifications
- **Command-line Tools**: `system_profiler`, `diskutil`, `pmset`, `ioreg`, `ps` for fallback data

### Accessibility
- SF Symbols throughout (no custom icons)
- Color-coded status with text labels for clarity
- Full keyboard navigation in preferences window
- Alert notifications with system sound

## Future Enhancements
- S.M.A.R.T. disk temperature predictions
- Custom notification sounds
- Bluetooth device battery history graphs
- Per-app network usage breakdown (requires packet analysis)
- Fan speed control with custom curves (requires elevated permissions)
- Multiple location weather support
- Localization for international users

See [SPECIFICATION.md](docs/SPECIFICATION.md) for detailed requirements and design decisions.

## Licensing

Free/open-source - MIT or Apache 2.0 (TBD)
