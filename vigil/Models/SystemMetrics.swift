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

    var usedPercentage: Int {
        guard total > 0 else { return 0 }
        return Int(Double(used) / Double(total) * 100)
    }

    var usagePercentage: String {
        String(format: "%d%%", usedPercentage)
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
    
    private var _updateInterval: TimeInterval = 1.0
    
    private var updateInterval: TimeInterval {
        let value = UserDefaults.standard.double(forKey: "updateInterval")
        return value > 0 ? value : 1.0
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
        
        // Start observing preference changes for update interval
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            let newInterval = self.updateInterval
            if newInterval != self._updateInterval {
                self._updateInterval = newInterval
                self.restartTimer()
            }
        }
    }

    private func restartTimer() {
        stop()
        start()
    }
    
    func stop() {
        isRunning = false
        if let updateTask = objc_getAssociatedObject(self, "updateTask") as? Task<Void, Never> {
            updateTask.cancel()
        }
    }

    func updateMetrics() {
        print("Vigil: updateMetrics called - using dummy data")
        // Use dummy data to test UI without system calls
        let cpu = CPUMetrics(
            timestamp: Date(),
            totalUsage: Double.random(in: 10...30),
            processorCount: 8,
            temperature: 45.0,
            loadAverage: (1.2, 1.5, 1.8),
            uptime: 3600.0
        )
        let mem = MemoryMetrics(
            timestamp: Date(),
            total: 16000000000,
            used: UInt64.random(in: 6000000000...10000000000),
            free: 8000000000,
            active: 4000000000,
            inactive: 2000000000,
            wired: 1000000000,
            compressed: 500000000
        )
        
        print("Vigil: Setting cpuMetrics to \(cpu.totalUsage)%")
        print("Vigil: Setting memoryMetrics to \(mem.usedPercentage)%")
        
        cpuMetrics = cpu
        memoryMetrics = mem
        // Temporarily disable all system monitoring calls
        // networkMetrics = networkMonitor.getCurrentNetworkInfo()
        // diskMetrics = diskMonitor.getDiskInfo()
        // batteryMetrics = batteryMonitor.getBatteryInfo()
        // smartInfos = []
        // sensorReadings = []
        // topCPUProcesses = []
        // topMemoryProcesses = []
        // weatherInfo = nil
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
