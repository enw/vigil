import SwiftUI

struct BatteryPanelView: View {
    let batteryMetrics: BatteryMonitor.BatteryInfo
    let batteryMonitor = BatteryMonitor()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Battery")
                .font(.system(size: 13, weight: .semibold))

            VStack(alignment: .leading, spacing: 8) {
                // Battery percentage with visual indicator
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Charge")
                            .font(.system(size: 10, weight: .semibold))
                        Text("\(batteryMetrics.percentage)%")
                            .font(.system(size: 14, weight: .bold))
                    }
                    Spacer()
                    Image(systemName: batteryIcon)
                        .font(.system(size: 24))
                        .foregroundColor(batteryColor)
                }

                Divider()

                // Battery details
                VStack(alignment: .leading, spacing: 4) {
                    DetailRow("Status:", value: batteryMetrics.isCharging ? "Charging" : "On Battery")
                    if !batteryMetrics.isCharging, let timeRemaining = batteryMetrics.timeRemaining {
                        let hours = Int(timeRemaining) / 3600
                        let minutes = (Int(timeRemaining) % 3600) / 60
                        DetailRow("Time Remaining:", value: "\(hours)h \(minutes)m")
                    }
                    DetailRow("Health:", value: batteryMetrics.health)
                    DetailRow("Cycle Count:", value: String(batteryMetrics.cycleCount))
                }
                .font(.system(size: 10, weight: .regular))

                Divider()

                Text(batteryMonitor.getChargingEstimate())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(red: 0.95, green: 0.95, blue: 0.95))
        .cornerRadius(6)
    }

    private var batteryIcon: String {
        if batteryMetrics.percentage < 20 {
            return batteryMetrics.isCharging ? "bolt.badge.exclamationmark" : "exclamationmark.triangle"
        } else if batteryMetrics.isCharging {
            return "battery.100.bolt"
        } else {
            let iconValue = Int(max(0, (Double(batteryMetrics.percentage) / 25 * 100).rounded()))
            return "battery.\(iconValue)"
        }
    }

    private var batteryColor: Color {
        if batteryMetrics.percentage < 20 {
            return .red
        } else if batteryMetrics.percentage < 50 {
            return .orange
        } else {
            return .green
        }
    }
}
