import Foundation
import SwiftData
import CoreLocation

@Model
final class Course {
    var name: String
    var address: String
    var phone: String
    var designer: String
    var openedYear: Int
    var totalPar: Int

    /// Optional tee-time booking URL (the course's online booking page).
    var bookingURL: String = ""

    /// Name of a bundled image in Assets.xcassets — used for the course logo.
    /// Empty string means "no logo, fall back to the generic flag icon".
    var logoAssetName: String = ""

    /// Stable identity for this row — generated on insert, never changes.
    var idempotencyKey: String = ""

    /// Course center coordinates — used as the map camera default when holes
    /// have no per-hole coordinates yet.
    var latitude: Double = 0
    var longitude: Double = 0

    /// True for indoor simulators. The "course" record is a venue
    /// placeholder; the actual track played is recorded per-round on
    /// `Round.simulatedCourseName`. Defaults to false so existing rows
    /// migrate cleanly.
    var isSimulator: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \CourseHole.course)
    var holes: [CourseHole] = []

    @Relationship(deleteRule: .cascade, inverse: \CourseTee.course)
    var tees: [CourseTee] = []

    @Relationship(deleteRule: .nullify, inverse: \Round.course)
    var rounds: [Round] = []

    init(name: String,
         address: String = "",
         phone: String = "",
         designer: String = "",
         openedYear: Int = 0,
         totalPar: Int = 72) {
        self.name = name
        self.address = address
        self.phone = phone
        self.designer = designer
        self.openedYear = openedYear
        self.totalPar = totalPar
        self.idempotencyKey = UUID().uuidString
    }

    var coordinate: CLLocationCoordinate2D? {
        guard latitude != 0 || longitude != 0 else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var holesWithCoordinates: Int {
        holes.filter(\.hasCoordinates).count
    }

    var sortedHoles: [CourseHole] {
        holes.sorted { $0.number < $1.number }
    }

    /// Tees sorted descending by yardage (longest first).
    var sortedTees: [CourseTee] {
        tees.sorted { $0.yardage > $1.yardage }
    }

    /// Live-computed par (sum of hole pars). Use for display; keep
    /// `totalPar` in sync when holes are edited so old code paths stay right.
    var computedPar: Int {
        holes.reduce(0) { $0 + $1.par }
    }
}
