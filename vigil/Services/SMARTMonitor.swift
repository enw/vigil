import Foundation

class SMARTMonitor {
    struct SMARTInfo {
        let diskId: String
        let name: String
        let status: HealthStatus
        let temperature: Int? // Celsius
        let powerOnHours: Int?
        let powerCycles: Int?
        let sectorErrors: Int?
        
        enum HealthStatus: String {
            case healthy = "Healthy"
            case warning = "Warning"
            case critical = "Critical"
            case unknown = "Unknown"
        }
    }
    
    func getSMARTInfo() -> [SMARTInfo] {
        var smartInfos: [SMARTInfo] = []
        
        // Get list of physical disks
        let task = Process()
        task.launchPath = "/usr/sbin/diskutil"
        task.arguments = ["list", "-plist"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
        } catch {
            return []
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        
        guard let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let disks = plist["AllDisksAndPartitions"] as? [[String: Any]] else {
            return []
        }
        
        for diskDict in disks {
            guard let diskId = diskDict["DeviceIdentifier"] as? String else { continue }
            
            // Query S.M.A.R.T. status for this disk
            if let smartInfo = querySMARTStatus(for: diskId) {
                smartInfos.append(smartInfo)
            }
        }
        
        return smartInfos
    }
    
    private func querySMARTStatus(for diskId: String) -> SMARTInfo? {
        let task = Process()
        task.launchPath = "/usr/sbin/diskutil"
        task.arguments = ["info", "-plist", diskId]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
        } catch {
            return nil
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        
        guard let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            return nil
        }
        
        let name = (plist["MediaName"] as? String) ?? diskId
        
        // Parse S.M.A.R.T. status
        var status = SMARTInfo.HealthStatus.unknown
        if let smartStatus = plist["SMARTStatus"] as? String {
            if smartStatus.lowercased().contains("verified") {
                status = .healthy
            } else if smartStatus.lowercased().contains("failing") || smartStatus.lowercased().contains("bad") {
                status = .critical
            } else if smartStatus.lowercased().contains("warning") {
                status = .warning
            }
        }
        
        return SMARTInfo(
            diskId: diskId,
            name: name,
            status: status,
            temperature: nil, // Would require additional API access
            powerOnHours: nil,
            powerCycles: nil,
            sectorErrors: nil
        )
    }
    
    // Simplified health check - returns true if all disks are healthy
    func getAllDisksHealthy() -> Bool {
        let infos = getSMARTInfo()
        return infos.allSatisfy { $0.status == .healthy }
    }
    
    // Get status indicator for menu bar
    func getHealthStatus() -> String {
        let infos = getSMARTInfo()
        
        if infos.isEmpty {
            return "--"
        }
        
        if infos.allSatisfy({ $0.status == .healthy }) {
            return "✓"
        } else if infos.contains(where: { $0.status == .critical }) {
            return "⚠"
        } else {
            return "!"
        }
    }
}
