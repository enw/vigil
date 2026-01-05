import SwiftUI

struct PreferencesWindow: View {
    @State private var selectedTab: String = "general"

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralPreferencesView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag("general")

            MenuBarPreferencesView()
                .tabItem {
                    Label("Menu Bar", systemImage: "menu.bar.rectangle")
                }
                .tag("menubar")

            NotificationPreferencesView()
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }
                .tag("notifications")
        }
        .frame(width: 400, height: 300)
    }
}

struct GeneralPreferencesView: View {
    @AppStorage("launchAtLogin") var launchAtLogin = true
    @AppStorage("updateInterval") var updateInterval = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Launch at Login", isOn: $launchAtLogin)
            Toggle("Show in Menu Bar", isOn: .constant(true))
                .disabled(true)

            VStack(alignment: .leading, spacing: 8) {
                Text("Update Frequency")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)

                Picker("Update Frequency", selection: $updateInterval) {
                    Text("Every 0.5 seconds").tag(0.5)
                    Text("Every 1 second").tag(1.0)
                    Text("Every 2 seconds").tag(2.0)
                    Text("Every 5 seconds").tag(5.0)
                    Text("Every 10 seconds").tag(10.0)
                }
                .pickerStyle(.segmented)
            }

            Spacer()
        }
        .padding()
    }
}

struct MenuBarPreferencesView: View {
    @AppStorage("showCPU") var showCPU = true
    @AppStorage("showMemory") var showMemory = true
    @AppStorage("showNetwork") var showNetwork = false
    @AppStorage("showDisk") var showDisk = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Menu Bar Items")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            Toggle("CPU", isOn: $showCPU)
            Toggle("Memory", isOn: $showMemory)
            Toggle("Network", isOn: $showNetwork)
            Toggle("Disk", isOn: $showDisk)

            Spacer()
        }
        .padding()
    }
}

struct NotificationPreferencesView: View {
    @AppStorage("enableNotifications") var enableNotifications = true
    @AppStorage("cpuThreshold") var cpuThreshold = 80.0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Enable Notifications", isOn: $enableNotifications)

            VStack(alignment: .leading, spacing: 8) {
                Text("CPU Alert Threshold: \(Int(cpuThreshold))%")
                    .font(.system(size: 11, weight: .semibold))
                Slider(value: $cpuThreshold, in: 50...100, step: 5)
            }
            .disabled(!enableNotifications)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    PreferencesWindow()
}
