import Foundation

class WeatherService {
    struct WeatherInfo {
        let temperature: Double // Celsius
        let feelsLike: Double
        let description: String
        let humidity: Int // 0-100
        let windSpeed: Double // m/s
        let pressure: Int // hPa
        let cloudCover: Int // 0-100
        let uvIndex: Double?
        let sunrise: Date
        let sunset: Date
        let location: String
    }
    
    private let apiKey = "demo" // Free tier for demo - user can set their own
    private var cachedWeather: WeatherInfo?
    private var lastWeatherUpdate: Date = Date()
    private let weatherCacheTTL: TimeInterval = 600.0 // Cache for 10 minutes
    
    private let defaultLat = 37.7749 // San Francisco as default
    private let defaultLon = -122.4194
    
    func getWeatherInfo() -> WeatherInfo? {
        // Check cache first
        if let cached = cachedWeather,
           Date().timeIntervalSince(lastWeatherUpdate) < weatherCacheTTL {
            return cached
        }
        
        // Try to fetch fresh weather
        let userLat = UserDefaults.standard.double(forKey: "weatherLat")
        let userLon = UserDefaults.standard.double(forKey: "weatherLon")
        let lat = userLat != 0 ? userLat : defaultLat
        let lon = userLon != 0 ? userLon : defaultLon
        
        let apiKey = UserDefaults.standard.string(forKey: "openWeatherMapKey") ?? self.apiKey
        
        if let weather = fetchWeatherFromAPI(lat: lat, lon: lon, apiKey: apiKey) {
            cachedWeather = weather
            lastWeatherUpdate = Date()
            return weather
        }
        
        return cachedWeather
    }
    
    private func fetchWeatherFromAPI(lat: Double, lon: Double, apiKey: String) -> WeatherInfo? {
        // Skip if using demo key
        if apiKey == "demo" {
            return nil
        }
        
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"
        
        guard let url = URL(string: urlString) else { return nil }
        
        var result: WeatherInfo?
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            defer { semaphore.signal() }
            
            guard let data = data, error == nil else { return }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    result = self?.parseWeatherJSON(json)
                }
            } catch {
                print("Weather API parse error: \(error)")
            }
        }
        
        task.resume()
        _ = semaphore.wait(timeout: .now() + 5) // 5 second timeout
        
        return result
    }
    
    private func parseWeatherJSON(_ json: [String: Any]) -> WeatherInfo? {
        guard let main = json["main"] as? [String: Any],
              let weather = (json["weather"] as? [[String: Any]])?.first,
              let wind = json["wind"] as? [String: Any],
              let clouds = json["clouds"] as? [String: Any],
              let sys = json["sys"] as? [String: Any]
        else { return nil }
        
        let temp = main["temp"] as? Double ?? 0
        let feelsLike = main["feels_like"] as? Double ?? temp
        let humidity = main["humidity"] as? Int ?? 0
        let pressure = main["pressure"] as? Int ?? 0
        let description = (weather["main"] as? String ?? "Unknown") + ": " + (weather["description"] as? String ?? "")
        let windSpeed = wind["speed"] as? Double ?? 0
        let cloudCover = clouds["all"] as? Int ?? 0
        let sunriseTS = sys["sunrise"] as? Double ?? Date().timeIntervalSince1970
        let sunsetTS = sys["sunset"] as? Double ?? Date().timeIntervalSince1970
        let location = (json["name"] as? String ?? "Unknown") + (json["sys"] as? [String: Any] != nil ? ", " + ((json["sys"] as! [String: Any])["country"] as? String ?? "") : "")
        
        return WeatherInfo(
            temperature: temp,
            feelsLike: feelsLike,
            description: description,
            humidity: humidity,
            windSpeed: windSpeed,
            pressure: pressure,
            cloudCover: cloudCover,
            uvIndex: nil, // Would require separate API call
            sunrise: Date(timeIntervalSince1970: sunriseTS),
            sunset: Date(timeIntervalSince1970: sunsetTS),
            location: location
        )
    }
    
    // Get brief weather for menu bar
    func getWeatherBrief() -> String {
        guard let weather = getWeatherInfo() else {
            return "--"
        }
        return String(format: "%.0f°C", weather.temperature)
    }
}
