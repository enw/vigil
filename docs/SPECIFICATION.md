# my-istat: iStat Menus Clone Specification

## Project Overview

**Goal**: Build a macOS system monitoring application cloning iStat Menus functionality - displaying comprehensive system metrics in the menu bar with detailed dropdown panels.

**Current State**: Greenfield project - empty repository on `trunk` branch.

---

## Core Requirements

### 1. System Metrics Monitoring

#### CPU Monitoring
- Individual core usage percentages (separate efficiency/performance cores on Apple Silicon)
- CPU frequency tracking per core
- Load averages (1min, 5min, 15min)
- System uptime
- Top CPU-consuming apps ranking
- CPU temperature sensors
- Historical usage graphs

#### GPU Monitoring (Apple Silicon)
- GPU processor utilization
- GPU memory usage
- GPU temperature
- Frames-per-second counter (optional menu bar display)

#### Memory Monitoring
- Total/used/free memory
- Memory pressure indicator
- Compressed memory stats
- Swap usage (used/encrypted)
- Historical memory usage graphs
- Top memory-consuming apps

#### Disk Monitoring
- Used/free space per volume
- Real-time read/write activity
- S.M.A.R.T. status checking
- Per-app disk activity ranking
- Multi-disk support
- Historical I/O graphs

#### Network Monitoring
- Real-time upload/download bandwidth
- Bandwidth history graphs
- Per-app network usage breakdown
- Public/private IP addresses
- Wi-Fi SSID display (optional menu bar)
- Connection status indicators
- Detailed connection info (router, DNS, subnet mask)

#### Battery & Power
- Current battery percentage
- Charging status indicators
- Time remaining estimates
- Battery health information
- Bluetooth device battery levels (AirPods, Magic Mouse, Magic Trackpad, etc.)
- Power consumption metrics
- Battery cycle count

#### Sensors
- CPU/GPU temperature readings
- Hard drive temperatures
- Fan speeds (all fans)
- Voltages
- Current/power consumption
- Fan speed control with custom curves
- Temperature-based fan ramping

#### Weather (Optional)
- Location-based or manual location weather
- Current conditions
- Hourly forecasts
- 7-day and 14-day forecasts
- Temperature, wind, precipitation, humidity, pressure, UV index
- Sun/moon information

#### Date/Time
- Customizable menu bar clock formats
- Calendar integration with events
- World clocks with custom names
- Sun/moon rise/set times

---

### 2. UI/UX Architecture

#### Menu Bar Integration
- **Compact mode**: Individual menu bar items per metric
- **Combined mode**: Single icon consolidating multiple metrics
- **Stacked display**: Labels above/below values in menu bar
- Customizable display order
- Color-coded indicators (e.g., high CPU = red)
- Icon-only or icon+text modes

#### Dropdown Panels
- Detailed metric views accessible via menu bar clicks
- Historical graphs (last hour, day, week)
- Top processes lists (sortable)
- Interactive controls (fan speed adjustment, etc.)
- Quick actions (open Activity Monitor, Disk Utility, etc.)
- Smooth animations and responsive UI

#### Notifications & Alerts
- Rule-based notifications:
  - CPU threshold exceeded (e.g., ">60% for 10s")
  - Memory pressure warnings
  - Disk space low alerts
  - IP address changes
  - Network disconnection
  - Battery low/charged notifications
  - Temperature thresholds
  - Daylight saving reminders
- Customizable notification sounds
- Notification history

#### Preferences Window
- Per-module enable/disable toggles
- Menu bar item configuration
- Color theme customization
- Notification rule editor
- Update frequency settings
- Launch at login option
- Accessibility permissions setup

---

### 3. Technical Architecture

#### Tech Stack
- **Language**: Swift (native macOS)
- **UI Framework**: SwiftUI + AppKit (for menu bar integration)
- **System APIs**:
  - `IOKit` for hardware sensors
  - `SystemConfiguration` for network
  - `DiskArbitration` for disk info
  - `IOBluetooth` for Bluetooth device batteries
  - `SMC` (System Management Controller) for fan control/temps
- **Charts**: Swift Charts for historical graphs
- **Persistence**: UserDefaults for preferences, Core Data if needed for history
- **Weather API**: OpenWeatherMap free tier

#### System Requirements
- **macOS Version**: 11.0+ (Big Sur and later)
- **Architecture**: Universal Binary (Intel + Apple Silicon) - Apple Silicon primary, Intel as nice-to-have
- **Permissions Required**:
  - Location Services (for weather)
  - Accessibility (for fan control in Phase 2)
  - Full Disk Access (optional, for future S.M.A.R.T. data)

#### Project Structure
```
my-istat/
├── my-istat.xcodeproj
├── my-istat/
│   ├── App/
│   │   ├── AppDelegate.swift
│   │   └── MenuBarController.swift
│   ├── Modules/
│   │   ├── CPU/
│   │   ├── Memory/
│   │   ├── Disk/
│   │   ├── Network/
│   │   ├── Battery/
│   │   ├── Sensors/
│   │   ├── Weather/
│   │   └── DateTime/
│   ├── UI/
│   │   ├── MenuBarViews/
│   │   ├── DropdownPanels/
│   │   ├── Preferences/
│   │   └── Components/
│   ├── Services/
│   │   ├── SystemMonitor.swift
│   │   ├── SMCService.swift
│   │   ├── NotificationService.swift
│   │   └── WeatherService.swift
│   ├── Models/
│   │   └── [Data models for each metric]
│   └── Utilities/
│       └── [Helpers, extensions]
├── Tests/
└── Resources/
    ├── Assets.xcassets
    └── Info.plist
```

#### Performance Targets
- **CPU Usage**: <1% idle, <3% active monitoring
- **Memory Footprint**: <50MB
- **Update Frequency**: Configurable (1s - 10s intervals)
- **Launch Time**: <2s cold start

---

### 4. Feature Prioritization

#### Phase 1: MVP (Core Metrics)
1. Menu bar app infrastructure
2. CPU monitoring (usage, cores, temp)
3. Memory monitoring (usage, pressure)
4. Basic menu bar display
5. Simple dropdown panels with graphs
6. Preferences window (basic)

#### Phase 2: Extended Monitoring
1. Network monitoring (bandwidth, connections)
2. Disk monitoring (space, activity)
3. Battery monitoring (status, devices)
4. Notification system
5. Combined mode UI

#### Phase 3: Advanced Features
1. Sensor monitoring & fan control (read-only to start)
2. Weather integration
3. Per-app breakdowns (CPU, memory, disk, network)
4. S.M.A.R.T. status
5. Advanced theming

#### Phase 4: Polish
1. Performance optimization
2. Accessibility improvements
3. Localization
4. Auto-updates (Sparkle framework)
5. Documentation

---

### 5. Key Design Decisions

#### Data Collection Strategy
- **Polling-based**: Timer-driven updates at user-configured intervals
- **Caching**: Minimize system API calls by caching computed values
- **Background threads**: Keep main thread free for UI responsiveness

#### Menu Bar Item Management
- **Dynamic**: Items added/removed based on preferences
- **Reorderable**: Drag-to-reorder in preferences
- **State preservation**: Remember user configuration across launches

#### Graph Rendering
- **Ring buffers**: Fixed-size circular buffers for historical data
- **Smoothing**: Optional graph smoothing for noisy data
- **Persistence**: Keep last 24h in memory, older data discarded

#### Fan Control Strategy (v1)
- **Display-only**: Read fan speeds from SMC, display RPM in menu/panels
- **No write access**: No permissions/privilege escalation needed
- **Migration path**: Safe upgrade to Phase 2 manual control without API changes

---

### 6. Non-Functional Requirements

#### Privacy
- No analytics/tracking
- No network calls except weather API (OpenWeatherMap)
- No data collection
- All processing local

#### Reliability
- Graceful degradation if APIs fail
- No crashes on permission denial
- Safe fan control with fallbacks

#### Accessibility
- VoiceOver support for all UI
- Keyboard navigation
- High contrast mode support

#### Distribution & Licensing
- Free/open-source (MIT or Apache 2.0)
- Direct download (DMG)
- Notarized for Gatekeeper
- Code-signed with Developer ID
- Self-hosted auto-updates via Sparkle framework + GitHub releases

---

### 7. Design Details

#### Fan Control (v1 Approach)

**Recommendation: Display-only fan speed monitoring**

Three approaches considered:

**Option A: Display-only (SELECTED for v1)**
- Read fan speeds from System Management Controller (SMC)
- Display current RPM in menu bar and panels
- No write access = no permissions/privilege escalation needed
- Can upgrade to control later without breaking API
- ~10% effort, high user value (visibility into cooling)

**Option B: Safe write access (Phase 2+ candidate)**
- Use reverse-engineered SMC library (e.g., `SMCKit` on GitHub)
- Requires Accessibility permission (user grants in System Preferences)
- Implement predefined fan curves (normal/performance/quiet)
- Safety: Validate all values, enforce min/max speeds, reset on app crash
- ~40% effort, medium-high value

**Option C: Kernel extension (NOT recommended)**
- Maximum flexibility but requires code signing + notarization complexity
- Difficult for open-source (code review burden)
- Requires macOS System Integrity Protection (SIP) disabling by users
- Maintenance burden too high for community project

**Implementation**: Start with Option A (fan speed display). When ready for Phase 2+, migrate to Option B with user testing on multiple Mac models.

---

### 8. Resolved Decisions

| Item | Decision | Rationale |
|------|----------|-----------|
| Weather API | OpenWeatherMap free tier | 1000 calls/day sufficient, no cost |
| Licensing | MIT or Apache 2.0 open-source | Community-friendly |
| Auto-updates | Self-hosted Sparkle + GitHub releases | No external dependencies |
| S.M.A.R.T. access | Defer to Phase 3 | Too complex for v1 |
| Fan control | Display-only (v1), safe write access (Phase 2) | Simplicity + upgrade path |
| Design assets | SF Symbols only | No custom icon design needed |
| Testing focus | Apple Silicon primary | Current market focus |
| App name | "cavestat" (or TBD) | Trademark-safe |
