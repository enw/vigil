import SwiftUI

@main
struct VigilApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra(content: {
            MenuContentView()
        }, label: {
            MenuBarLabel()
        })

        Settings {
            PreferencesWindow()
        }
    }
}

struct MenuBarLabel: View {
    @StateObject private var metricsProvider = SystemMetricsProvider()

    var body: some View {
        HStack(spacing: 6) {
            if let cpu = metricsProvider.cpuMetrics {
                Text(String(format: "CPU %d%%", Int(cpu.totalUsage)))
                    .font(.system(size: 11, weight: .semibold))
            }
            
            if let memory = metricsProvider.memoryMetrics {
                Text(String(format: "MEM %d%%", Int(memory.usedPercentage)))
                    .font(.system(size: 11, weight: .semibold))
            }
        }
        .onAppear {
            metricsProvider.start()
        }
        .onDisappear {
            metricsProvider.stop()
        }
    }
}
