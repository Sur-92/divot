import Foundation

// MARK: - Public display types

struct PGATournament: Identifiable, Hashable {
    let id: String
    let name: String
    let shortName: String
    let startDate: Date
    let endDate: Date
    let venue: String
    let city: String
    let status: PGAStatus
    let leaderboard: [PGALeaderboardEntry]

    var isLive: Bool       { status == .inProgress }
    var isUpcoming: Bool   { status == .scheduled }
    var isComplete: Bool   { status == .complete }

    var dateRange: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        let start = fmt.string(from: startDate)
        fmt.dateFormat = "MMM d, yyyy"
        let end = fmt.string(from: endDate)
        return "\(start) – \(end)"
    }
}

enum PGAStatus: String {
    case scheduled    // "pre"
    case inProgress   // "in"
    case complete     // "post"

    var displayLabel: String {
        switch self {
        case .scheduled:  return "UPCOMING"
        case .inProgress: return "IN PROGRESS"
        case .complete:   return "FINAL"
        }
    }
}

struct PGALeaderboardEntry: Identifiable, Hashable {
    let id: String
    let position: String   // e.g. "1", "T2", "CUT"
    let player: String
    let country: String
    let toPar: String      // e.g. "-12", "E", "+3"
    let thru: String       // e.g. "F", "14", "—"

    /// Per-round stroke totals (R1, R2, R3, R4). 0 for a round not yet played.
    let roundScores: [Int]

    /// Current OWGR (Official World Golf Ranking) — nil if unranked or
    /// outside our curated top-50 snapshot.
    let worldRanking: Int?

    /// Sum of all played rounds (0 if none).
    var total: Int { roundScores.filter { $0 > 0 }.reduce(0, +) }
}

// MARK: - Course knowledge (curated)

struct PGACourseInfo: Hashable {
    let designer: String
    let yearOpened: Int
    let par: Int
    let yardage: Int
    let latitude: Double
    let longitude: Double
}

// MARK: - Weather

struct WeatherSnapshot: Hashable {
    let temperatureF: Double
    let feelsLikeF: Double?
    let windMph: Double
    let windDirectionDeg: Double
    let humidityPct: Double?
    let weatherCode: Int

    var conditionLabel: String {
        switch weatherCode {
        case 0:          return "Clear"
        case 1:          return "Mostly clear"
        case 2:          return "Partly cloudy"
        case 3:          return "Overcast"
        case 45, 48:     return "Foggy"
        case 51, 53, 55: return "Drizzle"
        case 56, 57:     return "Freezing drizzle"
        case 61, 63, 65: return "Rain"
        case 66, 67:     return "Freezing rain"
        case 71, 73, 75: return "Snow"
        case 77:         return "Snow grains"
        case 80, 81, 82: return "Rain showers"
        case 85, 86:     return "Snow showers"
        case 95:         return "Thunderstorm"
        case 96, 99:     return "Thunderstorm w/ hail"
        default:         return "—"
        }
    }

    var conditionIcon: String {
        switch weatherCode {
        case 0:          return "sun.max.fill"
        case 1:          return "sun.min.fill"
        case 2:          return "cloud.sun.fill"
        case 3:          return "cloud.fill"
        case 45, 48:     return "cloud.fog.fill"
        case 51...57:    return "cloud.drizzle.fill"
        case 61...67:    return "cloud.rain.fill"
        case 71...77:    return "cloud.snow.fill"
        case 80...82:    return "cloud.heavyrain.fill"
        case 85, 86:     return "cloud.snow.fill"
        case 95, 96, 99: return "cloud.bolt.rain.fill"
        default:         return "cloud"
        }
    }

    var windCompass: String {
        let compass = ["N","NNE","NE","ENE","E","ESE","SE","SSE",
                       "S","SSW","SW","WSW","W","WNW","NW","NNW","N"]
        let idx = Int(((windDirectionDeg + 11.25) / 22.5).rounded(.down)) % 16
        return compass[idx]
    }
}

// MARK: - News feed

struct PGAArticle: Identifiable, Hashable {
    let id: String
    let headline: String
    let description: String
    let byline: String
    let publishedAt: Date
    let imageURL: URL?
    let webURL: URL?

    var relativeTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: publishedAt, relativeTo: Date())
    }
}

// MARK: - Service

final class PGAService {
    static let shared = PGAService()
    private init() {}

    private let scoreboardURL = URL(string:
        "https://site.api.espn.com/apis/site/v2/sports/golf/pga/scoreboard")!
    private let newsURL = URL(string:
        "https://site.api.espn.com/apis/site/v2/sports/golf/pga/news")!
    private let pgaTourNewsURL = URL(string:
        "https://www.pgatour.com/news")!

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 12
        cfg.timeoutIntervalForResource = 20
        cfg.waitsForConnectivity = true
        return URLSession(configuration: cfg)
    }()

    /// Fetches a URL with automatic retry on network/TLS hiccups.
    /// ESPN's edge occasionally throws transient `SSL_ERROR_SYSCALL`s —
    /// retrying 1-2 times with a short backoff almost always succeeds.
    private func fetchData(from url: URL, retries: Int = 2) async throws -> Data {
        var lastError: Error = PGAError.badResponse
        for attempt in 0...retries {
            do {
                let (data, response) = try await session.data(from: url)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    throw PGAError.badResponse
                }
                return data
            } catch {
                lastError = error
                if attempt < retries {
                    // Exponential-ish backoff: 0.5s, 1.0s, 2.0s
                    let ns = UInt64(pow(2.0, Double(attempt)) * 500_000_000)
                    try? await Task.sleep(nanoseconds: ns)
                }
            }
        }
        throw lastError
    }

    // In-memory caches — refresh no more than every 90s (board) / 5m (news).
    private var cachedBoard: (tournaments: [PGATournament], fetchedAt: Date)?
    private var cachedNews: (articles: [PGAArticle], fetchedAt: Date)?
    private let boardTTL: TimeInterval = 90
    private let newsTTL: TimeInterval = 300

    /// Returns all tournaments in the current scoreboard response.
    func fetchTournaments(forceRefresh: Bool = false) async throws -> [PGATournament] {
        if !forceRefresh,
           let cachedBoard,
           Date().timeIntervalSince(cachedBoard.fetchedAt) < boardTTL {
            return cachedBoard.tournaments
        }
        let data = try await fetchData(from: scoreboardURL)
        let decoded = try JSONDecoder().decode(Scoreboard.self, from: data)
        let tournaments = decoded.events.map { $0.toTournament() }
            .sorted { $0.startDate < $1.startDate }
        cachedBoard = (tournaments, .now)
        return tournaments
    }

    /// Curated knowledge for well-known PGA Tour venues, keyed by a
    /// case-insensitive substring of the tournament/event name.
    static let courseKnowledge: [(key: String, info: PGACourseInfo)] = [
        ("rbc heritage",
            .init(designer: "Pete Dye & Jack Nicklaus", yearOpened: 1969,
                  par: 71, yardage: 7121, latitude: 32.1403, longitude: -80.8087)),
        ("masters",
            .init(designer: "Alister MacKenzie & Bobby Jones", yearOpened: 1933,
                  par: 72, yardage: 7555, latitude: 33.5021, longitude: -82.0232)),
        ("players championship",
            .init(designer: "Pete Dye", yearOpened: 1980,
                  par: 72, yardage: 7275, latitude: 30.1973, longitude: -81.3877)),
        ("memorial",
            .init(designer: "Jack Nicklaus", yearOpened: 1974,
                  par: 72, yardage: 7571, latitude: 40.1459, longitude: -83.1427)),
        ("travelers",
            .init(designer: "Pete Dye · Bobby Weed redesign", yearOpened: 1928,
                  par: 70, yardage: 6841, latitude: 41.6054, longitude: -72.6604)),
        ("arnold palmer",
            .init(designer: "Dick Wilson · Arnold Palmer redesign", yearOpened: 1961,
                  par: 72, yardage: 7466, latitude: 28.4592, longitude: -81.5149)),
        ("genesis",
            .init(designer: "George C. Thomas Jr.", yearOpened: 1927,
                  par: 71, yardage: 7322, latitude: 34.0484, longitude: -118.5027)),
        ("pebble beach",
            .init(designer: "Jack Neville & Douglas Grant", yearOpened: 1919,
                  par: 72, yardage: 6828, latitude: 36.5678, longitude: -121.9500)),
        ("phoenix open",
            .init(designer: "Tom Weiskopf & Jay Morrish", yearOpened: 1986,
                  par: 71, yardage: 7261, latitude: 33.6452, longitude: -111.9038)),
        ("farmers insurance",
            .init(designer: "William P. Bell", yearOpened: 1957,
                  par: 72, yardage: 7698, latitude: 32.8953, longitude: -117.2510)),
        ("sentry",
            .init(designer: "Ben Crenshaw & Bill Coore", yearOpened: 1991,
                  par: 73, yardage: 7596, latitude: 20.9995, longitude: -156.6638)),
        ("valero texas open",
            .init(designer: "Greg Norman", yearOpened: 2010,
                  par: 72, yardage: 7438, latitude: 29.3819, longitude: -98.6017)),
        ("wells fargo",
            .init(designer: "George W. Cobb · Tom Fazio redesign", yearOpened: 1961,
                  par: 71, yardage: 7521, latitude: 35.1467, longitude: -80.7864)),
        ("charles schwab",
            .init(designer: "John Bredemus & Perry Maxwell", yearOpened: 1936,
                  par: 70, yardage: 7209, latitude: 32.7104, longitude: -97.4101)),
        ("tour championship",
            .init(designer: "Donald Ross", yearOpened: 1904,
                  par: 70, yardage: 7385, latitude: 33.7443, longitude: -84.3461)),
        ("zurich classic",
            .init(designer: "Pete Dye", yearOpened: 2004,
                  par: 72, yardage: 7425, latitude: 29.9800, longitude: -90.0530)),
        ("pga championship",
            .init(designer: "varies by year", yearOpened: 1916,
                  par: 72, yardage: 0, latitude: 0, longitude: 0)),
        ("us open",
            .init(designer: "varies by year", yearOpened: 1895,
                  par: 70, yardage: 0, latitude: 0, longitude: 0)),
        ("open championship",
            .init(designer: "varies by year", yearOpened: 1860,
                  par: 70, yardage: 0, latitude: 0, longitude: 0))
    ]

    static func courseInfo(for tournament: PGATournament) -> PGACourseInfo? {
        let lowered = tournament.name.lowercased()
        for (key, info) in courseKnowledge where lowered.contains(key) {
            return info
        }
        return nil
    }

    /// Fetches current weather from open-meteo (no API key required).
    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherSnapshot {
        guard latitude != 0 || longitude != 0 else { throw PGAError.badResponse }
        let urlStr = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=\(latitude)&longitude=\(longitude)"
            + "&current=temperature_2m,apparent_temperature,wind_speed_10m,wind_direction_10m,relative_humidity_2m,weather_code"
            + "&temperature_unit=fahrenheit&wind_speed_unit=mph"
        guard let url = URL(string: urlStr) else { throw PGAError.badResponse }
        let data = try await fetchData(from: url)
        struct Resp: Decodable {
            let current: Current
            struct Current: Decodable {
                let temperature_2m: Double
                let apparent_temperature: Double?
                let wind_speed_10m: Double
                let wind_direction_10m: Double
                let relative_humidity_2m: Double?
                let weather_code: Int
            }
        }
        let r = try JSONDecoder().decode(Resp.self, from: data)
        return WeatherSnapshot(
            temperatureF: r.current.temperature_2m,
            feelsLikeF: r.current.apparent_temperature,
            windMph: r.current.wind_speed_10m,
            windDirectionDeg: r.current.wind_direction_10m,
            humidityPct: r.current.relative_humidity_2m,
            weatherCode: r.current.weather_code
        )
    }

    /// Returns the latest PGA news articles — ESPN + PGATour.com merged,
    /// sorted newest-first. Either source failing silently falls back to
    /// whichever still worked.
    func fetchNews(forceRefresh: Bool = false) async throws -> [PGAArticle] {
        if !forceRefresh,
           let cachedNews,
           Date().timeIntervalSince(cachedNews.fetchedAt) < newsTTL {
            return cachedNews.articles
        }

        async let espn: [PGAArticle] = (try? await fetchESPNNews()) ?? []
        async let pgaTour: [PGAArticle] = (try? await fetchPGATourNews()) ?? []

        let combined = await (espn + pgaTour)
        // Dedupe by normalized headline (handles both sources covering the same story).
        var seen = Set<String>()
        let merged = combined.filter { a in
            let key = a.headline
                .lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .prefix(60)
            let k = String(key)
            if seen.contains(k) { return false }
            seen.insert(k)
            return true
        }
        .sorted { $0.publishedAt > $1.publishedAt }

        cachedNews = (merged, .now)
        if merged.isEmpty { throw PGAError.badResponse }
        return merged
    }

    private func fetchESPNNews() async throws -> [PGAArticle] {
        let data = try await fetchData(from: newsURL)
        let decoded = try JSONDecoder().decode(NewsResponse.self, from: data)
        return decoded.articles.compactMap { $0.toArticle() }
    }

    /// Scrapes PGATour.com/news — it's a Next.js app, so the article list
    /// lives in an embedded `__NEXT_DATA__` JSON blob rather than an API
    /// endpoint. We pull the page HTML, extract that blob, and walk the
    /// `dehydratedState.queries[].state.data.pages[].newsArticles.articles`
    /// path to the actual articles.
    private func fetchPGATourNews() async throws -> [PGAArticle] {
        var req = URLRequest(url: pgaTourNewsURL)
        req.setValue("Mozilla/5.0 (Macintosh)", forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 12

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw PGAError.badResponse
        }
        guard let html = String(data: data, encoding: .utf8) else {
            throw PGAError.badResponse
        }

        // Extract the <script id="__NEXT_DATA__">…</script> payload.
        let pattern = #"<script id="__NEXT_DATA__"[^>]*>(.*?)</script>"#
        guard let regex = try? NSRegularExpression(pattern: pattern,
                                                   options: [.dotMatchesLineSeparators]),
              let match = regex.firstMatch(in: html,
                                           range: NSRange(html.startIndex..., in: html)),
              let jsonRange = Range(match.range(at: 1), in: html),
              let jsonData = String(html[jsonRange]).data(using: .utf8),
              let root = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        else {
            throw PGAError.badResponse
        }

        let props = root["props"] as? [String: Any]
        let pageProps = props?["pageProps"] as? [String: Any]
        let dehydrated = pageProps?["dehydratedState"] as? [String: Any]
        let queries = dehydrated?["queries"] as? [[String: Any]] ?? []

        var articles: [PGAArticle] = []
        for query in queries {
            guard let state = query["state"] as? [String: Any],
                  let qdata = state["data"] as? [String: Any],
                  let pages = qdata["pages"] as? [[String: Any]]
            else { continue }

            for page in pages {
                guard let na = page["newsArticles"] as? [String: Any],
                      let list = na["articles"] as? [[String: Any]]
                else { continue }

                for a in list {
                    guard let headline = a["headline"] as? String, !headline.isEmpty
                    else { continue }

                    let teaser = (a["teaserContent"] as? String)
                        ?? (a["teaserHeadline"] as? String) ?? ""
                    let publishMs = a["publishDate"] as? Double ?? 0
                    let publishedAt = Date(timeIntervalSince1970: publishMs / 1000.0)
                    let img = a["articleImage"] as? String
                    let link = (a["shareURL"] as? String) ?? (a["url"] as? String)
                    let franchise = a["franchiseDisplayName"] as? String ?? "PGA Tour"
                    let id = a["id"] as? String ?? headline

                    articles.append(PGAArticle(
                        id: id,
                        headline: headline,
                        description: teaser,
                        byline: franchise,
                        publishedAt: publishedAt,
                        imageURL: img.flatMap { URL(string: $0) },
                        webURL: link.flatMap { URL(string: $0) }
                    ))
                }
            }
        }
        return articles
    }
}

enum PGAError: Error, LocalizedError {
    case badResponse
    var errorDescription: String? {
        switch self {
        case .badResponse:
            return "PGA feed is having a hiccup. Tap refresh in a few seconds."
        }
    }
}

extension URLError {
    /// Friendlier error text for the network errors we actually see from ESPN.
    var friendlyText: String {
        switch code {
        case .cannotFindHost, .cannotConnectToHost:
            return "Can't reach ESPN right now."
        case .timedOut:
            return "ESPN took too long to respond."
        case .notConnectedToInternet, .networkConnectionLost:
            return "No internet connection."
        case .secureConnectionFailed, .serverCertificateUntrusted,
             .serverCertificateHasBadDate, .serverCertificateNotYetValid,
             .serverCertificateHasUnknownRoot:
            return "ESPN's server had a secure-connection hiccup. Try refreshing."
        default:
            return "Network error — tap refresh to retry."
        }
    }
}

// MARK: - JSON decoding — news feed

private struct NewsResponse: Decodable {
    let articles: [NewsArticle]
}

private struct NewsArticle: Decodable {
    let id: Int?
    let headline: String?
    let description: String?
    let byline: String?
    let published: String?
    let images: [Image]?
    let links: Links?

    struct Image: Decodable {
        let url: String?
        let width: Int?
        let height: Int?
    }

    struct Links: Decodable {
        let web: Web?
        let mobile: Mobile?
        struct Web: Decodable { let href: String? }
        struct Mobile: Decodable { let href: String? }
    }

    func toArticle() -> PGAArticle? {
        guard let headline, !headline.isEmpty else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = published.flatMap { iso.date(from: $0) }
                ?? published.flatMap { ISO8601DateFormatter().date(from: $0) }
                ?? Date()

        let img = images?.first(where: { ($0.url ?? "").hasPrefix("http") })?.url
        let web = links?.web?.href ?? links?.mobile?.href

        return PGAArticle(
            id: id.map(String.init) ?? headline,
            headline: headline,
            description: description ?? "",
            byline: byline ?? "ESPN",
            publishedAt: date,
            imageURL: img.flatMap { URL(string: $0) },
            webURL: web.flatMap { URL(string: $0) }
        )
    }
}

// MARK: - JSON decoding — scoreboard

private struct Scoreboard: Decodable {
    let events: [Event]
}

private struct Event: Decodable {
    let id: String
    let name: String
    let shortName: String?
    let date: String
    let endDate: String?
    let status: Status
    let competitions: [Competition]?

    struct Status: Decodable {
        let type: StateType
        struct StateType: Decodable {
            let state: String
            let completed: Bool?
        }
    }

    struct Competition: Decodable {
        let venue: Venue?
        let competitors: [Competitor]?

        struct Venue: Decodable {
            let fullName: String?
            let address: Address?
            struct Address: Decodable {
                let city: String?
                let state: String?
            }
        }

        struct Competitor: Decodable {
            let id: String
            let score: String?
            let athlete: Athlete?
            let team: Team?
            let status: CompStatus?
            let sortOrder: Int?
            let order: Int?
            let linescores: [Linescore]?

            struct Athlete: Decodable {
                let displayName: String?
                let flag: Flag?
                struct Flag: Decodable { let alt: String? }
            }

            /// Present on team-format events (e.g. Zurich Classic). Two
            /// athletes per team; ESPN provides a combined display name
            /// like "Smalley/Springer".
            struct Team: Decodable {
                let displayName: String?
            }

            struct CompStatus: Decodable {
                let position: Position?
                let thru: Int?
                let displayThru: String?
                let type: StatusType?
                struct Position: Decodable { let displayName: String? }
                struct StatusType: Decodable { let completed: Bool? }
            }

            struct Linescore: Decodable {
                let value: Double?
                let displayValue: String?
                let period: Int?
                /// Per-hole scores within this round. Present while a
                /// round is being (or has been) played.
                let linescores: [HoleScore]?

                struct HoleScore: Decodable {
                    let value: Double?
                    let period: Int?
                }
            }
        }
    }

    func toTournament() -> PGATournament {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        let start = iso.date(from: date) ?? Date()
        let end = (endDate.flatMap { iso.date(from: $0) }) ?? start

        let competition = competitions?.first
        let venueName = competition?.venue?.fullName ?? ""
        let city = [
            competition?.venue?.address?.city,
            competition?.venue?.address?.state
        ].compactMap { $0 }.joined(separator: ", ")

        let state: PGAStatus = {
            switch status.type.state {
            case "in":   return .inProgress
            case "post": return .complete
            default:     return .scheduled
            }
        }()

        // Sort competitors by order / sortOrder ascending.
        let rawCompetitors = competition?.competitors ?? []
        let byOrder = rawCompetitors.sorted { a, b in
            (a.order ?? a.sortOrder ?? Int.max) < (b.order ?? b.sortOrder ?? Int.max)
        }

        // Build POSITION with ties ("1", "T2", "T2", "4"…) by grouping
        // consecutive competitors with identical scores.
        var positionMap: [String: String] = [:]
        var i = 0
        while i < byOrder.count {
            let currentScore = byOrder[i].score ?? ""
            var j = i
            while j < byOrder.count && (byOrder[j].score ?? "") == currentScore {
                j += 1
            }
            let rank = i + 1
            let tied = (j - i) > 1
            let posStr = tied ? "T\(rank)" : "\(rank)"
            for k in i..<j {
                positionMap[byOrder[k].id] = posStr
            }
            i = j
        }

        let leaderboard = byOrder.map { c -> PGALeaderboardEntry in
            // Per-round stroke totals (R1..R4), padded with 0 for unplayed.
            let outer = c.linescores ?? []
            let rawScores = outer.map { Int(($0.value ?? 0).rounded()) }
            let roundScores = Array(
                (rawScores + Array(repeating: 0, count: 4)).prefix(4)
            )

            // Walk rounds in order. ESPN populates `value` on a round as
            // soon as any holes are played (it's the running cumulative,
            // NOT a completed flag), so the only reliable "round done"
            // signal is 18 inner per-hole scores. If a round has some
            // holes played but less than 18, that's the live current
            // round and the inner count is the player's "thru" number.
            var roundsCompleted = 0
            var currentHole = 0

            for round in outer {
                let inner = round.linescores ?? []
                let holesPlayed = inner.filter { ($0.value ?? 0) > 0 }.count

                if holesPlayed >= 18 {
                    roundsCompleted += 1
                } else if holesPlayed > 0 {
                    currentHole = holesPlayed
                    break
                } else {
                    break
                }
            }

            let thru: String
            switch state {
            case .complete:
                thru = "F"
            case .inProgress:
                if c.status?.type?.completed == true || roundsCompleted >= 4 {
                    thru = "F"
                } else if currentHole > 0 {
                    // Mid-round — show hole number they've played through.
                    thru = "\(currentHole)"
                } else if roundsCompleted > 0 {
                    // Finished a round, next round hasn't started yet.
                    thru = "F"
                } else {
                    thru = "—"
                }
            case .scheduled:
                thru = "—"
            }

            // Team events (Zurich Classic) put the combined name on `team`
            // instead of `athlete`; fall through to that before giving up.
            let playerName = c.athlete?.displayName
                ?? c.team?.displayName
                ?? "Unknown"
            let isTeam = c.athlete == nil && c.team != nil
            return PGALeaderboardEntry(
                id: c.id,
                position: positionMap[c.id] ?? "—",
                player: playerName,
                country: c.athlete?.flag?.alt ?? "",
                toPar: c.score ?? "E",
                thru: thru,
                roundScores: roundScores,
                // World ranking is per-individual; suppress it for team
                // events so the column shows blank rather than a wrong rank.
                worldRanking: isTeam ? nil : WorldRankings.rank(for: playerName)
            )
        }

        return PGATournament(
            id: id,
            name: name,
            shortName: shortName ?? name,
            startDate: start,
            endDate: end,
            venue: venueName,
            city: city,
            status: state,
            leaderboard: leaderboard
        )
    }
}
