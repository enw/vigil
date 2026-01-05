import Foundation
import ObjectiveC

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
    @Published var isRunning = false

    private var updateTimer: Timer?
    private let updateInterval: TimeInterval = 1.0
    private let cpuMonitor = CPUMonitor()
    private let memoryMonitor = MemoryMonitor()

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
