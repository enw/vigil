import SwiftUI

struct TopProcessesPanelView: View {
    let topCPUProcesses: [ProcessMonitor.ProcessInfo]
    let topMemoryProcesses: [ProcessMonitor.ProcessInfo]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Processes")
                .font(.system(size: 13, weight: .semibold))
            
            if topCPUProcesses.isEmpty && topMemoryProcesses.isEmpty {
                Text("No process data available")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    // Top CPU processes
                    if !topCPUProcesses.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("By CPU")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            ForEach(topCPUProcesses.prefix(3)) { process in
                                ProcessRowView(process: process, metric: "CPU")
                            }
                        }
                        .padding(8)
                        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                        .cornerRadius(4)
                    }
                    
                    // Top Memory processes
                    if !topMemoryProcesses.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("By Memory")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            ForEach(topMemoryProcesses.prefix(3)) { process in
                                ProcessRowView(process: process, metric: "Memory")
                            }
                        }
                        .padding(8)
                        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                        .cornerRadius(4)
                    }
                }
            }
        }
        .padding()
        .background(Color(red: 0.95, green: 0.95, blue: 0.95))
        .cornerRadius(6)
    }
}

struct ProcessRowView: View {
    let process: ProcessMonitor.ProcessInfo
    let metric: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(process.name)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
                Spacer()
                Text(metric == "CPU" ? String(format: "%.1f%%", process.cpuUsage) : formatBytes(process.memoryUsage))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            Text("PID: \(process.pid)")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let mb = Double(bytes) / 1024 / 1024
        if mb < 1024 {
            return String(format: "%.0f MB", mb)
        }
        let gb = mb / 1024
        return String(format: "%.1f GB", gb)
    }
}
