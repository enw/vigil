import SwiftUI

struct MenuContentView: View {
    @StateObject private var metricsProvider = SystemMetricsProvider()

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
            } else {
                Text("Loading CPU metrics...")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
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
            } else {
                Text("Loading memory metrics...")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
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
        .frame(width: 280)
        .onAppear {
            metricsProvider.start()
        }
        .onDisappear {
            metricsProvider.stop()
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
