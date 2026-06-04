import Foundation

/// Curated comparison of premium golf balls — the recommendations
/// produced for this player's profile (14.1 handicap, ~100 mph swing,
/// push pattern, forged-iron player, PA climate). Static read-only data;
/// edit the array below to add or refine entries.
struct Ball {
    let brand: String
    let model: String
    let pieces: Int                 // 3, 4, or 5
    let cover: CoverMaterial
    let compression: Int
    let driverSpin: SpinTier
    let greensideSpin: SpinTier
    let feel: FeelTier
    let pricePerDozen: Int          // current USD MSRP / street
    let fit: FitStatus
    let bestFor: String             // one-line player fit
    let take: String                // 2–4 sentences of opinion
}

enum CoverMaterial: String {
    case urethane = "Urethane"
    case ionomer  = "Ionomer"
    case surlyn   = "Surlyn"
}

enum SpinTier: String, CaseIterable {
    case low  = "Low"
    case mid  = "Mid"
    case high = "High"
}

enum FeelTier: String, CaseIterable {
    case soft   = "Soft"
    case medium = "Medium"
    case firm   = "Firm"
}

/// Where each ball lands in the current testing plan.
enum FitStatus: String {
    case gamer     = "GAMER"        // currently in the bag
    case benchmark = "BENCHMARK"    // the standard others get judged against
    case alt       = "ALT"          // strong alternative; trial-worthy
    case sleeper   = "SLEEPER"      // less obvious pick worth trying
    case avoid     = "AVOID"        // wrong fit for this player
}

enum Balls {
    /// Display order — gamer first, then benchmark, then alts by relevance.
    static let all: [Ball] = [

        Ball(
            brand: "Legato",
            model: "LTX 3085",
            pieces: 3,
            cover: .urethane,
            compression: 85,
            driverSpin: .mid,
            greensideSpin: .high,
            feel: .soft,
            pricePerDozen: 32,
            fit: .gamer,
            bestFor: "~100 mph swings wanting tour-ball performance at half the price",
            take: "The DTC ball that genuinely competes with Pro V1 on construction (3-piece, real urethane) at $23/dozen less. 85 compression matches a ~100 mph swing speed cleanly. The one fair caveat is QC consistency vs. the majors — one reviewer noted a defective ball in 24. First gamer in current testing rotation."),

        Ball(
            brand: "Titleist",
            model: "Pro V1",
            pieces: 3,
            cover: .urethane,
            compression: 88,
            driverSpin: .mid,
            greensideSpin: .high,
            feel: .medium,
            pricePerDozen: 55,
            fit: .benchmark,
            bestFor: "Any tour-quality player — the universal-fit premium ball",
            take: "The standard the rest of the field gets measured against, and for good reason. Mid driver-spin is forgiving of off-line strikes (matters for push patterns). Decades of refinement = highest QC consistency in the category. Premium price buys predictability."),

        Ball(
            brand: "Srixon",
            model: "Z-Star",
            pieces: 3,
            cover: .urethane,
            compression: 90,
            driverSpin: .mid,
            greensideSpin: .high,
            feel: .soft,
            pricePerDozen: 45,
            fit: .alt,
            bestFor: "Pro V1 performance with softer feel for $10/dozen less",
            take: "Pro V1's quiet rival — comparable construction, comparable spin numbers, softer feel signature, $10/dozen cheaper. Many teaching pros play this and don't talk about it. The value pick within the legitimate premium tier."),

        Ball(
            brand: "Callaway",
            model: "Chrome Tour",
            pieces: 4,
            cover: .urethane,
            compression: 75,
            driverSpin: .mid,
            greensideSpin: .high,
            feel: .soft,
            pricePerDozen: 50,
            fit: .alt,
            bestFor: "Players who prefer Callaway's feel signature to Titleist's",
            take: "Comparable performance to Pro V1 with a lower-compression, softer feel. Flight is slightly lower with more rollout. Choosing between Pro V1 and Chrome Tour is mostly feel preference, not performance gap."),

        Ball(
            brand: "Mizuno",
            model: "RB Tour",
            pieces: 4,
            cover: .urethane,
            compression: 85,
            driverSpin: .mid,
            greensideSpin: .high,
            feel: .soft,
            pricePerDozen: 45,
            fit: .sleeper,
            bestFor: "Mizuno iron players — built around the forged-iron feel signature",
            take: "Engineered specifically for forged-iron players. The cover is tuned for the feel-off-the-face sensation Mizuno's iron buyers chase. Worth a sleeve as a brand-pairing experiment with the JPX 921s."),

        Ball(
            brand: "TaylorMade",
            model: "TP5",
            pieces: 5,
            cover: .urethane,
            compression: 85,
            driverSpin: .mid,
            greensideSpin: .high,
            feel: .medium,
            pricePerDozen: 55,
            fit: .alt,
            bestFor: "Players who specifically want max layers / tunability",
            take: "Five-piece construction marketed as the most tunable to swing speed. Slightly different feel than Titleist's three-piece. Cold-weather feel softens more than Pro V1 — worth knowing for spring PA rounds."),

        Ball(
            brand: "Titleist",
            model: "Pro V1x",
            pieces: 4,
            cover: .urethane,
            compression: 97,
            driverSpin: .high,
            greensideSpin: .high,
            feel: .firm,
            pricePerDozen: 55,
            fit: .avoid,
            bestFor: "High-launch, high-spin players who need more flight",
            take: "Wrong direction on every count for this profile — firmer, higher driver spin (amplifies push side-spin), higher trajectory. Save for a player who needs more height and stop on irons; this player needs less side spin off the tee."),
    ]
}
