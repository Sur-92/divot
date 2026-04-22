import Foundation

/// Snapshot of the Official World Golf Rankings top 50.
/// Source: ESPN (`espn.com/golf/rankings`) — updated manually.
/// Keys are normalized player names (lowercased, accents stripped).
enum WorldRankings {
    /// Last refresh date — bump when the snapshot below is updated.
    static let lastUpdated = "2026-04-18"

    private static let raw: [String: Int] = [
        "scottie scheffler":  1,
        "rory mcilroy":       2,
        "cameron young":      3,
        "justin rose":        4,
        "tommy fleetwood":    5,
        "russell henley":     6,
        "matt fitzpatrick":   7,
        "collin morikawa":    8,
        "xander schauffele":  9,
        "j.j. spaun":        10,
        "chris gotterup":    11,
        "robert macintyre":  12,
        "sepp straka":       13,
        "hideki matsuyama":  14,
        "justin thomas":     15,
        "ben griffin":       16,
        "ludvig aberg":      17,
        "jacob bridgeman":   18,
        "alex noren":        19,
        "patrick reed":      20,
        "harris english":    21,
        "viktor hovland":    22,
        "tyrrell hatton":    23,
        "akshay bhatia":     24,
        "bryson dechambeau": 25,
        "keegan bradley":    26,
        "min woo lee":       27,
        "sam burns":         28,
        "maverick mcnealy":  29,
        "si woo kim":        30,
        "jon rahm":          31,
        "ryan gerard":       32,
        "patrick cantlay":   33,
        "shane lowry":       34,
        "kurt kitayama":     35,
        "jake knapp":        36,
        "marco penge":       37,
        "nicolai hojgaard":  38,
        "jason day":         39,
        "daniel berger":     40,
        "aaron rai":         41,
        "nico echavarria":   42,
        "corey conners":     43,
        "michael kim":       44,
        "sam stevens":       45,
        "kristoffer reitan": 46,
        "michael brennan":   47,
        "matt mccarty":      48,
        "gary woodland":     49,
        "brian harman":      50
    ]

    /// Returns the world ranking for a player name, or nil if unranked
    /// or outside the top 50 snapshot. Name matching is diacritic- and
    /// case-insensitive so "Ludvig Åberg" matches "ludvig aberg".
    static func rank(for playerName: String) -> Int? {
        let key = normalize(playerName)
        if let r = raw[key] { return r }
        // Fallback: match on "first.last" style keys where the feed might
        // give initials like "J. J. Spaun"
        let collapsed = key.replacingOccurrences(of: " ", with: "")
        for (k, v) in raw where k.replacingOccurrences(of: " ", with: "") == collapsed {
            return v
        }
        return nil
    }

    private static func normalize(_ s: String) -> String {
        s.folding(options: .diacriticInsensitive, locale: .current)
         .lowercased()
         .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
