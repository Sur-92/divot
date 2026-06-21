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
    // 1–6 scales (finer than the old 3 tiers), estimated from compression,
    // cover, and robot-test / review data on relative performance:
    let driverSpin: Int             // 1 = lowest driver spin … 6 = highest
    let greensideSpin: Int          // 1 = least wedge bite … 6 = most
    let feel: Int                   // 1 = softest … 6 = firmest
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
            driverSpin: 3,
            greensideSpin: 5,
            feel: 4,
            pricePerDozen: 32,
            fit: .gamer,
            bestFor: "~100 mph swings wanting tour-ball performance at half the price",
            take: "The DTC ball that genuinely competes with Pro V1 on construction (3-piece, real urethane) at $23/dozen less. 85 compression matches a ~100 mph swing speed cleanly. The one fair caveat is QC consistency vs. the majors — one reviewer noted a defective ball in 24. First gamer in current testing rotation."),

        Ball(
            brand: "Titleist",
            model: "Pro V1",
            pieces: 3,
            cover: .urethane,
            compression: 90,
            driverSpin: 4,
            greensideSpin: 6,
            feel: 4,
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
            driverSpin: 5,
            greensideSpin: 6,
            feel: 4,
            pricePerDozen: 45,
            fit: .alt,
            bestFor: "Pro V1 performance with softer feel for $10/dozen less",
            take: "Pro V1's quiet rival — comparable construction, comparable spin numbers, softer feel signature, $10/dozen cheaper. Many teaching pros play this and don't talk about it. The value pick within the legitimate premium tier."),

        Ball(
            brand: "Srixon",
            model: "Q-Star Tour",
            pieces: 3,
            cover: .urethane,
            compression: 70,
            driverSpin: 3,
            greensideSpin: 5,
            feel: 3,
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
            driverSpin: 3,
            greensideSpin: 6,
            feel: 3,
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
            driverSpin: 4,
            greensideSpin: 5,
            feel: 4,
            pricePerDozen: 45,
            fit: .sleeper,
            bestFor: "Mizuno iron players — built around the forged-iron feel signature",
            take: "Engineered specifically for forged-iron players. The cover is tuned for the feel-off-the-face sensation Mizuno's iron buyers chase. Worth a sleeve as a brand-pairing experiment with the JPX 921s."),

        Ball(
            brand: "TaylorMade",
            model: "TP5",
            pieces: 5,
            cover: .urethane,
            compression: 80,
            driverSpin: 4,
            greensideSpin: 6,
            feel: 4,
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
            driverSpin: 2,
            greensideSpin: 3,
            feel: 3,
            pricePerDozen: 30,
            fit: .alt,
            bestFor: "Push / slice players who'll trade greenside bite for the straightest flight",
            take: "The e12's whole identity is straight flight — low driver spin and the Contact Force Dimple cut sidespin, which directly counters a push off the tee. Genuinely relevant to your miss. The catch is the ionomer cover: greenside spin is a clear step below the urethane balls here, so wedges release more. The opposite tradeoff from the Legato — pick it if tee-to-fairway accuracy matters to you more than stop-on-the-green spin. (This is the straight-flight e12; current model name is \"e12 Contact.\")"),

        Ball(
            brand: "Callaway",
            model: "Supersoft",
            pieces: 2,
            cover: .ionomer,
            compression: 40,
            driverSpin: 1,
            greensideSpin: 2,
            feel: 1,
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
            driverSpin: 4,
            greensideSpin: 5,
            feel: 4,
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
            driverSpin: 4,
            greensideSpin: 5,
            feel: 3,
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
            driverSpin: 2,
            greensideSpin: 2,
            feel: 2,
            pricePerDozen: 20,
            fit: .alt,
            bestFor: "Cheap, durable, straight — a practice / casual distance ball",
            take: "Vice's 2-piece Surlyn value ball — durable, low spin both ends, ~$20. Fine for the range or a casual loop, but the hard cover gives up the wedge control your scoring leans on."),

        Ball(
            brand: "TaylorMade",
            model: "TP5x",
            pieces: 5,
            cover: .urethane,
            compression: 90,
            driverSpin: 3,
            greensideSpin: 6,
            feel: 4,
            pricePerDozen: 55,
            fit: .alt,
            bestFor: "Players wanting the highest flight + most iron spin from a tour ball",
            take: "The data flipped my read here: in MyGolfSpy's 2025 robot test the TP5x had the LOWEST driver spin of the whole field (2,524 rpm) — the opposite of the \"high-spin x ball\" reputation. The five-piece build sheds driver spin while keeping high iron/wedge spin and a towering flight. At a measured 90 compression it's firmer than the TP5 but not harsh. Low tee-spin actually suits a push; worth a sleeve."),

        Ball(
            brand: "TaylorMade",
            model: "Tour Response",
            pieces: 3,
            cover: .urethane,
            compression: 70,
            driverSpin: 3,
            greensideSpin: 5,
            feel: 2,
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
            driverSpin: 2,
            greensideSpin: 2,
            feel: 4,
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
            driverSpin: 2,
            greensideSpin: 2,
            feel: 2,
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
            driverSpin: 1,
            greensideSpin: 1,
            feel: 5,
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
            driverSpin: 4,
            greensideSpin: 5,
            feel: 6,
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
            driverSpin: 3,
            greensideSpin: 2,
            feel: 3,
            pricePerDozen: 25,
            fit: .alt,
            bestFor: "The fun one — matte-colored novelty with respectable performance",
            take: "Volvik's famous matte-colored ball — 3-piece ionomer, soft, ~$25, and nearly impossible to lose in the rough. More novelty/distance than scoring ball (greenside spin is modest), but genuinely fun and the most 'exotic'-looking thing you could put in play."),

        // ===== Top-4-per-manufacturer expansion =====
        // Compression from the Golf Sidekick chart where listed; driver spin
        // from MyGolfSpy's 2025 robot test where the model was tested
        // (noted inline); other values estimated from cover + construction.

        Ball(
            brand: "Titleist",
            model: "AVX",
            pieces: 3,
            cover: .urethane,
            compression: 80,
            driverSpin: 3,
            greensideSpin: 5,
            feel: 3,
            pricePerDozen: 50,
            fit: .sleeper,
            bestFor: "Low-spin, soft, straight urethane — a quietly ideal fit for a push pattern",
            take: "Titleist's low-spin, low-flight tour ball, and on paper the closest thing in this matrix to your spec: low driver spin to fight the push, soft 80-compression feel, and real urethane greenside bite. The under-the-radar pick worth a sleeve — it does what the Supersoft does off the tee without surrendering the 60–100 yard check."),

        Ball(
            brand: "Titleist",
            model: "Tour Speed",
            pieces: 3,
            cover: .urethane,
            compression: 80,
            driverSpin: 4,
            greensideSpin: 4,
            feel: 3,
            pricePerDozen: 40,
            fit: .alt,
            bestFor: "Distance-leaning urethane a step below Pro V1 money",
            take: "A faster, firmer-flying urethane positioned under the Pro V1 line. Decent greenside for the price, but a touch more driver spin and less bite than the AVX — more of a distance play with a soft cover."),

        Ball(
            brand: "Srixon",
            model: "Z-Star XV",
            pieces: 4,
            cover: .urethane,
            compression: 100,
            driverSpin: 4,
            greensideSpin: 6,
            feel: 5,
            pricePerDozen: 45,
            fit: .alt,
            bestFor: "Higher swing speeds wanting high flight + maximum spin",
            take: "The firmer, higher-launching, higher-spinning sibling of the Z-Star — measured 2,766 rpm off the driver in MyGolfSpy's test. At 100 compression it's firm for a ~100 mph swing; the standard Z-Star suits you better."),

        Ball(
            brand: "Srixon",
            model: "Soft Feel",
            pieces: 2,
            cover: .ionomer,
            compression: 60,
            driverSpin: 2,
            greensideSpin: 2,
            feel: 2,
            pricePerDozen: 23,
            fit: .alt,
            bestFor: "Slower-swing / soft-feel players on a budget",
            take: "A 2-piece ionomer value ball — soft, straight, cheap, low-spinning both ends. The same tradeoff as the Supersoft: pleasant and forgiving, but gives up the greenside bite your short game uses."),

        Ball(
            brand: "Callaway",
            model: "Chrome Tour X",
            pieces: 4,
            cover: .urethane,
            compression: 90,
            driverSpin: 4,
            greensideSpin: 6,
            feel: 5,
            pricePerDozen: 55,
            fit: .alt,
            bestFor: "Players wanting Chrome Tour spin with a firmer feel + higher flight",
            take: "The firmer, higher-spin 'X' of the Chrome Tour — more iron spin and a taller flight at 90 compression. Premium performance, but firmer and a touch much driver spin for a push; the standard Chrome Tour is the better match."),

        Ball(
            brand: "Callaway",
            model: "ERC Soft",
            pieces: 3,
            cover: .ionomer,
            compression: 60,
            driverSpin: 2,
            greensideSpin: 3,
            feel: 2,
            pricePerDozen: 33,
            fit: .alt,
            bestFor: "Soft distance with Triple Track alignment help",
            take: "A soft, fast distance ball with a hybrid cover that grabs a little more than pure ionomer, plus the Triple Track alignment lines. Greenside is a notch above the Supersoft but still well short of urethane."),

        Ball(
            brand: "Bridgestone",
            model: "Tour B X",
            pieces: 3,
            cover: .urethane,
            compression: 85,
            driverSpin: 5,
            greensideSpin: 6,
            feel: 4,
            pricePerDozen: 50,
            fit: .alt,
            bestFor: "~105+ mph swings wanting low long-game spin with iron bite",
            take: "A premium urethane ball built around mid/high swing speeds that measured a high 2,892 rpm off the driver in MyGolfSpy's test — more tee spin than ideal for your push. Elite greenside, but the long-game spin works against your miss."),

        Ball(
            brand: "Bridgestone",
            model: "Tour B XS",
            pieces: 3,
            cover: .urethane,
            compression: 85,
            driverSpin: 5,
            greensideSpin: 6,
            feel: 4,
            pricePerDozen: 50,
            fit: .alt,
            bestFor: "Players chasing maximum greenside spin and soft urethane feel",
            take: "Tiger's gamer — the softer, max-spin sibling of the Tour B X (measured 2,844 rpm driver). Outstanding greenside bite and feel, but like the X it spins more off the tee than your push wants."),

        Ball(
            brand: "Bridgestone",
            model: "e6",
            pieces: 2,
            cover: .surlyn,
            compression: 45,
            driverSpin: 2,
            greensideSpin: 2,
            feel: 2,
            pricePerDozen: 23,
            fit: .alt,
            bestFor: "Soft, straight, low-spin distance on a budget",
            take: "A soft 2-piece built for straight, low-spin flight — the Supersoft's Bridgestone cousin. Same story: friendly off the tee, light on greenside."),

        Ball(
            brand: "Mizuno",
            model: "RB Tour X",
            pieces: 4,
            cover: .urethane,
            compression: 110,
            driverSpin: 4,
            greensideSpin: 6,
            feel: 6,
            pricePerDozen: 45,
            fit: .alt,
            bestFor: "Fast swings wanting the firmest, highest-flying Mizuno tour ball",
            take: "The firmest ball in the whole matrix at a measured 110 compression — built for high swing speeds. Superb urethane greenside, but far too firm to compress or feel well at ~100 mph."),

        Ball(
            brand: "Mizuno",
            model: "RB 566",
            pieces: 2,
            cover: .ionomer,
            compression: 75,
            driverSpin: 2,
            greensideSpin: 2,
            feel: 3,
            pricePerDozen: 22,
            fit: .alt,
            bestFor: "Straight distance via the 566-dimple low-drag design",
            take: "A 2-piece distance ball whose 566 micro-dimples cut drag for a straighter, lower-spin flight. A value/distance option, not a scoring ball. (Compression estimated.)"),

        Ball(
            brand: "Mizuno",
            model: "RB 566V",
            pieces: 3,
            cover: .ionomer,
            compression: 80,
            driverSpin: 2,
            greensideSpin: 3,
            feel: 3,
            pricePerDozen: 25,
            fit: .alt,
            bestFor: "A softer, 3-piece step up from the RB 566",
            take: "The 3-piece 'V' adds a softer cover and a bit more greenside than the RB 566, still in the value/distance lane. A notch below urethane on bite. (Compression estimated.)"),

        Ball(
            brand: "Vice",
            model: "Pro Soft",
            pieces: 3,
            cover: .urethane,
            compression: 45,
            driverSpin: 3,
            greensideSpin: 5,
            feel: 2,
            pricePerDozen: 30,
            fit: .alt,
            bestFor: "Supersoft-soft feel but with real urethane greenside spin",
            take: "Vice's softest urethane — close to Supersoft softness off the face, but with a cover that actually checks. Right in your wheelhouse: soft, low-ish driver spin, real bite, DTC price. (Compression estimated.)"),

        Ball(
            brand: "OnCore",
            model: "VERO X2",
            pieces: 4,
            cover: .urethane,
            compression: 100,
            driverSpin: 4,
            greensideSpin: 6,
            feel: 5,
            pricePerDozen: 45,
            fit: .alt,
            bestFor: "Boutique-brand premium tour performance",
            take: "The newer 4-piece evolution of the VERO X1 from boutique maker OnCore — premium urethane with high greenside spin and a firm feel. A curiosity pick; firm for your speed. (Compression estimated.)"),

        Ball(
            brand: "OnCore",
            model: "ELIXR",
            pieces: 3,
            cover: .urethane,
            compression: 85,
            driverSpin: 3,
            greensideSpin: 5,
            feel: 4,
            pricePerDozen: 35,
            fit: .alt,
            bestFor: "OnCore's softer, value-priced tour ball",
            take: "OnCore's all-around tour ball — softer and cheaper than the VERO line, with solid urethane greenside. A reasonable boutique value. (Compression estimated.)"),

        Ball(
            brand: "OnCore",
            model: "Avant 64",
            pieces: 2,
            cover: .ionomer,
            compression: 64,
            driverSpin: 2,
            greensideSpin: 2,
            feel: 3,
            pricePerDozen: 25,
            fit: .alt,
            bestFor: "Soft 2-piece distance with a low 64 compression",
            take: "OnCore's value distance ball — the '64' is its compression, soft for a 2-piece. Straight and forgiving, but ionomer greenside; a budget option, not a scorer."),

        Ball(
            brand: "Volvik",
            model: "S4",
            pieces: 4,
            cover: .urethane,
            compression: 95,
            driverSpin: 4,
            greensideSpin: 5,
            feel: 5,
            pricePerDozen: 40,
            fit: .alt,
            bestFor: "Tour performance in Volvik's signature colors",
            take: "Volvik's 4-piece urethane flagship — genuine tour construction in the brand's bold colors. Firm at 95 compression and high-spinning; a real ball if you want color, but firm for your swing."),

        Ball(
            brand: "Volvik",
            model: "S3",
            pieces: 3,
            cover: .urethane,
            compression: 85,
            driverSpin: 3,
            greensideSpin: 5,
            feel: 4,
            pricePerDozen: 33,
            fit: .alt,
            bestFor: "A softer, 3-piece colored urethane below the S4",
            take: "The 3-piece S3 is softer and easier to compress than the S4 while keeping urethane greenside — the more sensible Volvik for a ~100 mph swing, still in colors."),

        Ball(
            brand: "Volvik",
            model: "Power Soft",
            pieces: 3,
            cover: .ionomer,
            compression: 70,
            driverSpin: 2,
            greensideSpin: 2,
            feel: 3,
            pricePerDozen: 22,
            fit: .alt,
            bestFor: "Soft colored distance on a budget",
            take: "A soft ionomer distance ball in Volvik colors — straight and pleasant, but greenside lands in Supersoft territory. Value/novelty, not a scoring ball."),

        Ball(
            brand: "Top-Flite",
            model: "D2 Feel",
            pieces: 2,
            cover: .ionomer,
            compression: 50,
            driverSpin: 2,
            greensideSpin: 2,
            feel: 2,
            pricePerDozen: 15,
            fit: .alt,
            bestFor: "Rock-bottom price with a soft cover",
            take: "Dick's house-brand soft distance ball — cheap and pleasant off the face, minimal greenside. Pure value. (Compression estimated.)"),

        Ball(
            brand: "Top-Flite",
            model: "D2 Distance",
            pieces: 2,
            cover: .surlyn,
            compression: 90,
            driverSpin: 1,
            greensideSpin: 1,
            feel: 5,
            pricePerDozen: 15,
            fit: .avoid,
            bestFor: "Maximum distance and durability at the lowest price",
            take: "A firm 2-piece Surlyn distance rock — built only to fly straight and far and survive cart paths. Lowest greenside in the matrix alongside the XL Distance; wrong fit for a short-game player. (Compression estimated.)"),

        Ball(
            brand: "Titleist",
            model: "Pro V1x",
            pieces: 4,
            cover: .urethane,
            compression: 100,
            driverSpin: 4,
            greensideSpin: 6,
            feel: 5,
            pricePerDozen: 55,
            fit: .alt,
            bestFor: "Players wanting higher iron flight + more stopping power, who can handle a firm ball",
            take: "Correcting an earlier call: MyGolfSpy's 2025 robot test clocked the Pro V1x at 2,680 rpm off the driver (mid-pack, not high) with the most neutral spin axis in the field — so the \"high driver spin amplifies your push\" knock was wrong. The real caveat is firmness: at a measured 100 compression it's the firmest urethane ball here, a bit much for a ~100 mph swing, and it's premium-priced. Higher flight and elite greenside bite make it a legit trial, not an avoid."),
    ]
}
