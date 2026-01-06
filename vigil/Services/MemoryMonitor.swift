import Foundation

class MemoryMonitor {
    func getCurrentMemoryUsage() -> MemoryInfo {
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

        guard result == KERN_SUCCESS else {
            return MemoryInfo(total: 0, used: 0, free: 0, active: 0, inactive: 0, wired: 0, compressed: 0)
        }

        pageSize = Int(vm_page_size)
        let total = UInt64(ProcessInfo.processInfo.physicalMemory)
        let active = UInt64(vmStats.active_count) * UInt64(pageSize)
        let inactive = UInt64(vmStats.inactive_count) * UInt64(pageSize)
        let wired = UInt64(vmStats.wire_count) * UInt64(pageSize)
        let compressed = UInt64(vmStats.compressor_page_count) * UInt64(pageSize)

        let used = active + wired + compressed
        let free = UInt64(vmStats.free_count) * UInt64(pageSize)

        return MemoryInfo(
            total: total,
            used: used,
            free: free,
            active: active,
            inactive: inactive,
            wired: wired,
            compressed: compressed
        )
    }

    func getMemoryPressure() -> Double {
        let memory = getCurrentMemoryUsage()
        guard memory.total > 0 else { return 0 }
        return Double(memory.used) / Double(memory.total) * 100
    }
}

struct MemoryInfo {
    let total: UInt64
    let used: UInt64
    let free: UInt64
    let active: UInt64
    let inactive: UInt64
    let wired: UInt64
    let compressed: UInt64

    var usagePercentage: Double {
        guard total > 0 else { return 0 }
        return Double(used) / Double(total) * 100
    }

    func formatBytes(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1024 / 1024 / 1024
        return String(format: "%.2f GB", gb)
    }

    var usedFormatted: String {
        formatBytes(used)
    }

    var totalFormatted: String {
        formatBytes(total)
    }

    var freeFormatted: String {
        formatBytes(free)
    }
}
