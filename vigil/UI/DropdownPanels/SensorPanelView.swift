import SwiftUI

struct SensorPanelView: View {
    let sensorReadings: [SensorMonitor.SensorReading]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sensors")
                .font(.system(size: 13, weight: .semibold))
            
            if sensorReadings.isEmpty {
                Text("No sensor data available")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    // Group readings by type
                    let temperatureReadings = sensorReadings.filter { $0.type == .cpuTemp || $0.type == .gpuTemp }
                    let fanReadings = sensorReadings.filter { $0.type == .fanSpeed }
                    
                    if !temperatureReadings.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Temperatures")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            ForEach(temperatureReadings, id: \.name) { reading in
                                HStack {
                                    Text(reading.name)
                                        .font(.system(size: 10))
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Image(systemName: "thermometer.half")
                                            .font(.system(size: 9))
                                            .foregroundColor(temperatureColor(reading.value))
                                        Text(String(format: "%.1f\(reading.unit)", reading.value))
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(temperatureColor(reading.value))
                                    }
                                }
                            }
                        }
                    }
                    
                    if !fanReadings.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Fans")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            ForEach(fanReadings, id: \.name) { reading in
                                HStack {
                                    Text(reading.name)
                                        .font(.system(size: 10))
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Image(systemName: "fan.fill")
                                            .font(.system(size: 9))
                                            .foregroundColor(.secondary)
                                        Text(String(format: "%.0f \(reading.unit)", reading.value))
                                            .font(.system(size: 10, weight: .semibold))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(red: 0.95, green: 0.95, blue: 0.95))
        .cornerRadius(6)
    }
    
    private func temperatureColor(_ temp: Double) -> Color {
        if temp < 50 {
            return .blue
        } else if temp < 70 {
            return .green
        } else if temp < 85 {
            return .orange
        } else {
            return .red
        }
    }
}
