import Foundation

/// Everything captured about ONE nine of a round beyond the score: course
/// surface, the situation, and the player's own state. Persisted as JSON in
/// a String column on `Round` (front/back) — TEXT is SQLite-safe (unlike the
/// array-blob columns) and tolerant of schema growth: add a field here and
/// old rows decode with its default, no migration needed.
///
/// Graded values: 0 = unset (not recorded), 1 / 2 / 3 = the three levels.
/// Checkboxes default false. A clean round needs zero input — defaults read
/// as "nothing notable."
struct NineConditions: Codable, Equatable {
    // Graded (3-way) — 0 = unset
    var greenSpeed = 0
    var greenFirmness = 0
    var fairways = 0
    var rough = 0
    var pace = 0
    var feel = 0
    var anxiety = 0

    // Checkboxes
    var greensBumpy = false
    var greensSanded = false
    var poorBunkers = false
    var cartPathOnly = false
    var casualWater = false
    var leavesDown = false
    var frostDelay = false
    var backedUp = false
    var solo = false
    var familiarGroup = false
    var strangers = false
    var socialPressure = false
    var tired = false

    /// True when nothing has been recorded for this nine.
    var isEmpty: Bool {
        greenSpeed == 0 && greenFirmness == 0 && fairways == 0 && rough == 0
            && pace == 0 && feel == 0 && anxiety == 0
            && !greensBumpy && !greensSanded && !poorBunkers && !cartPathOnly
            && !casualWater && !leavesDown && !frostDelay && !backedUp
            && !solo && !familiarGroup && !strangers && !socialPressure && !tired
    }
}

/// Display grouping for the conditions editor.
enum ConditionCategory: String, CaseIterable, Identifiable {
    case greens      = "Greens"
    case turf        = "Turf"
    case maintenance = "Maintenance"
    case pace        = "Pace"
    case social      = "Social"
    case state       = "Your State"
    var id: String { rawValue }
}

/// A 3-way graded condition: which struct field, its label, the three option
/// labels, and the category it renders under.
struct GradedSpec: Identifiable {
    let id: String
    let label: String
    let keyPath: WritableKeyPath<NineConditions, Int>
    let options: [String]   // exactly three
    let category: ConditionCategory
}

/// A checkbox condition.
struct FlagSpec: Identifiable {
    let id: String
    let label: String
    let keyPath: WritableKeyPath<NineConditions, Bool>
    let category: ConditionCategory
}

/// The single source of truth for which conditions exist and how they render.
/// Add an entry here (and a field on `NineConditions`) to add a condition.
enum ConditionsCatalog {
    static let graded: [GradedSpec] = [
        .init(id: "greenSpeed",   label: "Speed",    keyPath: \.greenSpeed,   options: ["Slow", "Med", "Fast"],            category: .greens),
        .init(id: "greenFirm",    label: "Firmness", keyPath: \.greenFirmness,options: ["Soft", "Med", "Firm"],            category: .greens),
        .init(id: "fairways",     label: "Fairways", keyPath: \.fairways,     options: ["Wet", "Normal", "Firm"],          category: .turf),
        .init(id: "rough",        label: "Rough",    keyPath: \.rough,        options: ["Light", "Med", "Heavy"],          category: .turf),
        .init(id: "pace",         label: "Pace",     keyPath: \.pace,         options: ["Quick", "Normal", "Slow"],        category: .pace),
        .init(id: "feel",         label: "Feel",     keyPath: \.feel,         options: ["Struggling", "Average", "Locked"],category: .state),
        .init(id: "anxiety",      label: "Anxiety",  keyPath: \.anxiety,      options: ["Calm", "Nerves", "High"],         category: .state),
    ]

    static let flags: [FlagSpec] = [
        .init(id: "greensBumpy",   label: "Bumpy",                 keyPath: \.greensBumpy,    category: .greens),
        .init(id: "greensSanded",  label: "Recently sanded",       keyPath: \.greensSanded,   category: .greens),
        .init(id: "poorBunkers",   label: "Poor bunkers",          keyPath: \.poorBunkers,    category: .turf),
        .init(id: "cartPathOnly",  label: "Cart-path-only",        keyPath: \.cartPathOnly,   category: .maintenance),
        .init(id: "casualWater",   label: "Casual water / wet",    keyPath: \.casualWater,    category: .maintenance),
        .init(id: "leavesDown",    label: "Leaves down",           keyPath: \.leavesDown,     category: .maintenance),
        .init(id: "frostDelay",    label: "Frost delay",           keyPath: \.frostDelay,     category: .maintenance),
        .init(id: "backedUp",      label: "Backed up / waited",    keyPath: \.backedUp,       category: .pace),
        .init(id: "solo",          label: "Solo",                  keyPath: \.solo,           category: .social),
        .init(id: "familiarGroup", label: "Familiar group",        keyPath: \.familiarGroup,  category: .social),
        .init(id: "strangers",     label: "Paired w/ strangers",   keyPath: \.strangers,      category: .social),
        .init(id: "socialPressure",label: "Felt social pressure",  keyPath: \.socialPressure, category: .social),
        .init(id: "tired",         label: "Tired / low energy",    keyPath: \.tired,          category: .state),
    ]

    static func graded(in cat: ConditionCategory) -> [GradedSpec] { graded.filter { $0.category == cat } }
    static func flags(in cat: ConditionCategory) -> [FlagSpec] { flags.filter { $0.category == cat } }
}
