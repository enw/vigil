import Foundation
import Foundation
import ObjectiveC
import SwiftUI

// MARK: - CPU Metrics
struct CPUMetrics {
    let timestamp: Date
    let totalUsage: Double // 0-100
    let processorCount: Int
    let temperature: Double? // Celsius
    let loadAverage: (one: Double, five: Double, fifteen: Double)
    let uptime: TimeInterval

    var usagePercentage: String {
        String(format: "%.1f%%", totalUsage)
    }

    var formattedUptime: String {
        let hours = Int(uptime) / 3600
        let minutes = (Int(uptime) % 3600) / 60
        return String(format: "%dh %dm", hours, minutes)
    }
}

// MARK: - Memory Metrics
struct MemoryMetrics {
    let timestamp: Date
    let total: UInt64 // Bytes
    let used: UInt64
    let free: UInt64
    let active: UInt64
    let inactive: UInt64
    let wired: UInt64
    let compressed: UInt64

    var usedPercentage: Double {
        guard total > 0 else { return 0 }
        return Double(used) / Double(total) * 100
    }

    var usagePercentage: String {
        String(format: "%.1f%%", usedPercentage)
    }

    var formattedUsed: String {
        formatBytes(used)
    }

    var formattedFree: String {
        formatBytes(free)
    }

    var formattedTotal: String {
        formatBytes(total)
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1024 / 1024 / 1024
        return String(format: "%.2f GB", gb)
    }
}

// MARK: - System Metrics Collection
@MainActor
class SystemMetricsProvider: ObservableObject {
    @Published var cpuMetrics: CPUMetrics?
    @Published var memoryMetrics: MemoryMetrics?
    @Published var networkMetrics: NetworkMonitor.NetworkInfo?
    @Published var diskMetrics: DiskMonitor.DiskInfo?
    @Published var batteryMetrics: BatteryMonitor.BatteryInfo?
    @Published var smartInfos: [SMARTMonitor.SMARTInfo] = []
    @Published var sensorReadings: [SensorMonitor.SensorReading] = []
    @Published var topCPUProcesses: [ProcessMonitor.ProcessInfo] = []
    @Published var topMemoryProcesses: [ProcessMonitor.ProcessInfo] = []
    @Published var weatherInfo: WeatherService.WeatherInfo?
    @Published var isRunning = false

    private var updateTimer: Timer?
    private let smartUpdateInterval: TimeInterval = 60.0 // S.M.A.R.T. updates less frequently
    private var lastSmartUpdate: Date = Date(timeIntervalSince1970: 0)
    private let sensorUpdateInterval: TimeInterval = 5.0 // Sensor updates every 5s
    private var lastSensorUpdate: Date = Date(timeIntervalSince1970: 0)
    
    private var updateInterval: TimeInterval {
        UserDefaults.standard.double(forKey: "updateInterval") > 0 ? 
            UserDefaults.standard.double(forKey: "updateInterval") : 1.0
    }
    private let cpuMonitor = CPUMonitor()
    private let memoryMonitor = MemoryMonitor()
    private let networkMonitor = NetworkMonitor()
    private let diskMonitor = DiskMonitor()
    private let batteryMonitor = BatteryMonitor()
    private let smartMonitor = SMARTMonitor()
    private let sensorMonitor = SensorMonitor()
    private let processMonitor = ProcessMonitor()
    private let weatherService = WeatherService()
    lazy var alertManager = AlertManager()

    func start() {
        guard !isRunning else { return }
        isRunning = true

        // Update immediately
        updateMetrics()

        // Set up periodic updates using Task instead of Timer
        let updateTask = Task {
            while isRunning {
                try? await Task.sleep(nanoseconds: UInt64(updateInterval * 1_000_000_000))
                if isRunning {
                    updateMetrics()
                }
            }
        }

        // Store reference to allow cancellation later
        objc_setAssociatedObject(self, "updateTask", updateTask, .OBJC_ASSOCIATION_RETAIN)
    }

    func stop() {
        isRunning = false
        if let updateTask = objc_getAssociatedObject(self, "updateTask") as? Task<Void, Never> {
            updateTask.cancel()
        }
    }

    private func updateMetrics() {
        cpuMetrics = fetchCPUMetrics()
        memoryMetrics = fetchMemoryMetrics()
        networkMetrics = networkMonitor.getCurrentNetworkInfo()
        diskMetrics = diskMonitor.getDiskInfo()
        batteryMetrics = batteryMonitor.getBatteryInfo()
        
        // S.M.A.R.T. updates less frequently (every 60s)
        if Date().timeIntervalSince(lastSmartUpdate) >= smartUpdateInterval {
            smartInfos = smartMonitor.getSMARTInfo()
            lastSmartUpdate = Date()
        }
        
        // Sensor updates every 5s
        if Date().timeIntervalSince(lastSensorUpdate) >= sensorUpdateInterval {
            sensorReadings = sensorMonitor.getAllSensorReadings()
            lastSensorUpdate = Date()
        }
        
        // Process updates every second (same as main metrics)
        topCPUProcesses = processMonitor.getTopProcesses(by: .cpu, limit: 5)
        topMemoryProcesses = processMonitor.getTopProcesses(by: .memory, limit: 5)
        
        // Weather updates every 10 minutes (via caching in WeatherService)
        weatherInfo = weatherService.getWeatherInfo()

        // Check alerts
        if let cpu = cpuMetrics {
            alertManager.checkCPUAlert(usage: cpu.totalUsage)
        }
        if let mem = memoryMetrics {
            alertManager.checkMemoryAlert(usage: mem.usedPercentage)
        }
        if let disk = diskMetrics {
            let usagePercent = Double(disk.totalUsedBytes) / Double(disk.totalBytes) * 100
            alertManager.checkDiskAlert(usage: usagePercent)
        }
        if let battery = batteryMetrics {
            alertManager.checkBatteryAlert(percentage: battery.percentage, isCharging: battery.isCharging)
        }
    }

    private func fetchCPUMetrics() -> CPUMetrics {
        let usage = cpuMonitor.getCurrentCPUUsage()
        let loadAverage = cpuMonitor.getLoadAverage()
        let uptime = cpuMonitor.getSystemUptime()

        return CPUMetrics(
            timestamp: Date(),
            totalUsage: usage,
            processorCount: cpuMonitor.getProcessorCount(),
            temperature: cpuMonitor.getThermalInfo(),
            loadAverage: loadAverage,
            uptime: uptime
        )
    }

    private func fetchMemoryMetrics() -> MemoryMetrics {
        let memory = memoryMonitor.getCurrentMemoryUsage()

        return MemoryMetrics(
            timestamp: Date(),
            total: memory.total,
            used: memory.used,
            free: memory.free,
            active: memory.active,
            inactive: memory.inactive,
            wired: memory.wired,
            compressed: memory.compressed
        )
    }
}
