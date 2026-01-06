import SwiftUI

struct NetworkPanelView: View {
    let networkMetrics: NetworkMonitor.NetworkInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Network")
                .font(.system(size: 13, weight: .semibold))

            VStack(alignment: .leading, spacing: 4) {
                DetailRow("Download:", value: String(format: "%.2f Mbps", networkMetrics.bandwidth.downloadMbps))
                DetailRow("Upload:", value: String(format: "%.2f Mbps", networkMetrics.bandwidth.uploadMbps))
                DetailRow("Downloaded:", value: formatBytes(networkMetrics.bandwidth.downloadBytes))
                DetailRow("Uploaded:", value: formatBytes(networkMetrics.bandwidth.uploadBytes))

                Divider()
                    .padding(.vertical, 4)

                if let privateIP = networkMetrics.addresses.privateIP {
                    DetailRow("Local IP:", value: privateIP)
                }
                if let publicIP = networkMetrics.addresses.publicIP {
                    DetailRow("Public IP:", value: publicIP)
                }
                if let gateway = networkMetrics.addresses.gateway {
                    DetailRow("Gateway:", value: gateway)
                }

                if !networkMetrics.addresses.dns.isEmpty {
                    DetailRow("DNS Servers:", value: networkMetrics.addresses.dns.joined(separator: ", "))
                }
            }
            .font(.system(size: 10, weight: .regular))
        }
        .padding()
        .background(Color(red: 0.95, green: 0.95, blue: 0.95))
        .cornerRadius(6)
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.2f KB", Double(bytes) / 1024)
        } else if bytes < 1024 * 1024 * 1024 {
            return String(format: "%.2f MB", Double(bytes) / 1024 / 1024)
        } else {
            return String(format: "%.2f GB", Double(bytes) / 1024 / 1024 / 1024)
        }
    }
}
