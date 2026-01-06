import Foundation
import IOKit

class CPUMonitor {
    private var previousInfo: host_cpu_load_info?

    func getCurrentCPUUsage() -> Double {
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        var info = host_cpu_load_info()

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                host_statistics(
                    mach_host_self(),
                    HOST_CPU_LOAD_INFO,
                    $0,
                    &count
                )
            }
        }

        guard result == KERN_SUCCESS else { 
            print("Vigil: CPU stats failed with result: \(result)")
            return 0 
        }

        let userDiff = Double(info.cpu_ticks.0 - (previousInfo?.cpu_ticks.0 ?? 0))
        let sysDiff = Double(info.cpu_ticks.1 - (previousInfo?.cpu_ticks.1 ?? 0))
        let idleDiff = Double(info.cpu_ticks.2 - (previousInfo?.cpu_ticks.2 ?? 0))
        let niceDiff = Double(info.cpu_ticks.3 - (previousInfo?.cpu_ticks.3 ?? 0))

        let totalDiff = userDiff + sysDiff + idleDiff + niceDiff
        guard totalDiff > 0 else {
            previousInfo = info
            return 0
        }

        let usage = ((userDiff + sysDiff) / totalDiff) * 100
        print("Vigil: CPU usage calculated: \(usage)% (user: \(userDiff), sys: \(sysDiff), idle: \(idleDiff))")

        previousInfo = info
        return max(0, min(100, usage))
    }

    func getProcessorCount() -> Int {
        ProcessInfo.processInfo.processorCount
    }

    func getLoadAverage() -> (one: Double, five: Double, fifteen: Double) {
        var loadavg: [Double] = [0, 0, 0]
        getloadavg(&loadavg, 3)
        return (loadavg[0], loadavg[1], loadavg[2])
    }

    func getSystemUptime() -> TimeInterval {
        var bootTime = timeval()
        var bootTimeSize = MemoryLayout<timeval>.size
        let result = sysctlbyname("kern.boottime", &bootTime, &bootTimeSize, nil, 0)

        guard result == 0 else { return 0 }

        let bootTimeInterval = TimeInterval(bootTime.tv_sec) + TimeInterval(bootTime.tv_usec) / 1_000_000
        return Date().timeIntervalSince1970 - bootTimeInterval
    }

    func getThermalInfo() -> Double? {
        // Basic temperature reading - expand with IOKit for detailed sensor data
        nil
    }
}
