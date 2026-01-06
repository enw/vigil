import Foundation

class SensorMonitor {
    struct SensorReading {
        let name: String
        let value: Double
        let unit: String
        let type: SensorType
        
        enum SensorType {
            case cpuTemp
            case gpuTemp
            case fanSpeed
            case other
        }
    }
    
    func getTemperatures() -> [SensorReading] {
        var readings: [SensorReading] = []
        
        // Try to get temps via system_profiler (most reliable without special permissions)
        let task = Process()
        task.launchPath = "/usr/sbin/system_profiler"
        task.arguments = ["SPHardwareDataType"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
        } catch {
            return readings
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        
        guard let output = String(data: data, encoding: .utf8) else {
            return readings
        }
        
        // Parse output for temperature info
        let lines = output.split(separator: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Look for temperature entries
            if trimmed.contains("Temperature") || trimmed.contains("°C") {
                if let temp = parseTemperatureLine(String(trimmed)) {
                    readings.append(temp)
                }
            }
        }
        
        // If system_profiler didn't give us temps, try pmset
        if readings.isEmpty {
            readings.append(contentsOf: getTemperaturesViaPmset())
        }
        
        return readings
    }
    
    private func parseTemperatureLine(_ line: String) -> SensorReading? {
        // Parse lines like "CPU Temperature: 65°C" or "Temperature: 58 °C"
        let components = line.split(separator: ":")
        guard components.count >= 2 else { return nil }
        
        let valueStr = String(components.last ?? "").trimmingCharacters(in: .whitespaces)
        
        // Extract numeric value
        let digits = valueStr.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard let value = Double(digits) else { return nil }
        
        let name: String
        if line.lowercased().contains("gpu") {
            name = "GPU Temperature"
        } else {
            name = "CPU Temperature"
        }
        
        return SensorReading(
            name: name,
            value: value,
            unit: "°C",
            type: line.lowercased().contains("gpu") ? .gpuTemp : .cpuTemp
        )
    }
    
    private func getTemperaturesViaPmset() -> [SensorReading] {
        var readings: [SensorReading] = []
        
        let task = Process()
        task.launchPath = "/usr/bin/pmset"
        task.arguments = ["-g", "thermlog"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
        } catch {
            return readings
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        
        guard let output = String(data: data, encoding: .utf8) else {
            return readings
        }
        
        // Parse pmset output for temperature readings
        let lines = output.split(separator: "\n")
        for line in lines {
            if let temp = parseTemperatureLine(String(line)) {
                readings.append(temp)
            }
        }
        
        return readings
    }
    
    func getFanSpeeds() -> [SensorReading] {
        var readings: [SensorReading] = []
        
        // Fan speeds are harder to get without special tools
        // Try ioreg which is usually available
        let task = Process()
        task.launchPath = "/usr/sbin/ioreg"
        task.arguments = ["-l", "-w", "0"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
        } catch {
            return readings
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        
        guard let output = String(data: data, encoding: .utf8) else {
            return readings
        }
        
        // Parse ioreg output for fan entries
        let lines = output.split(separator: "\n")
        var currentFan = ""
        
        for line in lines {
            let trimmed = String(line).trimmingCharacters(in: .whitespaces)
            
            // Look for fan entries
            if trimmed.lowercased().contains("\"Fan\"") || trimmed.lowercased().contains("fan") {
                currentFan = trimmed
            }
            
            // Look for RPM values associated with fans
            if trimmed.contains("RPM") || trimmed.contains("rpm") {
                if let rpm = extractRPMValue(trimmed) {
                    let fanName = extractFanName(currentFan).isEmpty ? "Fan" : extractFanName(currentFan)
                    readings.append(SensorReading(
                        name: fanName,
                        value: Double(rpm),
                        unit: "RPM",
                        type: .fanSpeed
                    ))
                }
            }
        }
        
        return readings
    }
    
    private func extractRPMValue(_ line: String) -> Int? {
        let components = line.split(separator: "=")
        if let lastPart = components.last {
            let cleanedValue = String(lastPart)
                .trimmingCharacters(in: .whitespaces)
                .components(separatedBy: CharacterSet.decimalDigits.inverted)
                .joined()
            return Int(cleanedValue)
        }
        return nil
    }
    
    private func extractFanName(_ line: String) -> String {
        if line.contains("CPU") { return "CPU Fan" }
        if line.contains("System") { return "System Fan" }
        if line.contains("GPU") { return "GPU Fan" }
        return "Fan"
    }
    
    // Get all sensor readings (temps + fans)
    func getAllSensorReadings() -> [SensorReading] {
        var all = getTemperatures()
        all.append(contentsOf: getFanSpeeds())
        return all
    }
    
    // Get brief status for menu bar (hottest component)
    func getMaxTemperature() -> String {
        let temps = getTemperatures()
        guard let maxTemp = temps.max(by: { $0.value < $1.value }) else {
            return "--"
        }
        return String(format: "%.0f°C", maxTemp.value)
    }
}
