import Foundation
import SwiftData

// MARK: - Category

enum ClubCategory: String, CaseIterable, Codable, Hashable, Identifiable {
    case driver, fairway, hybrid, ironSet, wedge, putter

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .driver:   return "Driver"
        case .fairway:  return "Fairway Wood"
        case .hybrid:   return "Hybrid"
        case .ironSet:  return "Iron Set"
        case .wedge:    return "Wedge"
        case .putter:   return "Putter"
        }
    }

    var shortName: String {
        switch self {
        case .driver:   return "DRIVER"
        case .fairway:  return "FAIRWAY"
        case .hybrid:   return "HYBRID"
        case .ironSet:  return "IRONS"
        case .wedge:    return "WEDGE"
        case .putter:   return "PUTTER"
        }
    }

    var symbol: String {
        switch self {
        case .driver:   return "001"
        case .fairway:  return "003"
        case .hybrid:   return "H"
        case .ironSet:  return "4–PW"
        case .wedge:    return "WG"
        case .putter:   return "PT"
        }
    }

    /// Sort order for bag display — longest club first.
    var sortOrder: Int {
        switch self {
        case .driver:   return 0
        case .fairway:  return 1
        case .hybrid:   return 2
        case .ironSet:  return 3
        case .wedge:    return 4
        case .putter:   return 5
        }
    }
}

// MARK: - BagClub

@Model
final class BagClub {
    var manufacturer: String
    var modelName: String
    var year: Int                   // 0 = unknown
    var category: ClubCategory
    var loft: String                // freeform, e.g. "10.5°", "15°", "52-08"
    var shaft: String               // freeform, e.g. "Ventus Blue 6 S"
    var notes: String
    var addedAt: Date

    /// User-controlled display order in the bag. Lower = higher in list.
    /// 0 means "not yet assigned" and gets backfilled on first ClubsView load.
    var bagOrder: Int = 0

    /// Club designation — e.g. "4", "7", "PW", "GW", "SW", "LW", "3W", "Driver", "Putter".
    var clubNumber: String = ""

    /// Grip info — e.g. "Golf Pride Tour Velvet Midsize", "Lamkin Crossline Std".
    var grip: String = ""

    /// Stable identity for this row — generated on insert, never changes.
    var idempotencyKey: String = ""

    /// Soft-delete flag. Retired clubs are hidden from the main bag view
    /// and don't count toward the 14-slot tally, but the data is preserved
    /// (the user can restore them or hard-delete from the Retired list).
    var isRetired: Bool = false

    /// When the club was retired. Nil if active. Shown as a date stamp on
    /// the retired list so it's clear when each club came out of the bag.
    var retiredAt: Date?

    init(manufacturer: String,
         modelName: String,
         year: Int = 0,
         category: ClubCategory,
         loft: String = "",
         shaft: String = "",
         notes: String = "",
         addedAt: Date = .now,
         bagOrder: Int = 0,
         clubNumber: String = "",
         grip: String = "") {
        self.manufacturer = manufacturer
        self.modelName = modelName
        self.year = year
        self.category = category
        self.loft = loft
        self.shaft = shaft
        self.notes = notes
        self.addedAt = addedAt
        self.bagOrder = bagOrder
        self.clubNumber = clubNumber
        self.grip = grip
        self.idempotencyKey = UUID().uuidString
    }

    var displayTitle: String {
        if modelName.isEmpty && manufacturer.isEmpty { return "Untitled Club" }
        if modelName.isEmpty { return manufacturer }
        if manufacturer.isEmpty { return modelName }
        return "\(manufacturer) \(modelName)"
    }

    var yearDisplay: String {
        year > 0 ? "\(year)" : "—"
    }
}
