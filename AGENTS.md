# Vigil Agent Guidelines

## Project Overview
Vigil is a macOS system monitoring menubar app built with Swift and SwiftUI. Uses Swift Package Manager, targets macOS 13.0+, and prioritizes privacy with local-only processing.

## Build & Development Commands

```bash
# Build and run (development)
swift run vigil

# Build release binary  
swift build -c release

# Create .app bundle (manual process, see BUILD.md)
# No automated test framework configured yet
```

## Code Structure & Organization

```
vigil/
├── App/           # App entry point
├── Models/        # Data structures (SystemMetrics.swift)
├── Services/      # System monitoring classes
└── UI/            # SwiftUI views and components
    ├── Components/     # Reusable UI elements
    ├── DropdownPanels/ # Detail panel views
    ├── MenuBarViews/   # Main menubar interface
    └── Preferences/    # Settings window
```

## Swift Conventions

### Naming
- **Classes**: PascalCase (CPUMonitor, AlertManager)
- **Structs**: PascalCase (CPUMetrics, MemoryInfo) 
- **Methods/Properties**: camelCase (getCurrentCPUUsage(), totalUsage)
- **Files**: PascalCase matching primary type

### Imports
```swift
import Foundation
import IOKit  // Framework-specific imports follow Foundation
```

### Access Control
- Default `internal` for most APIs
- `private` for implementation details
- `@MainActor` for UI components

## SwiftUI Guidelines

### State Management
```swift
@StateObject private var monitor = CPUMonitor()
@Published var metrics: CPUMetrics
```

### View Composition
- Small, focused View structs
- Use SF Symbols: `systemImage: "cpu"`
- MARK comments for organization: `// MARK: - CPU Metrics`

## System API Patterns

### Error Handling
```swift
let result = withUnsafeMutablePointer(to: &info) { ... }
guard result == KERN_SUCCESS else { return 0 }
```

### Performance
- Cache with TTL: NetworkMonitor (5s), DiskMonitor (10s)
- Background threads for data collection
- Update frequencies: 1s main, 5s sensors, 60s S.M.A.R.T.

## Type Conventions
- `Double` for percentages
- `UInt64` for bytes/memory sizes  
- `Int` for counts
- Nil coalescing for safe defaults: `return value ?? 0`

## Code Style

### Formatting
- 4-space indentation (project default)
- No trailing whitespace
- Line length ~100 characters (implied)

### Documentation
- MARK comments for section organization
- No copyright headers
- Minimal inline comments

## Privacy & Security
- All processing local, no network calls except weather API
- No analytics or telemetry
- Handle system permissions gracefully
- Never log sensitive system information

## macOS Specifics
- Target macOS 13.0+ for MenuBarExtra
- Use IOKit, SystemConfiguration, DiskArbitration frameworks
- Handle Universal Binary (Apple Silicon primary, Intel secondary)
- Follow Apple Human Interface Guidelines for menubar apps

## Testing (When Added)
- Use XCTest framework
- Test system monitors with mock data
- Focus on edge cases and error conditions
- UI tests for critical user flows

## Commit Message Format
```
[type]: description
```
Types: `fix:`, `refactor:`, `docs:`, feature descriptions
Keep concise, action-focused, no fluff.

## Development Workflow
1. Read existing code before editing to understand patterns
2. Follow established naming and structure conventions
3. Test system monitoring changes under various load conditions
4. Verify UI updates reflect at appropriate refresh rates
5. Check privacy implications of any new system data access