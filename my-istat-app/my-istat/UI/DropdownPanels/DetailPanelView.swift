import SwiftUI

struct DetailPanelView: View {
    @StateObject private var metricsProvider = SystemMetricsProvider()
    @StateObject private var historyManager = HistoryManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // CPU Details
            if let cpu = metricsProvider.cpuMetrics {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CPU")
                        .font(.system(size: 13, weight: .semibold))

                    VStack(alignment: .leading, spacing: 4) {
                        DetailRow("Usage:", value: cpu.usagePercentage)
                        DetailRow("Cores:", value: String(cpu.processorCount))
                        DetailRow("Load (1m):", value: String(format: "%.2f", cpu.loadAverage.one))
                        DetailRow("Load (5m):", value: String(format: "%.2f", cpu.loadAverage.five))
                        DetailRow("Load (15m):", value: String(format: "%.2f", cpu.loadAverage.fifteen))
                        DetailRow("Uptime:", value: cpu.formattedUptime)
                    }
                    .font(.system(size: 10, weight: .regular))
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)

                SimpleGraph(
                    data: historyManager.getCPUHistory().suffix(120).map { Double($0) },
                    title: "CPU Usage (Last 2 minutes)",
                    color: .blue
                )
            }

            // Memory Details
            if let memory = metricsProvider.memoryMetrics {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Memory")
                        .font(.system(size: 13, weight: .semibold))

                    VStack(alignment: .leading, spacing: 4) {
                        DetailRow("Usage:", value: memory.usagePercentage)
                        DetailRow("Used:", value: memory.formattedUsed)
                        DetailRow("Free:", value: memory.formattedFree)
                        DetailRow("Total:", value: memory.formattedTotal)
                        DetailRow("Active:", value: String(format: "%.2f GB", Double(memory.active) / 1024 / 1024 / 1024))
                        DetailRow("Compressed:", value: String(format: "%.2f GB", Double(memory.compressed) / 1024 / 1024 / 1024))
                    }
                    .font(.system(size: 10, weight: .regular))
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)

                SimpleGraph(
                    data: historyManager.getMemoryHistory().suffix(120).map { Double($0) },
                    title: "Memory Usage (Last 2 minutes)",
                    color: .green
                )
            }

            Spacer()
        }
        .padding()
        .frame(width: 400, height: 600)
        .onAppear {
            metricsProvider.start()

            // Update history
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if let cpu = metricsProvider.cpuMetrics, let memory = metricsProvider.memoryMetrics {
                    historyManager.addDataPoint(
                        cpuUsage: cpu.totalUsage,
                        memoryUsage: memory.usedPercentage
                    )
                }
            }
        }
        .onDisappear {
            metricsProvider.stop()
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    init(_ label: String, value: String) {
        self.label = label
        self.value = value
    }

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    DetailPanelView()
}
