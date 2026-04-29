import Foundation
import SwiftData

/// Stub seeder. The public build ships with no bundled courses — every
/// course is added by the user via the Courses screen.
///
/// To pre-seed your own private courses on first launch:
///   1. Add a logo asset to `Assets.xcassets` (the asset name will be
///      stored on `Course.logoAssetName`).
///   2. Add a `seedYourCourse(context:)` static func below that builds
///      a `Course`, attaches `CourseHole`s and `CourseTee`s, then calls
///      `context.insert(course)`.
///   3. Call it from `seedIfEmpty(context:)` (or from `DivotApp.init`).
///
/// Keep your seeders out of the public branch — that's why this file
/// is empty in the public release.
enum CourseSeeder {
    /// Runs once if the courses table is empty. The public build leaves
    /// it empty so the Courses screen shows its empty state and the user
    /// builds their own list.
    static func seedIfEmpty(context: ModelContext) {
        // No-op in the public build.
    }
}
