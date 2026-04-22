import Foundation
import SwiftData

// MARK: - Practice type

enum PracticeType: String, CaseIterable, Codable, Hashable, Identifiable {
    case drivingRange
    case indoorSim
    case putting
    case chipping
    case fullSwing
    case lesson
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .drivingRange: return "Driving Range"
        case .indoorSim:    return "Indoor Sim"
        case .putting:      return "Putting"
        case .chipping:     return "Chipping"
        case .fullSwing:    return "Full Swing"
        case .lesson:       return "Lesson"
        case .other:        return "Other"
        }
    }

    var shortName: String {
        switch self {
        case .drivingRange: return "RANGE"
        case .indoorSim:    return "INDOOR"
        case .putting:      return "PUTT"
        case .chipping:     return "CHIP"
        case .fullSwing:    return "SWING"
        case .lesson:       return "LESSON"
        case .other:        return "OTHER"
        }
    }

    var systemImage: String {
        switch self {
        case .drivingRange: return "figure.golf"
        case .indoorSim:    return "tv"
        case .putting:      return "circle.circle"
        case .chipping:     return "figure.run"
        case .fullSwing:    return "figure.strengthtraining.traditional"
        case .lesson:       return "person.2"
        case .other:        return "ellipsis.circle"
        }
    }
}

// MARK: - PracticeSession

@Model
final class PracticeSession {
    var date: Date
    var type: PracticeType
    var location: String       // "Blue Ridge Range", "Home sim", "18th green"
    var durationMinutes: Int   // 0 if not tracked
    var ballsHit: Int          // 0 if n/a (putting, chipping)
    var focus: String          // what you were working on
    var drills: String         // drills performed
    var rating: Int            // 0..5 — 0 = unrated
    var notes: String
    var idempotencyKey: String = ""
    var isArchived: Bool = false

    init(date: Date = .now,
         type: PracticeType = .drivingRange,
         location: String = "",
         durationMinutes: Int = 0,
         ballsHit: Int = 0,
         focus: String = "",
         drills: String = "",
         rating: Int = 0,
         notes: String = "") {
        self.date = date
        self.type = type
        self.location = location
        self.durationMinutes = durationMinutes
        self.ballsHit = ballsHit
        self.focus = focus
        self.drills = drills
        self.rating = rating
        self.notes = notes
        self.idempotencyKey = UUID().uuidString
    }

    var durationDisplay: String {
        guard durationMinutes > 0 else { return "—" }
        let h = durationMinutes / 60
        let m = durationMinutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}
