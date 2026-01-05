import Foundation

class DiskMonitor {
    private var cachedDiskInfo: DiskInfo?
    private var lastDiskUpdate: Date = Date()
    private let diskCacheTTL: TimeInterval = 10.0 // Cache disk info for 10 seconds
    struct DiskInfo {
        let volumes: [VolumeInfo]
        let totalUsedBytes: UInt64
        let totalBytes: UInt64
    }

    struct VolumeInfo {
        let name: String
        let mountPoint: String
        let totalBytes: UInt64
        let usedBytes: UInt64
        let freeBytes: UInt64

        var usagePercentage: Double {
            guard totalBytes > 0 else { return 0 }
            return Double(usedBytes) / Double(totalBytes) * 100
        }

        var formattedTotal: String {
            formatBytes(totalBytes)
        }

        var formattedUsed: String {
            formatBytes(usedBytes)
        }

        var formattedFree: String {
            formatBytes(freeBytes)
        }

        private func formatBytes(_ bytes: UInt64) -> String {
            let gb = Double(bytes) / 1024 / 1024 / 1024
            return String(format: "%.2f GB", gb)
        }
    }

    func getDiskInfo() -> DiskInfo {
        // Cache disk info to reduce filesystem calls
        if let cached = cachedDiskInfo,
           Date().timeIntervalSince(lastDiskUpdate) < diskCacheTTL {
            return cached
        }
        
        let volumes = getDiskVolumes()

        var totalUsed: UInt64 = 0
        var totalSize: UInt64 = 0

        for volume in volumes {
            totalUsed += volume.usedBytes
            totalSize += volume.totalBytes
        }

        let diskInfo = DiskInfo(
            volumes: volumes,
            totalUsedBytes: totalUsed,
            totalBytes: totalSize
        )
        
        cachedDiskInfo = diskInfo
        lastDiskUpdate = Date()
        
        return diskInfo
    }

    private func getDiskVolumes() -> [VolumeInfo] {
        let fileManager = FileManager.default
        var volumes: [VolumeInfo] = []

        guard let mountedVolumes = try? fileManager.contentsOfDirectory(atPath: "/Volumes") else {
            // Fallback to system volume
            if let resources = getVolumeResourceValues(for: "/") {
                let vol = VolumeInfo(
                    name: "Macintosh HD",
                    mountPoint: "/",
                    totalBytes: resources.totalBytes,
                    usedBytes: resources.totalBytes - resources.freeBytes,
                    freeBytes: resources.freeBytes
                )
                volumes.append(vol)
            }
            return volumes
        }

        // Check each mounted volume
        for volumeName in mountedVolumes {
            let path = "/Volumes/\(volumeName)"
            guard fileManager.fileExists(atPath: path) else { continue }

            if let resources = getVolumeResourceValues(for: path) {
                let vol = VolumeInfo(
                    name: volumeName,
                    mountPoint: path,
                    totalBytes: resources.totalBytes,
                    usedBytes: resources.totalBytes - resources.freeBytes,
                    freeBytes: resources.freeBytes
                )
                volumes.append(vol)
            }
        }

        // Add system volume if not already there
        if !volumes.contains(where: { $0.mountPoint == "/" }) {
            if let resources = getVolumeResourceValues(for: "/") {
                let vol = VolumeInfo(
                    name: "System",
                    mountPoint: "/",
                    totalBytes: resources.totalBytes,
                    usedBytes: resources.totalBytes - resources.freeBytes,
                    freeBytes: resources.freeBytes
                )
                volumes.append(vol)
            }
        }

        return volumes.sorted { $0.name < $1.name }
    }

    private func getVolumeResourceValues(for path: String) -> (totalBytes: UInt64, freeBytes: UInt64)? {
        let fileManager = FileManager.default

        guard let values = try? fileManager.attributesOfFileSystem(forPath: path) else {
            return nil
        }

        let total = (values[FileAttributeKey.systemSize] as? NSNumber)?.uint64Value ?? 0
        let free = (values[FileAttributeKey.systemFreeSize] as? NSNumber)?.uint64Value ?? 0

        return (totalBytes: total, freeBytes: free)
    }

    func getDiskActivity() -> DiskActivityStats {
        // This requires reading I/O statistics from /proc or sysctl
        // On macOS, this is complex - requires system calls
        // Simplified version returns zeros
        return DiskActivityStats(readBytesPerSec: 0, writeBytesPerSec: 0)
    }
}

struct DiskActivityStats {
    let readBytesPerSec: UInt64
    let writeBytesPerSec: UInt64

    var readMBps: Double {
        Double(readBytesPerSec) / 1024 / 1024
    }

    var writeMBps: Double {
        Double(writeBytesPerSec) / 1024 / 1024
    }
}
