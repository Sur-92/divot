import Foundation
import SwiftData

/// Stub seeder. The public build ships with an empty bag — every club
/// is added by the user via the Clubs screen.
///
/// To pre-seed your own private bag on first launch, drop your
/// `BagClub` rows into `seedIfEmpty(context:)` and they'll appear once
/// when the bag is empty.
enum BagSeeder {
    static func seedIfEmpty(context: ModelContext) {
        // No-op in the public build.
    }
}
