import Foundation

class ProcessMonitor {
    struct ProcessInfo: Identifiable {
        let id = UUID()
        let pid: Int32
        let name: String
        let cpuUsage: Double // percentage
        let memoryUsage: UInt64 // bytes
        let icon: String? // would need app lookup
    }
    
    func getTopProcesses(by type: ProcessSortType, limit: Int = 5) -> [ProcessInfo] {
        let processes = getAllProcesses()
        
        switch type {
        case .cpu:
            return Array(processes.sorted { $0.cpuUsage > $1.cpuUsage }.prefix(limit))
        case .memory:
            return Array(processes.sorted { $0.memoryUsage > $1.memoryUsage }.prefix(limit))
        }
    }
    
    enum ProcessSortType {
        case cpu
        case memory
    }
    
    private func getAllProcesses() -> [ProcessInfo] {
        var processes: [ProcessInfo] = []
        
        // Use ps command to get process info
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["aux"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
        } catch {
            return processes
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        
        guard let output = String(data: data, encoding: .utf8) else {
            return processes
        }
        
        let lines = output.split(separator: "\n")
        for line in lines.dropFirst() { // Skip header
            let columns = line.split(separator: " ", omittingEmptySubsequences: true)
            
            guard columns.count >= 11 else { continue }
            
            guard let cpuPercent = Double(columns[2]) else { continue }
            guard let memPercent = Double(columns[3]) else { continue }
            guard let pid = Int32(columns[1]) else { continue }
            
            // Skip system processes with 0% usage
            if cpuPercent < 0.01 && memPercent < 0.01 {
                continue
            }
            
            let commandPath = String(columns[10])
            let processName = URL(fileURLWithPath: commandPath).lastPathComponent
            
            // Convert memory percentage to bytes (rough estimate)
            let memoryBytes = UInt64(memPercent * 10_485_760) // ~10MB per 1% on typical system
            
            processes.append(ProcessInfo(
                pid: pid,
                name: processName,
                cpuUsage: cpuPercent,
                memoryUsage: memoryBytes,
                icon: nil
            ))
        }
        
        return processes
    }
    
    // Get total CPU usage by summing top processes
    func getTotalCPUByTopProcesses() -> Double {
        let processes = getTopProcesses(by: .cpu, limit: 10)
        return processes.reduce(0) { $0 + $1.cpuUsage }
    }
    
    // Get total memory by summing top processes
    func getTotalMemoryByTopProcesses() -> UInt64 {
        let processes = getTopProcesses(by: .memory, limit: 10)
        return processes.reduce(0) { $0 + $1.memoryUsage }
    }
}
