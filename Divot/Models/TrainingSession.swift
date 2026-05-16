import Foundation
import SwiftData

// MARK: - Session

/// One logged training workout. A session has a date, an optional name
/// (e.g. "Pre-round warm-up", "Tuesday strength"), free-form notes, and
/// a list of `PerformedExercise` rows recording what the player actually
/// did — exercises, sets, reps, weights, holds.
@Model
final class TrainingSession {
    var date: Date
    var name: String
    var notes: String
    /// Total session duration in minutes. 0 = unspecified.
    var durationMinutes: Int

    var idempotencyKey: String = ""
    var isArchived: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \PerformedExercise.session)
    var performances: [PerformedExercise] = []

    init(date: Date = .now,
         name: String = "",
         notes: String = "",
         durationMinutes: Int = 0) {
        self.date = date
        self.name = name
        self.notes = notes
        self.durationMinutes = durationMinutes
        self.idempotencyKey = UUID().uuidString
    }

    var sortedPerformances: [PerformedExercise] {
        performances.sorted { $0.order < $1.order }
    }

    var displayTitle: String {
        if !name.isEmpty { return name }
        return "Training · \(date.formatted(date: .abbreviated, time: .omitted))"
    }

    /// Compact summary like "5 exercises · 28 min".
    var summaryLine: String {
        let count = performances.count
        let exerciseLabel = "\(count) exercise" + (count == 1 ? "" : "s")
        if durationMinutes > 0 {
            return "\(exerciseLabel) · \(durationMinutes) min"
        }
        return exerciseLabel
    }
}

// MARK: - PerformedExercise

/// A single exercise as it was performed inside one session: the
/// reference to the library exercise, plus the actual sets/reps/weight
/// the player did. Stored separately from `TrainingExercise` so editing
/// a library entry's defaults doesn't retroactively rewrite history.
@Model
final class PerformedExercise {
    var session: TrainingSession?
    var exercise: TrainingExercise?

    /// Order of this performance within the session (0-based).
    var order: Int = 0

    var sets: Int
    var reps: Int
    var weightLbs: Double
    /// Hold or cardio duration. 0 if not timed.
    var durationSeconds: Int
    var notes: String

    var idempotencyKey: String = ""

    init(session: TrainingSession? = nil,
         exercise: TrainingExercise? = nil,
         order: Int = 0,
         sets: Int = 0,
         reps: Int = 0,
         weightLbs: Double = 0,
         durationSeconds: Int = 0,
         notes: String = "") {
        self.session = session
        self.exercise = exercise
        self.order = order
        self.sets = sets
        self.reps = reps
        self.weightLbs = weightLbs
        self.durationSeconds = durationSeconds
        self.notes = notes
        self.idempotencyKey = UUID().uuidString
    }

    /// Compact prescription summary like "3 × 12 @ 25 lb" or "2 × 30s".
    var summary: String {
        var parts: [String] = []
        if sets > 0 { parts.append("\(sets)") }
        if reps > 0 { parts.append("× \(reps)") }
        if durationSeconds > 0 {
            parts.append(parts.isEmpty ? "\(durationSeconds)s" : "× \(durationSeconds)s")
        }
        if weightLbs > 0 {
            parts.append("@ \(formatWeight(weightLbs))")
        }
        return parts.joined(separator: " ")
    }

    private func formatWeight(_ w: Double) -> String {
        let rounded = (w * 10).rounded() / 10
        let s = rounded.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", rounded)
            : String(format: "%.1f", rounded)
        return "\(s) lb"
    }
}
