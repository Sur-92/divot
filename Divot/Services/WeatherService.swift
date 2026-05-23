import Foundation

struct WeatherSummary {
    let code: Int
    let highF: Double
    let lowF: Double
    let windMph: Double
    let precipIn: Double
}

/// Historical daily weather via Open-Meteo — free, no API key. Tries the
/// forecast endpoint (covers ~92 days back) then the archive endpoint
/// (older dates). Used to stamp a round with the conditions it was played in.
enum WeatherService {
    static func fetch(lat: Double, lon: Double, date: Date) async -> WeatherSummary? {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(identifier: "UTC")
        df.dateFormat = "yyyy-MM-dd"
        let day = df.string(from: date)

        let daily = "weathercode,temperature_2m_max,temperature_2m_min,windspeed_10m_max,precipitation_sum"
        let common = "latitude=\(lat)&longitude=\(lon)&start_date=\(day)&end_date=\(day)"
            + "&daily=\(daily)&temperature_unit=fahrenheit&windspeed_unit=mph"
            + "&precipitation_unit=inch&timezone=auto"

        let endpoints = [
            "https://api.open-meteo.com/v1/forecast?\(common)",
            "https://archive-api.open-meteo.com/v1/archive?\(common)"
        ]
        for str in endpoints {
            if let s = await tryFetch(str) { return s }
        }
        return nil
    }

    private static func tryFetch(_ urlStr: String) async -> WeatherSummary? {
        guard let url = URL(string: urlStr) else { return nil }
        do {
            let (data, resp) = try await URLSession.shared.data(from: url)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let r = try JSONDecoder().decode(OMResponse.self, from: data)
            guard let d = r.daily,
                  let code = (d.weathercode?.first ?? nil),
                  let hi = (d.temperature_2m_max?.first ?? nil),
                  let lo = (d.temperature_2m_min?.first ?? nil) else { return nil }
            return WeatherSummary(
                code: code, highF: hi, lowF: lo,
                windMph: (d.windspeed_10m_max?.first ?? nil) ?? 0,
                precipIn: (d.precipitation_sum?.first ?? nil) ?? 0)
        } catch { return nil }
    }

    private struct OMResponse: Decodable {
        let daily: Daily?
        struct Daily: Decodable {
            let weathercode: [Int?]?
            let temperature_2m_max: [Double?]?
            let temperature_2m_min: [Double?]?
            let windspeed_10m_max: [Double?]?
            let precipitation_sum: [Double?]?
        }
    }

    // MARK: - WMO weather code → display

    static func symbol(for code: Int) -> String {
        switch code {
        case 0:                              return "sun.max.fill"
        case 1, 2:                           return "cloud.sun.fill"
        case 3:                              return "cloud.fill"
        case 45, 48:                         return "cloud.fog.fill"
        case 51, 53, 55, 56, 57:             return "cloud.drizzle.fill"
        case 61, 63, 80, 81:                 return "cloud.rain.fill"
        case 65, 66, 67, 82:                 return "cloud.heavyrain.fill"
        case 71, 73, 75, 77, 85, 86:         return "cloud.snow.fill"
        case 95, 96, 99:                     return "cloud.bolt.rain.fill"
        default:                             return "cloud.fill"
        }
    }

    static func label(for code: Int) -> String {
        switch code {
        case 0:                      return "Clear"
        case 1:                      return "Mostly clear"
        case 2:                      return "Partly cloudy"
        case 3:                      return "Overcast"
        case 45, 48:                 return "Fog"
        case 51, 53, 55, 56, 57:     return "Drizzle"
        case 61, 63, 80, 81:         return "Rain"
        case 65, 66, 67, 82:         return "Heavy rain"
        case 71, 73, 75, 77, 85, 86: return "Snow"
        case 95, 96, 99:             return "Thunderstorms"
        default:                     return "Cloudy"
        }
    }
}
