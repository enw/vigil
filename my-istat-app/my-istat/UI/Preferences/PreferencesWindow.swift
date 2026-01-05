import SwiftUI

struct PreferencesWindow: View {
    @State private var selectedTab: String = "general"

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            HStack(spacing: 0) {
                TabButton(title: "General", icon: "gear", isSelected: selectedTab == "general") {
                    selectedTab = "general"
                }
                TabButton(title: "Menu Bar", icon: "menu.bar.rectangle", isSelected: selectedTab == "menubar") {
                    selectedTab = "menubar"
                }
                TabButton(title: "Alerts", icon: "bell", isSelected: selectedTab == "notifications") {
                    selectedTab = "notifications"
                }
                Spacer()
            }
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Tab content
            TabView(selection: $selectedTab) {
                GeneralPreferencesView()
                    .tag("general")

                MenuBarPreferencesView()
                    .tag("menubar")

                NotificationPreferencesView()
                    .tag("notifications")
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .frame(width: 500, height: 400)
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundColor(isSelected ? .blue : .secondary)
            .background(isSelected ? Color(nsColor: .controlBackgroundColor).opacity(0.5) : .clear)
        }
        .buttonStyle(.plain)
    }
}

struct GeneralPreferencesView: View {
    @AppStorage("launchAtLogin") var launchAtLogin = true
    @AppStorage("updateInterval") var updateInterval = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            GroupBox(label: Text("Launch").font(.system(size: 12, weight: .semibold))) {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Launch at Login", isOn: $launchAtLogin)
                    Toggle("Show in Menu Bar", isOn: .constant(true))
                        .disabled(true)
                }
                .font(.system(size: 11))
            }

            GroupBox(label: Text("Updates").font(.system(size: 12, weight: .semibold))) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Update Frequency")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)

                    Picker("Update Frequency", selection: $updateInterval) {
                        Text("Every 0.5s").tag(0.5)
                        Text("Every 1s").tag(1.0)
                        Text("Every 2s").tag(2.0)
                        Text("Every 5s").tag(5.0)
                    }
                    .pickerStyle(.segmented)
                }
                .font(.system(size: 11))
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
    @AppStorage("showBattery") var showBattery = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            GroupBox(label: Text("Visible Items").font(.system(size: 12, weight: .semibold))) {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("CPU", isOn: $showCPU)
                    Toggle("Memory", isOn: $showMemory)
                    Toggle("Network", isOn: $showNetwork)
                    Toggle("Disk", isOn: $showDisk)
                    Toggle("Battery", isOn: $showBattery)
                }
                .font(.system(size: 11))
            }

            GroupBox(label: Text("Display Mode").font(.system(size: 12, weight: .semibold))) {
                VStack(alignment: .leading, spacing: 8) {
                    RadioButton("Individual items", selected: true)
                    RadioButton("Combined icon", selected: false)
                }
                .font(.system(size: 11))
            }

            Spacer()
        }
        .padding()
    }
}

struct NotificationPreferencesView: View {
    @AppStorage("enableNotifications") var enableNotifications = true
    @AppStorage("cpuThreshold") var cpuThreshold = 80.0
    @AppStorage("memoryThreshold") var memoryThreshold = 85.0

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            GroupBox(label: Text("Alerts").font(.system(size: 12, weight: .semibold))) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Enable Notifications", isOn: $enableNotifications)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("CPU Threshold")
                            Spacer()
                            Text("\(Int(cpuThreshold))%")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $cpuThreshold, in: 50...100, step: 5)
                    }
                    .disabled(!enableNotifications)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Memory Threshold")
                            Spacer()
                            Text("\(Int(memoryThreshold))%")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $memoryThreshold, in: 50...100, step: 5)
                    }
                    .disabled(!enableNotifications)
                }
                .font(.system(size: 11))
            }

            Spacer()
        }
        .padding()
    }
}

struct RadioButton: View {
    let label: String
    let selected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                .font(.system(size: 12))
                .foregroundColor(selected ? .blue : .secondary)
            Text(label)
            Spacer()
        }
    }
}

#Preview {
    PreferencesWindow()
}
