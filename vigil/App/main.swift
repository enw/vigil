import SwiftUI

@main
struct VigilApp: App {
    @StateObject private var metricsProvider = SystemMetricsProvider()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("showCPU") private var showCPU = true
    @AppStorage("showMemory") private var showMemory = true

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(metricsProvider: metricsProvider)
        } label: {
            MenuBarLabel(metricsProvider: metricsProvider)
        }

        Settings {
            PreferencesWindow()
        }
    }
}

struct MenuBarLabel: View {
    @ObservedObject var metricsProvider: SystemMetricsProvider
    @AppStorage("showCPU") private var showCPU = true
    @AppStorage("showMemory") private var showMemory = true

    var body: some View {
        let titleText = buildTitleText()
        Text(titleText)
            .font(.system(size: 11, weight: .semibold))
            .onAppear {
                metricsProvider.start()
            }
            .onDisappear {
                metricsProvider.stop()
            }
    }
    
    private func buildTitleText() -> String {
        var components: [String] = []
        
        if showCPU, let cpu = metricsProvider.cpuMetrics {
            components.append(String(format: "CPU %d%%", Int(cpu.totalUsage)))
        }
        
        if showMemory, let memory = metricsProvider.memoryMetrics {
            components.append(String(format: "MEM %d%%", memory.usedPercentage))
        }
        
        return components.joined(separator: " ")
    }
}
