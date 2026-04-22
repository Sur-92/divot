import Foundation

// MARK: - Club

enum Club: String, CaseIterable, Codable, Hashable, Identifiable {
    case driver
    case wood3, wood5, wood7
    case hybrid2, hybrid3, hybrid4, hybrid5
    case iron2, iron3, iron4, iron5, iron6, iron7, iron8, iron9
    case pitchingWedge, gapWedge, sandWedge, lobWedge
    case putter

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .driver: return "DR"
        case .wood3: return "3W"
        case .wood5: return "5W"
        case .wood7: return "7W"
        case .hybrid2: return "2H"
        case .hybrid3: return "3H"
        case .hybrid4: return "4H"
        case .hybrid5: return "5H"
        case .iron2: return "2i"
        case .iron3: return "3i"
        case .iron4: return "4i"
        case .iron5: return "5i"
        case .iron6: return "6i"
        case .iron7: return "7i"
        case .iron8: return "8i"
        case .iron9: return "9i"
        case .pitchingWedge: return "PW"
        case .gapWedge: return "GW"
        case .sandWedge: return "SW"
        case .lobWedge: return "LW"
        case .putter: return "Pt"
        }
    }

    var fullName: String {
        switch self {
        case .driver: return "Driver"
        case .wood3: return "3 Wood"
        case .wood5: return "5 Wood"
        case .wood7: return "7 Wood"
        case .hybrid2: return "2 Hybrid"
        case .hybrid3: return "3 Hybrid"
        case .hybrid4: return "4 Hybrid"
        case .hybrid5: return "5 Hybrid"
        case .iron2: return "2 Iron"
        case .iron3: return "3 Iron"
        case .iron4: return "4 Iron"
        case .iron5: return "5 Iron"
        case .iron6: return "6 Iron"
        case .iron7: return "7 Iron"
        case .iron8: return "8 Iron"
        case .iron9: return "9 Iron"
        case .pitchingWedge: return "Pitching Wedge"
        case .gapWedge: return "Gap Wedge"
        case .sandWedge: return "Sand Wedge"
        case .lobWedge: return "Lob Wedge"
        case .putter: return "Putter"
        }
    }

    static let grouped: [(String, [Club])] = [
        ("Woods", [.driver, .wood3, .wood5, .wood7]),
        ("Hybrids", [.hybrid2, .hybrid3, .hybrid4, .hybrid5]),
        ("Irons", [.iron2, .iron3, .iron4, .iron5, .iron6, .iron7, .iron8, .iron9]),
        ("Wedges", [.pitchingWedge, .gapWedge, .sandWedge, .lobWedge]),
        ("Putter", [.putter])
    ]
}

// MARK: - Lie

enum Lie: String, CaseIterable, Codable, Hashable, Identifiable {
    case tee, fairway, rough, fringe, green
    case fairwayBunker, greensideBunker
    case trees, water, recovery, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tee: return "Tee"
        case .fairway: return "Fairway"
        case .rough: return "Rough"
        case .fringe: return "Fringe"
        case .green: return "Green"
        case .fairwayBunker: return "F. Bunker"
        case .greensideBunker: return "G. Bunker"
        case .trees: return "Trees"
        case .water: return "Water"
        case .recovery: return "Recovery"
        case .other: return "Other"
        }
    }
}

// MARK: - Shot result

enum ShotResult: String, CaseIterable, Codable, Hashable, Identifiable {
    case onTarget
    case draw, fade
    case left, right, short, long
    case mishit, penalty

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .onTarget: return "On Target"
        case .draw: return "Draw"
        case .fade: return "Fade"
        case .left: return "Missed Left"
        case .right: return "Missed Right"
        case .short: return "Short"
        case .long: return "Long"
        case .mishit: return "Mishit"
        case .penalty: return "Penalty"
        }
    }

    var shortName: String {
        switch self {
        case .onTarget: return "OK"
        case .draw: return "DR"
        case .fade: return "FD"
        case .left: return "LT"
        case .right: return "RT"
        case .short: return "SH"
        case .long: return "LG"
        case .mishit: return "MH"
        case .penalty: return "PN"
        }
    }
}
