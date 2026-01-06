import SwiftUI

struct SMARTPanelView: View {
    let smartInfos: [SMARTMonitor.SMARTInfo]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Disk Health (S.M.A.R.T.)")
                .font(.system(size: 13, weight: .semibold))
            
            if smartInfos.isEmpty {
                Text("No disk information available")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(smartInfos, id: \.diskId) { info in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(info.name)
                                    .font(.system(size: 10, weight: .semibold))
                                Spacer()
                                statusBadge(info.status)
                            }
                            
                            HStack {
                                Text(info.diskId)
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(info.status.rawValue)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(statusColor(info.status))
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
    
    @ViewBuilder
    private func statusBadge(_ status: SMARTMonitor.SMARTInfo.HealthStatus) -> some View {
        switch status {
        case .healthy:
            Label("", systemImage: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .warning:
            Label("", systemImage: "exclamationmark.circle.fill")
                .foregroundColor(.orange)
        case .critical:
            Label("", systemImage: "xmark.circle.fill")
                .foregroundColor(.red)
        case .unknown:
            Label("", systemImage: "questionmark.circle.fill")
                .foregroundColor(.gray)
        }
    }
    
    private func statusColor(_ status: SMARTMonitor.SMARTInfo.HealthStatus) -> Color {
        switch status {
        case .healthy:
            return .green
        case .warning:
            return .orange
        case .critical:
            return .red
        case .unknown:
            return .gray
        }
    }
}
