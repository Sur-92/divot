import Foundation
import SwiftData
import CoreLocation

@Model
final class CourseHole {
    var number: Int
    var par: Int
    var handicapIndex: Int   // 1 = hardest, 18 = easiest (optional, default 0)
    var course: Course?

    // Map coordinates — 0/0 means unset
    var teeLatitude: Double = 0
    var teeLongitude: Double = 0
    var greenLatitude: Double = 0
    var greenLongitude: Double = 0

    var idempotencyKey: String = ""

    init(number: Int, par: Int = 4, handicapIndex: Int = 0) {
        self.number = number
        self.par = par
        self.handicapIndex = handicapIndex
        self.idempotencyKey = UUID().uuidString
    }

    var hasTee: Bool { teeLatitude != 0 || teeLongitude != 0 }
    var hasGreen: Bool { greenLatitude != 0 || greenLongitude != 0 }
    var hasCoordinates: Bool { hasTee && hasGreen }

    var teeCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: teeLatitude, longitude: teeLongitude)
    }
    var greenCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: greenLatitude, longitude: greenLongitude)
    }

    /// Straight-line yardage tee→green. 0 if coords incomplete.
    var yardsTeeToGreen: Int {
        guard hasCoordinates else { return 0 }
        let from = CLLocation(latitude: teeLatitude, longitude: teeLongitude)
        let to = CLLocation(latitude: greenLatitude, longitude: greenLongitude)
        let meters = from.distance(from: to)
        return Int((meters * 1.09361).rounded())
    }
}
