import Foundation
import SystemConfiguration

class NetworkMonitor {
    private var previousStats: [String: NetworkStats] = [:]
    private var cachedNetworkInfo: NetworkInfo?
    private var lastAddressUpdate: Date = Date()
    private let addressCacheTTL: TimeInterval = 5.0 // Cache address info for 5 seconds

    struct NetworkStats {
        let bytesIn: UInt64
        let bytesOut: UInt64
        let timestamp: Date
    }

    struct NetworkInfo {
        let bandwidth: BandwidthStats
        let addresses: AddressInfo
    }

    struct BandwidthStats {
        let downloadMbps: Double
        let uploadMbps: Double
        let downloadBytes: UInt64
        let uploadBytes: UInt64
    }

    struct AddressInfo {
        let publicIP: String?
        let privateIP: String?
        let gateway: String?
        let dns: [String]
    }

    func getCurrentNetworkInfo() -> NetworkInfo {
        let bandwidth = getBandwidth()
        
        // Cache address info to reduce system calls
        let addresses: AddressInfo
        if Date().timeIntervalSince(lastAddressUpdate) >= addressCacheTTL {
            addresses = getAddresses()
            lastAddressUpdate = Date()
        } else if let cached = cachedNetworkInfo {
            addresses = cached.addresses
        } else {
            addresses = getAddresses()
            lastAddressUpdate = Date()
        }
        
        return NetworkInfo(bandwidth: bandwidth, addresses: addresses)
    }

    private func getBandwidth() -> BandwidthStats {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else {
            return BandwidthStats(downloadMbps: 0, uploadMbps: 0, downloadBytes: 0, uploadBytes: 0)
        }
        defer { freeifaddrs(ifaddr) }

        var totalBytesIn: UInt64 = 0
        var totalBytesOut: UInt64 = 0

        var ptr = ifaddr
        while let address = ptr {
            defer { ptr = address.pointee.ifa_next }

            let name = String(cString: address.pointee.ifa_name)
            guard name != "lo0" else { continue } // Skip loopback

            guard let data = address.pointee.ifa_data else { continue }

            let stats = data.withMemoryRebound(to: if_data.self, capacity: 1) { $0.pointee }
            totalBytesIn += UInt64(stats.ifi_ibytes)
            totalBytesOut += UInt64(stats.ifi_obytes)
        }

        // Calculate Mbps based on previous stats
        let downloadMbps = calculateMbps(totalBytesIn)
        let uploadMbps = calculateMbps(totalBytesOut)

        return BandwidthStats(
            downloadMbps: downloadMbps,
            uploadMbps: uploadMbps,
            downloadBytes: totalBytesIn,
            uploadBytes: totalBytesOut
        )
    }

    private func calculateMbps(_ bytes: UInt64) -> Double {
        // Simplified - would need timestamp tracking for accurate Mbps
        // For now, return 0 as we need more context
        return 0.0
    }

    private func getAddresses() -> AddressInfo {
        var privateIP: String?
        var gateway: String?
        var dnsServers: [String] = []

        // Get local IP
        if let localIP = getLocalIP() {
            privateIP = localIP
        }

        // Get gateway
        if let gw = getDefaultGateway() {
            gateway = gw
        }

        // Get DNS servers
        dnsServers = getDNSServers()

        // Public IP would require network call - skip for now
        // In production, use an external service like ipify API

        return AddressInfo(
            publicIP: nil,
            privateIP: privateIP,
            gateway: gateway,
            dns: dnsServers
        )
    }

    private func getLocalIP() -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        defer { freeifaddrs(ifaddr) }

        var ptr = ifaddr
        while let address = ptr {
            defer { ptr = address.pointee.ifa_next }

            let family = address.pointee.ifa_addr.pointee.sa_family
            guard family == sa_family_t(AF_INET) else { continue }

            let name = String(cString: address.pointee.ifa_name)
            guard name.hasPrefix("en") else { continue } // en0, en1, etc.

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            guard getnameinfo(
                address.pointee.ifa_addr,
                socklen_t(address.pointee.ifa_addr.pointee.sa_len),
                &hostname,
                socklen_t(hostname.count),
                nil,
                0,
                NI_NUMERICHOST
            ) == 0 else { continue }

            return String(cString: hostname)
        }

        return nil
    }

    private func getDefaultGateway() -> String? {
        // Requires routing table access - complex on macOS
        // Skip for MVP
        return nil
    }

    private func getDNSServers() -> [String] {
        // DNS resolver APIs (res_ninit, res_nclose) are not available in Swift's Darwin overlay
        // For MVP, return common default DNS servers
        // TODO: Consider using SystemConfiguration framework to query system DNS settings
        return ["8.8.8.8", "8.8.4.4"]
    }

    func getActiveConnections() -> [ConnectionInfo] {
        // This requires parsing netstat or using sysctl
        // Complex - skip for MVP, plan for Phase 3
        return []
    }
}

struct ConnectionInfo {
    let sourceIP: String
    let destIP: String
    let sourcePort: UInt16
    let destPort: UInt16
    let protocol_: String
    let state: String
}
