import Foundation

// MARK: - CPU Metrics
struct CPUMetrics: Codable {
    let timestamp: Date
    let totalUsage: Double // 0-100
    let coreUsages: [Double] // Per-core usage percentages
    let frequency: [Double] // Per-core frequencies in GHz
    let temperature: Double? // Celsius
    let loadAverage: (one: Double, five: Double, fifteen: Double)
    let uptime: TimeInterval

    var usagePercentage: String {
        String(format: "%.1f%%", totalUsage)
    }
}

// MARK: - Memory Metrics
struct MemoryMetrics: Codable {
    let timestamp: Date
    let total: UInt64 // Bytes
    let used: UInt64
    let free: UInt64
    let compressed: UInt64
    let swapUsed: UInt64
    let swapTotal: UInt64
    let memoryPressure: Double // 0-100

    var usedPercentage: Double {
        Double(used) / Double(total) * 100
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
    private let updateInterval: TimeInterval = 1.0 // Update every second

    func start() {
        guard !isRunning else { return }
        isRunning = true

        // Update immediately
        updateMetrics()

        // Set up periodic updates
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }
    }

    func stop() {
        updateTimer?.invalidate()
        updateTimer = nil
        isRunning = false
    }

    private func updateMetrics() {
        cpuMetrics = fetchCPUMetrics()
        memoryMetrics = fetchMemoryMetrics()
    }

    private func fetchCPUMetrics() -> CPUMetrics? {
        // TODO: Implement using IOKit
        let processor_count = ProcessInfo.processInfo.processorCount
        let loadAverage = getLoadAverage()
        let uptime = getSystemUptime()

        return CPUMetrics(
            timestamp: Date(),
            totalUsage: Double.random(in: 10...50), // Placeholder
            coreUsages: (0..<processor_count).map { _ in Double.random(in: 0...100) },
            frequency: (0..<processor_count).map { _ in Double.random(in: 2.0...3.5) },
            temperature: Double.random(in: 40...70),
            loadAverage: loadAverage,
            uptime: uptime
        )
    }

    private func fetchMemoryMetrics() -> MemoryMetrics? {
        var pageSize: Int = 0
        var vmStats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                host_statistics64(
                    mach_host_self(),
                    HOST_VM_INFO64,
                    $0,
                    &count
                )
            }
        }

        guard result == KERN_SUCCESS else { return nil }

        pageSize = Int(vm_page_size)
        let total = UInt64(ProcessInfo.processInfo.physicalMemory)
        let used = UInt64(vmStats.active_count + vmStats.wire_count) * UInt64(pageSize)
        let free = UInt64(vmStats.free_count) * UInt64(pageSize)
        let compressed = UInt64(vmStats.compressed_count) * UInt64(pageSize)

        var swapUsed: UInt64 = 0
        var swapTotal: UInt64 = 0
        // TODO: Implement swap detection

        let pressure = (Double(used) / Double(total)) * 100

        return MemoryMetrics(
            timestamp: Date(),
            total: total,
            used: used,
            free: free,
            compressed: compressed,
            swapUsed: swapUsed,
            swapTotal: swapTotal,
            memoryPressure: pressure
        )
    }

    private func getLoadAverage() -> (one: Double, five: Double, fifteen: Double) {
        var loadavg: [Double] = [0, 0, 0]
        getloadavg(&loadavg, 3)
        return (loadavg[0], loadavg[1], loadavg[2])
    }

    private func getSystemUptime() -> TimeInterval {
        var bootTime = timeval()
        var bootTimeSize = MemoryLayout<timeval>.size
        let result = sysctlbyname("kern.boottime", &bootTime, &bootTimeSize, nil, 0)

        guard result == 0 else { return 0 }

        let bootTimeInterval = TimeInterval(bootTime.tv_sec) + TimeInterval(bootTime.tv_usec) / 1_000_000
        return Date().timeIntervalSince1970 - bootTimeInterval
    }
}
