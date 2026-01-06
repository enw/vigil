import Foundation
import IOKit

class BatteryMonitor {
    struct BatteryInfo {
        let percentage: Int
        let isCharging: Bool
        let timeRemaining: TimeInterval?
        let health: String // Good, Fair, Poor
        let cycleCount: Int
        let isBatteryPowered: Bool
    }

    struct BluetoothDevice {
        let name: String
        let batteryPercentage: Int
    }

    func getBatteryInfo() -> BatteryInfo? {
        // Use system_profiler to get battery info (more reliable than IOKit for external access)
        let task = Process()
        task.launchPath = "/usr/bin/system_profiler"
        task.arguments = ["SPPowerDataType", "-json"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
        } catch {
            return nil
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        
        guard let jsonString = String(data: data, encoding: .utf8),
              let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let batteries = (json["SPPowerDataType"] as? [[String: Any]])?.first else {
            return nil
        }
        
        let percentage = (batteries["Current capacity"] as? Int) ?? 0
        let isCharging = (batteries["Charging"] as? String)?.lowercased() == "yes"
        let health = batteries["Health Information"] as? String ?? "Good"
        let cycleCount = extractCycleCount(from: health)
        let timeRemaining: TimeInterval? = extractTimeRemaining(from: batteries)
        
        return BatteryInfo(
            percentage: percentage,
            isCharging: isCharging,
            timeRemaining: timeRemaining,
            health: health.contains("Normal") ? "Good" : "Fair",
            cycleCount: cycleCount,
            isBatteryPowered: !isCharging
        )
    }

    private func extractCycleCount(from health: String) -> Int {
        // Attempt to get cycle count from pmset
        let task = Process()
        task.launchPath = "/usr/bin/pmset"
        task.arguments = ["-g", "batt"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
        } catch {
            return 0
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        
        guard let output = String(data: data, encoding: .utf8) else { return 0 }
        
        // Look for cycle count in output - format varies by macOS version
        if let range = output.range(of: "cycle count"),
           let startIdx = output[range.lowerBound...].firstIndex(of: ":"),
           let endIdx = output[startIdx...].firstIndex(of: ",") ?? output[startIdx...].firstIndex(of: "\n") {
            let substring = output[output.index(after: startIdx)..<endIdx]
            return Int(substring.trimmingCharacters(in: .whitespaces)) ?? 0
        }
        
        return 0
    }
    
    private func extractTimeRemaining(from dict: [String: Any]) -> TimeInterval? {
        // Time until empty/full in minutes - convert to seconds
        if let timeString = dict["Time Remaining"] as? String {
            let components = timeString.split(separator: ":")
            if components.count == 2,
               let hours = Int(components[0]),
               let minutes = Int(components[1]) {
                return TimeInterval((hours * 3600) + (minutes * 60))
            }
        }
        return nil
    }

    func getBluetoothDeviceBatteries() -> [BluetoothDevice] {
        // This requires IOBluetooth framework
        // Complex to implement properly
        // Return empty for MVP
        return []
    }

    func getChargingEstimate() -> String {
        guard let battery = getBatteryInfo() else { return "Unknown" }

        if !battery.isCharging {
            if let timeRemaining = battery.timeRemaining {
                let hours = Int(timeRemaining) / 3600
                let minutes = (Int(timeRemaining) % 3600) / 60
                return "\(hours)h \(minutes)m remaining"
            }
            return "Calculating..."
        }

        // Estimate time to charge (simplified)
        let percentageRemaining = 100 - battery.percentage
        let estimatedMinutes = percentageRemaining * 2 // Very rough estimate
        let hours = estimatedMinutes / 60
        let mins = estimatedMinutes % 60

        if hours > 0 {
            return "\(hours)h \(mins)m to charge"
        }
        return "\(mins)m to charge"
    }
}
