import SwiftUI

struct MenuContentView: View {
    @StateObject private var metricsProvider = SystemMetricsProvider()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // CPU Section
            if let cpu = metricsProvider.cpuMetrics {
                MenuSectionView(title: "CPU", value: cpu.usagePercentage)
                    .onTapGesture {
                        NSApp.sendAction(#selector(PreferencesWindow.show), to: nil, from: nil)
                    }
            }

            // Memory Section
            if let memory = metricsProvider.memoryMetrics {
                MenuSectionView(
                    title: "Memory",
                    value: String(format: "%.1f%%", memory.usedPercentage)
                )
            }

            Divider()

            // Quick Actions
            Button("Open in Activity Monitor") {
                NSWorkspace.shared.launchApplication("Activity Monitor")
            }
            .font(.system(size: 11))

            Button("Preferences...") {
                NSApp.sendAction(
                    #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
                    to: NSApp,
                    from: nil
                )
            }
            .font(.system(size: 11))

            Button("Quit cavestat") {
                NSApplication.shared.terminate(nil)
            }
            .font(.system(size: 11))
        }
        .padding()
        .frame(width: 250)
        .onAppear {
            metricsProvider.start()
        }
        .onDisappear {
            metricsProvider.stop()
        }
    }
}

struct MenuSectionView: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.tertiary)
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(4)
    }
}

#Preview {
    MenuContentView()
}
