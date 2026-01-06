import SwiftUI

struct WeatherPanelView: View {
    let weatherInfo: WeatherService.WeatherInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weather")
                .font(.system(size: 13, weight: .semibold))
            
            VStack(alignment: .leading, spacing: 8) {
                // Current conditions
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(weatherInfo.location)
                            .font(.system(size: 10, weight: .semibold))
                        Text(weatherInfo.description)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.0f°C", weatherInfo.temperature))
                            .font(.system(size: 16, weight: .bold))
                        Text(String(format: "Feels like %.0f°C", weatherInfo.feelsLike))
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Weather details grid
                VStack(spacing: 6) {
                    HStack(spacing: 12) {
                        DetailItem(
                            icon: "humidity",
                            label: "Humidity",
                            value: "\(weatherInfo.humidity)%"
                        )
                        DetailItem(
                            icon: "wind",
                            label: "Wind",
                            value: String(format: "%.1f m/s", weatherInfo.windSpeed)
                        )
                    }
                    
                    HStack(spacing: 12) {
                        DetailItem(
                            icon: "gauge",
                            label: "Pressure",
                            value: "\(weatherInfo.pressure) hPa"
                        )
                        DetailItem(
                            icon: "cloud",
                            label: "Cloud Cover",
                            value: "\(weatherInfo.cloudCover)%"
                        )
                    }
                }
                
                Divider()
                
                // Sun times
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Label("Sunrise", systemImage: "sunrise.fill")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.orange)
                        Text(formatTime(weatherInfo.sunrise))
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Label("Sunset", systemImage: "sunset.fill")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.orange)
                        Text(formatTime(weatherInfo.sunset))
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(red: 0.95, green: 0.95, blue: 0.95))
        .cornerRadius(6)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DetailItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(label, systemImage: icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 10, weight: .semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
