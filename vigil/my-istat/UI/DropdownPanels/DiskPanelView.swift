import SwiftUI

struct DiskPanelView: View {
    let diskMetrics: DiskMonitor.DiskInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Disk")
                .font(.system(size: 13, weight: .semibold))

            // Overall usage
            VStack(alignment: .leading, spacing: 4) {
                DetailRow("Used:", value: formatBytes(diskMetrics.totalUsedBytes))
                DetailRow("Total:", value: formatBytes(diskMetrics.totalBytes))
                let percentage = Double(diskMetrics.totalUsedBytes) / Double(diskMetrics.totalBytes) * 100
                DetailRow("Usage:", value: String(format: "%.1f%%", percentage))
            }
            .font(.system(size: 10, weight: .regular))

            Divider()
                .padding(.vertical, 4)

            // Per-volume breakdown
            VStack(alignment: .leading, spacing: 8) {
                ForEach(diskMetrics.volumes, id: \.name) { volume in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(volume.name)
                            .font(.system(size: 10, weight: .semibold))
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(volume.formattedUsed) / \(volume.formattedTotal)")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f%%", volume.usagePercentage))
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            Spacer()
                            // Simple progress bar
                            RoundedRectangle(cornerRadius: 2)
                                .fill(progressColor(volume.usagePercentage))
                                .frame(width: 100, height: 6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(progressColor(volume.usagePercentage).opacity(0.3))
                                        .frame(width: 100 * CGFloat(volume.usagePercentage) / 100, height: 6, alignment: .leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                )
                        }
                    }
                    .padding(6)
                    .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                    .cornerRadius(4)
                }
            }
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

    private func progressColor(_ percentage: Double) -> Color {
        if percentage > 90 {
            return .red
        } else if percentage > 75 {
            return .orange
        } else if percentage > 50 {
            return .yellow
        }
        return .green
    }
}
