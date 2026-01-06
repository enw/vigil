import SwiftUI

struct MenuContentView: View {
    @ObservedObject var metricsProvider: SystemMetricsProvider
    @State private var showDetailView = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // CPU Section
            if let cpu = metricsProvider.cpuMetrics {
                MetricSectionView(
                    title: "CPU",
                    value: cpu.usagePercentage,
                    details: [
                        "Cores: \(cpu.processorCount)",
                        "Load: \(String(format: "%.2f", cpu.loadAverage.one))",
                        "Uptime: \(cpu.formattedUptime)"
                    ]
                )
            }

            // Memory Section
            if let memory = metricsProvider.memoryMetrics {
                MetricSectionView(
                    title: "Memory",
                    value: memory.usagePercentage,
                    details: [
                        "Used: \(memory.formattedUsed)",
                        "Total: \(memory.formattedTotal)",
                        "Free: \(memory.formattedFree)"
                    ]
                )
            }

            // Network Section
            if let network = metricsProvider.networkMetrics {
                MetricSectionView(
                    title: "Network",
                    value: String(format: "%.1f Mbps", network.bandwidth.downloadMbps),
                    details: [
                        "Down: \(String(format: "%.2f", network.bandwidth.downloadMbps)) Mbps",
                        "Up: \(String(format: "%.2f", network.bandwidth.uploadMbps)) Mbps",
                        network.addresses.privateIP ?? "No IP"
                    ]
                )
            }

            // Disk Section
            if let disk = metricsProvider.diskMetrics {
                let percentage = (Double(disk.totalUsedBytes) / Double(disk.totalBytes) * 100)
                MetricSectionView(
                    title: "Disk",
                    value: String(format: "%.1f%%", percentage),
                    details: [
                        formatBytes(disk.totalUsedBytes) + " used",
                        formatBytes(disk.totalBytes - disk.totalUsedBytes) + " free",
                        "\(disk.volumes.count) volume\(disk.volumes.count == 1 ? "" : "s")"
                    ]
                )
            }

            // Battery Section
            if let battery = metricsProvider.batteryMetrics {
                MetricSectionView(
                    title: "Battery",
                    value: "\(battery.percentage)%",
                    details: [
                        battery.isCharging ? "Charging" : "On Battery",
                        "Health: \(battery.health)",
                        "Cycles: \(battery.cycleCount)"
                    ]
                )
            }

            // S.M.A.R.T. Section
            if !metricsProvider.smartInfos.isEmpty {
                SMARTPanelView(smartInfos: metricsProvider.smartInfos)
            }

            // Sensor Section
            if !metricsProvider.sensorReadings.isEmpty {
                SensorPanelView(sensorReadings: metricsProvider.sensorReadings)
            }

            // Top Processes Section
            if !metricsProvider.topCPUProcesses.isEmpty || !metricsProvider.topMemoryProcesses.isEmpty {
                TopProcessesPanelView(
                    topCPUProcesses: metricsProvider.topCPUProcesses,
                    topMemoryProcesses: metricsProvider.topMemoryProcesses
                )
            }

            // Weather Section
            if let weather = metricsProvider.weatherInfo {
                WeatherPanelView(weatherInfo: weather)
            }

            Divider()
                .padding(.vertical, 4)

            // Quick Actions
            VStack(alignment: .leading, spacing: 6) {
                Button(action: {
                    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.ActivityMonitor") {
                        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: { _, _ in })
                    }
                }) {
                    Label("Activity Monitor", systemImage: "list.dash")
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))

                Button(action: { NSApp.activate(ignoringOtherApps: true) }) {
                    Label("Preferences", systemImage: "gear")
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))

                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Label("Quit Vigil", systemImage: "power")
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(.red)
            }
        }
        .padding()
        .frame(width: 320)
        .onAppear {
            metricsProvider.start()
        }
        .onDisappear {
            metricsProvider.stop()
        }
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.0f KB", Double(bytes) / 1024)
        } else if bytes < 1024 * 1024 * 1024 {
            return String(format: "%.0f MB", Double(bytes) / 1024 / 1024)
        } else {
            return String(format: "%.1f GB", Double(bytes) / 1024 / 1024 / 1024)
        }
    }
}

struct MetricSectionView: View {
    let title: String
    let value: String
    let details: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(value)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                }
                Spacer()
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 2) {
                ForEach(details, id: \.self) { detail in
                    Text(detail)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(red: 0.95, green: 0.95, blue: 0.95))
        .cornerRadius(6)
    }
}
