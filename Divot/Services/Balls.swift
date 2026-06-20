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
            brand: "Srixon",
            model: "Q-Star Tour",
            pieces: 3,
            cover: .urethane,
            compression: 74,
            driverSpin: .mid,
            greensideSpin: .high,
            feel: .soft,
            pricePerDozen: 40,
            fit: .alt,
            bestFor: "~100 mph swings wanting urethane spin at a softer compression than Z-Star",
            take: "The Z-Star's softer, cheaper sibling — same urethane greenside grip and Spin Skin+ coating, but 74 compression that arguably suits a ~100 mph swing better than the firmer Z-Star (90). Mid flight, full greenside spin, $40/dozen. One of the strongest balanced-ball values in the field and a real rival to the Legato on feel. (\"Q-Star\" now means the Tour; the old plain distance Q-Star is the Q-Star UltiSpeed.)"),

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
            brand: "Bridgestone",
            model: "e12 Contact",
            pieces: 3,
            cover: .ionomer,
            compression: 61,
            driverSpin: .low,
            greensideSpin: .low,
            feel: .soft,
            pricePerDozen: 30,
            fit: .alt,
            bestFor: "Push / slice players who'll trade greenside bite for the straightest flight",
            take: "The e12's whole identity is straight flight — low driver spin and the Contact Force Dimple cut sidespin, which directly counters a push off the tee. Genuinely relevant to your miss. The catch is the ionomer cover: greenside spin is a clear step below the urethane balls here, so wedges release more. The opposite tradeoff from the Legato — pick it if tee-to-fairway accuracy matters to you more than stop-on-the-green spin. (This is the straight-flight e12; current model name is \"e12 Contact.\")"),

        Ball(
            brand: "Callaway",
            model: "Supersoft",
            pieces: 2,
            cover: .ionomer,
            compression: 38,
            driverSpin: .low,
            greensideSpin: .low,
            feel: .soft,
            pricePerDozen: 20,
            fit: .alt,
            bestFor: "Slower swings & feel-seekers who want soft + straight on a budget",
            take: "The softest, cheapest ball in the lineup — a 2-piece Trionomer (ionomer) distance ball at 38 compression, one of the lowest made. Marshmallow-soft feel, very low driver spin (straight, slice-resistant), and big value at $20. The honest caveat for YOUR game: it's built for slower swing speeds than your ~100 mph, and the ionomer cover gives the least greenside spin in the whole matrix — which trades away exactly the wedge bite your scramble-heavy scoring leans on. Great soft-feel value ball; not the one for a player whose short game is the engine."),

        Ball(
            brand: "Vice",
            model: "Pro Plus",
            pieces: 4,
            cover: .urethane,
            compression: 89,
            driverSpin: .mid,
            greensideSpin: .high,
            feel: .medium,
            pricePerDozen: 35,
            fit: .alt,
            bestFor: "A firmer, higher-launching urethane tour ball at DTC pricing",
            take: "Vice's firmest tour ball — 4-piece urethane, higher launch and a touch more spin than the standard Pro, with full greenside bite at ~$35/dozen direct. A little firm for a ~100 mph swing; the Pro is the softer-feeling sibling."),

        Ball(
            brand: "Vice",
            model: "Pro",
            pieces: 3,
            cover: .urethane,
            compression: 80,
            driverSpin: .mid,
            greensideSpin: .high,
            feel: .soft,
            pricePerDozen: 30,
            fit: .alt,
            bestFor: "Soft-feel urethane tour performance at a DTC discount",
            take: "The sweet spot of the Vice line — 3-piece urethane, soft feel, full greenside spin, ~$30/dozen. Reads like a Z-Star / Q-Star Tour rival on a budget; a legitimately strong balanced pick."),

        Ball(
            brand: "Vice",
            model: "Drive",
            pieces: 2,
            cover: .surlyn,
            compression: 60,
            driverSpin: .low,
            greensideSpin: .low,
            feel: .soft,
            pricePerDozen: 20,
            fit: .alt,
            bestFor: "Cheap, durable, straight — a practice / casual distance ball",
            take: "Vice's 2-piece Surlyn value ball — durable, low spin both ends, ~$20. Fine for the range or a casual loop, but the hard cover gives up the wedge control your scoring leans on."),

        Ball(
            brand: "TaylorMade",
            model: "TP5x",
            pieces: 5,
            cover: .urethane,
            compression: 97,
            driverSpin: .high,
            greensideSpin: .high,
            feel: .firm,
            pricePerDozen: 55,
            fit: .avoid,
            bestFor: "High-swing-speed players who want maximum launch + spin",
            take: "The firm, high-spin 'x' sibling of the TP5 — 5-piece urethane at 97 compression. Great if you need more height and stop, but for a push pattern the extra driver spin amplifies the curve. Wrong direction for you, same logic as the Pro V1x."),

        Ball(
            brand: "TaylorMade",
            model: "Tour Response",
            pieces: 3,
            cover: .urethane,
            compression: 70,
            driverSpin: .mid,
            greensideSpin: .high,
            feel: .soft,
            pricePerDozen: 40,
            fit: .alt,
            bestFor: "Soft urethane spin at a sensible price; fits ~100 mph swings",
            take: "TaylorMade's value urethane ball — 3-piece, 70 compression, soft feel, full greenside grip at ~$40. The low compression suits your swing speed and the urethane keeps the wedge bite your game needs. A genuinely good balanced option."),

        Ball(
            brand: "TaylorMade",
            model: "Distance+",
            pieces: 2,
            cover: .ionomer,
            compression: 77,
            driverSpin: .low,
            greensideSpin: .low,
            feel: .medium,
            pricePerDozen: 20,
            fit: .alt,
            bestFor: "Maximum distance + low spin on a budget",
            take: "2-piece ionomer distance ball, ~$20. Low spin runs straighter off the tee, but the cover gives up greenside control — a value/distance play, not a scoring ball for a short-game-driven golfer."),

        Ball(
            brand: "Top-Flite",
            model: "Gamer",
            pieces: 3,
            cover: .ionomer,
            compression: 60,
            driverSpin: .low,
            greensideSpin: .low,
            feel: .soft,
            pricePerDozen: 15,
            fit: .alt,
            bestFor: "Budget soft-feel all-rounder",
            take: "Top-Flite's softer 'tour-style' value ball — ionomer cover, soft feel, ~$15/dozen. Pleasant off the face and dirt-cheap, but greenside spin sits well below the urethane balls. A casual/value option."),

        Ball(
            brand: "Top-Flite",
            model: "XL Distance",
            pieces: 2,
            cover: .surlyn,
            compression: 90,
            driverSpin: .low,
            greensideSpin: .low,
            feel: .firm,
            pricePerDozen: 15,
            fit: .avoid,
            bestFor: "Pure distance at the lowest price",
            take: "About as basic as it gets — 2-piece Surlyn, firm, built only for distance and durability at ~$15. The least greenside spin in the matrix; for a player who scrambles to score, it works directly against you. Range fodder."),

        Ball(
            brand: "OnCore",
            model: "VERO X1",
            pieces: 3,
            cover: .urethane,
            compression: 108,
            driverSpin: .mid,
            greensideSpin: .high,
            feel: .firm,
            pricePerDozen: 45,
            fit: .sleeper,
            bestFor: "Curiosity pick — a boutique tech-brand premium urethane ball",
            take: "From OnCore, one of golf's genuine boutique/tech brands — 3-piece urethane with high greenside spin and a notably firm 108 compression at ~$45. The spin suits your short game, but 108 is firm for a ~100 mph swing; a fun trial, not an obvious daily."),

        Ball(
            brand: "Volvik",
            model: "Vivid",
            pieces: 3,
            cover: .ionomer,
            compression: 80,
            driverSpin: .low,
            greensideSpin: .low,
            feel: .soft,
            pricePerDozen: 25,
            fit: .alt,
            bestFor: "The fun one — matte-colored novelty with respectable performance",
            take: "Volvik's famous matte-colored ball — 3-piece ionomer, soft, ~$25, and nearly impossible to lose in the rough. More novelty/distance than scoring ball (greenside spin is modest), but genuinely fun and the most 'exotic'-looking thing you could put in play."),

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
