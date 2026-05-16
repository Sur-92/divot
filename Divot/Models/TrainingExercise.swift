import Foundation
import SwiftData

// MARK: - Category

enum TrainingCategory: String, CaseIterable, Codable, Hashable, Identifiable {
    case mobility, stability, strength, power, cardio

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mobility:  return "Mobility"
        case .stability: return "Stability"
        case .strength:  return "Strength"
        case .power:     return "Power"
        case .cardio:    return "Cardio"
        }
    }

    var shortName: String {
        switch self {
        case .mobility:  return "MOBILITY"
        case .stability: return "STABILITY"
        case .strength:  return "STRENGTH"
        case .power:     return "POWER"
        case .cardio:    return "CARDIO"
        }
    }

    /// Sort order — roughly the typical session ordering (warm-up → power
    /// → strength → conditioning → cooldown).
    var sortOrder: Int {
        switch self {
        case .mobility:  return 0
        case .stability: return 1
        case .power:     return 2
        case .strength:  return 3
        case .cardio:    return 4
        }
    }
}

// MARK: - Exercise (library entry)

/// One reusable exercise definition. The library lives independently of
/// any session — sessions reference these by relationship so the
/// definition can be edited once and reflect everywhere it's used.
@Model
final class TrainingExercise {
    var name: String
    var categoryRaw: String = TrainingCategory.mobility.rawValue
    /// Body region or focus — freeform: "Hips", "Core", "T-spine", "Shoulders".
    var targetArea: String
    /// Form cues / how to perform.
    var instructions: String
    /// Required gear: "Dumbbells", "Resistance band", "Mat", "None".
    var equipment: String
    /// Default prescription — 0 means "not set, ask per-session".
    var defaultSets: Int
    var defaultReps: Int
    var defaultDurationSeconds: Int
    /// Optional URL to a tutorial video (YouTube etc).
    var videoURL: String

    var addedAt: Date
    var sortOrder: Int = 0
    var idempotencyKey: String = ""
    var isArchived: Bool = false

    var category: TrainingCategory {
        get { TrainingCategory(rawValue: categoryRaw) ?? .mobility }
        set { categoryRaw = newValue.rawValue }
    }

    init(name: String = "",
         category: TrainingCategory = .mobility,
         targetArea: String = "",
         instructions: String = "",
         equipment: String = "",
         defaultSets: Int = 0,
         defaultReps: Int = 0,
         defaultDurationSeconds: Int = 0,
         videoURL: String = "",
         addedAt: Date = .now,
         sortOrder: Int = 0) {
        self.name = name
        self.categoryRaw = category.rawValue
        self.targetArea = targetArea
        self.instructions = instructions
        self.equipment = equipment
        self.defaultSets = defaultSets
        self.defaultReps = defaultReps
        self.defaultDurationSeconds = defaultDurationSeconds
        self.videoURL = videoURL
        self.addedAt = addedAt
        self.sortOrder = sortOrder
        self.idempotencyKey = UUID().uuidString
    }

    var displayTitle: String {
        name.isEmpty ? "Untitled exercise" : name
    }

    /// One-line prescription summary for the library row.
    /// e.g. "3 × 12", "3 × 30s", "5 × 5 @ form".
    var prescriptionSummary: String {
        var parts: [String] = []
        if defaultSets > 0 { parts.append("\(defaultSets)") }
        if defaultReps > 0 { parts.append("× \(defaultReps)") }
        if defaultDurationSeconds > 0 {
            parts.append(parts.isEmpty ? "\(defaultDurationSeconds)s" : "× \(defaultDurationSeconds)s")
        }
        return parts.joined(separator: " ")
    }
}
