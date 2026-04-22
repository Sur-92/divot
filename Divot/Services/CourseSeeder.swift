import Foundation
import SwiftData

enum CourseSeeder {
    /// Seeds default courses if none exist yet.
    static func seedIfEmpty(context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<Course>())) ?? 0
        guard count == 0 else { return }

        seedRoyalOaks(context: context)
        seedIronValley(context: context)
        seedFairview(context: context)
        seedPineMeadows(context: context)
        seedDauphinHighlands(context: context)
        seedBlueMountain(context: context)
        seedFoxchase(context: context)
        seedDeerValley(context: context)

        do {
            try context.save()
        } catch {
            print("CourseSeeder save failed: \(error)")
        }
    }

    /// Idempotent add-on: inserts Iron Valley only if missing.
    static func seedIronValleyIfNeeded(context: ModelContext) {
        let fetch = FetchDescriptor<Course>(
            predicate: #Predicate { $0.name == "Iron Valley Golf Club" }
        )
        let count = (try? context.fetchCount(fetch)) ?? 0
        guard count == 0 else { return }

        seedIronValley(context: context)

        do {
            try context.save()
        } catch {
            print("CourseSeeder Iron Valley save failed: \(error)")
        }
    }

    /// Idempotent add-on: inserts Fairview only if missing.
    static func seedFairviewIfNeeded(context: ModelContext) {
        let fetch = FetchDescriptor<Course>(
            predicate: #Predicate { $0.name == "Fairview Golf Course" }
        )
        let count = (try? context.fetchCount(fetch)) ?? 0
        guard count == 0 else { return }

        seedFairview(context: context)

        do {
            try context.save()
        } catch {
            print("CourseSeeder Fairview save failed: \(error)")
        }
    }

    /// Idempotent add-on: inserts Pine Meadows only if missing.
    static func seedPineMeadowsIfNeeded(context: ModelContext) {
        let fetch = FetchDescriptor<Course>(
            predicate: #Predicate { $0.name == "Pine Meadows Golf Complex" }
        )
        let count = (try? context.fetchCount(fetch)) ?? 0
        guard count == 0 else { return }

        seedPineMeadows(context: context)

        do {
            try context.save()
        } catch {
            print("CourseSeeder Pine Meadows save failed: \(error)")
        }
    }

    /// Idempotent add-on: inserts Dauphin Highlands only if missing.
    static func seedDauphinHighlandsIfNeeded(context: ModelContext) {
        let fetch = FetchDescriptor<Course>(
            predicate: #Predicate { $0.name == "Dauphin Highlands Golf Course" }
        )
        let count = (try? context.fetchCount(fetch)) ?? 0
        guard count == 0 else { return }

        seedDauphinHighlands(context: context)

        do {
            try context.save()
        } catch {
            print("CourseSeeder Dauphin Highlands save failed: \(error)")
        }
    }

    /// Idempotent add-on: inserts Blue Mountain only if missing.
    static func seedBlueMountainIfNeeded(context: ModelContext) {
        let fetch = FetchDescriptor<Course>(
            predicate: #Predicate { $0.name == "Blue Mountain Golf Course" }
        )
        let count = (try? context.fetchCount(fetch)) ?? 0
        guard count == 0 else { return }

        seedBlueMountain(context: context)

        do {
            try context.save()
        } catch {
            print("CourseSeeder Blue Mountain save failed: \(error)")
        }
    }

    /// Idempotent add-on: inserts Foxchase only if missing.
    static func seedFoxchaseIfNeeded(context: ModelContext) {
        let fetch = FetchDescriptor<Course>(
            predicate: #Predicate { $0.name == "Foxchase Golf Club" }
        )
        let count = (try? context.fetchCount(fetch)) ?? 0
        guard count == 0 else { return }

        seedFoxchase(context: context)

        do {
            try context.save()
        } catch {
            print("CourseSeeder Foxchase save failed: \(error)")
        }
    }

    /// Idempotent add-on: inserts Deer Valley only if missing.
    static func seedDeerValleyIfNeeded(context: ModelContext) {
        let fetch = FetchDescriptor<Course>(
            predicate: #Predicate { $0.name == "Deer Valley Golf Course" }
        )
        let count = (try? context.fetchCount(fetch)) ?? 0
        guard count == 0 else { return }

        seedDeerValley(context: context)

        do {
            try context.save()
        } catch {
            print("CourseSeeder Deer Valley save failed: \(error)")
        }
    }

    /// Replaces a pre-existing Royal Oaks record with the authoritative
    /// PDF-based data when it's running on an older seed (pre-yardage,
    /// pre-handicap, or old Gold/Silver/Bronze tee names).
    /// Fairview was originally seeded with all hole handicap indices = 0.
    /// Backfills from the official scorecard at
    /// https://www.fairview.distinctgolf.com/scorecard-ratings/ — both the
    /// course's CourseHole rows and any existing Round's snapshotted
    /// handicaps that were created before the fix.
    static func migrateFairviewHandicapsIfNeeded(context: ModelContext) {
        let fetch = FetchDescriptor<Course>(
            predicate: #Predicate { $0.name == "Fairview Golf Course" }
        )
        guard let course = try? context.fetch(fetch).first else { return }

        // Canonical handicap indices per hole (1-based → 0-based array),
        // men's Blue/Back tee row from the official scorecard image.
        let canonicalHcp = [17, 15,  1,  5, 7, 11,  9,  3, 13,
                            14,  4,  2, 18, 6,  8, 12, 10, 16]

        var touchedCourse = false
        for hole in course.holes where (1...18).contains(hole.number) {
            let expected = canonicalHcp[hole.number - 1]
            if hole.handicapIndex != expected {
                hole.handicapIndex = expected
                touchedCourse = true
            }
        }

        var touchedRounds = 0
        for round in course.rounds {
            for hole in round.holes where (1...18).contains(hole.number) {
                let expected = canonicalHcp[hole.number - 1]
                if hole.handicapIndex != expected {
                    hole.handicapIndex = expected
                    touchedRounds += 1
                }
            }
        }

        if touchedCourse || touchedRounds > 0 {
            do {
                try context.save()
            } catch {
                print("CourseSeeder Fairview hcp migrate failed: \(error)")
            }
        }
    }

    /// Iron Valley was originally seeded with all hole handicap indices = 0
    /// because the scorecard hadn't been verified. Now that we have the
    /// official values (from ironvalley.com's scorecard image), backfill:
    ///   1. the course's CourseHole rows
    ///   2. any existing Round's Hole snapshots that were created before the fix
    static func migrateIronValleyHandicapsIfNeeded(context: ModelContext) {
        let fetch = FetchDescriptor<Course>(
            predicate: #Predicate { $0.name == "Iron Valley Golf Club" }
        )
        guard let course = try? context.fetch(fetch).first else { return }

        // Canonical handicap indices per hole (1-based → 0-based array).
        let canonicalHcp = [1, 17, 15, 5, 11, 3,  9, 7, 13,
                            4, 14, 16, 10, 8, 6, 18, 12, 2]

        // 1) Patch course holes.
        var touchedCourse = false
        for hole in course.holes where (1...18).contains(hole.number) {
            let expected = canonicalHcp[hole.number - 1]
            if hole.handicapIndex != expected {
                hole.handicapIndex = expected
                touchedCourse = true
            }
        }

        // 2) Patch snapshotted handicaps on any existing round's Hole rows
        //    that point at Iron Valley (the round stores a copy so historical
        //    rounds aren't retroactively changed by later course edits —
        //    but since these snapshots were created BEFORE we had real data,
        //    we're fixing a previously-missing value, not rewriting history).
        var touchedRounds = 0
        for round in course.rounds {
            for hole in round.holes where (1...18).contains(hole.number) {
                let expected = canonicalHcp[hole.number - 1]
                if hole.handicapIndex != expected {
                    hole.handicapIndex = expected
                    touchedRounds += 1
                }
            }
        }

        if touchedCourse || touchedRounds > 0 {
            do {
                try context.save()
            } catch {
                print("CourseSeeder Iron Valley hcp migrate failed: \(error)")
            }
        }
    }

    static func migrateRoyalOaksIfNeeded(context: ModelContext) {
        let fetch = FetchDescriptor<Course>(
            predicate: #Predicate { $0.name == "Royal Oaks Golf Club" }
        )
        guard let existing = try? context.fetch(fetch).first else { return }

        let teeNames = Set(existing.tees.map(\.name))
        let expectedNames: Set<String> = ["Blue", "White", "Yellow", "Red"]
        let hasPerHoleYardages = existing.tees.contains { $0.yardages.count == 18 }
        let hasHandicaps = existing.holes.contains { $0.handicapIndex > 0 }

        // Migration triggers: tee-name mismatch, missing yardages, or missing handicaps.
        let needsMigration =
            !teeNames.isSuperset(of: expectedNames) ||
            teeNames.contains("Gold") || teeNames.contains("Silver") ||
            teeNames.contains("Bronze") || teeNames.contains("Black") ||
            teeNames.contains("Black (L)") ||
            !hasPerHoleYardages || !hasHandicaps

        guard needsMigration else { return }

        context.delete(existing)
        seedRoyalOaks(context: context)

        do {
            try context.save()
        } catch {
            print("CourseSeeder migrate failed: \(error)")
        }
    }

    // MARK: - Royal Oaks — 2024 scorecard

    private static func seedRoyalOaks(context: ModelContext) {
        let course = Course(
            name: "Royal Oaks Golf Club",
            address: "3350 W Oak St, Lebanon, PA 17042",
            phone: "(717) 274-2212",
            designer: "Ron Forse",
            openedYear: 1992,
            totalPar: 71
        )
        course.bookingURL = "https://golfatroyaloaks.com/teetimes/"
        course.logoAssetName = "RoyalOaksLogo"
        // Approximate course center for map camera fallback.
        course.latitude = 40.3312
        course.longitude = -76.4823

        // Hole-by-hole par and handicap (from 2024 scorecard).
        let pars       = [5, 4, 3, 4, 3, 4, 5, 3, 5,
                          4, 3, 4, 5, 4, 3, 4, 4, 4]
        let handicaps  = [6, 14, 16, 2, 10, 8, 4, 18, 12,
                          5, 15, 9, 17, 3, 11, 13, 1, 7]

        for i in 0..<18 {
            let hole = CourseHole(
                number: i + 1,
                par: pars[i],
                handicapIndex: handicaps[i]
            )
            hole.course = course
            course.holes.append(hole)
        }

        // Tees with per-hole yardages (from 2024 scorecard PDF).
        let teeData: [(name: String, yards: [Int], total: Int, rating: Double, slope: Int)] = [
            ("Blue",
             [534, 310, 162, 403, 203, 380, 546, 157, 510,
              388, 150, 393, 490, 423, 189, 319, 408, 409],
             6374, 71.1, 129),
            ("White",
             [500, 291, 142, 390, 167, 369, 523, 133, 486,
              371, 120, 359, 440, 393, 175, 309, 376, 373],
             5917, 69.2, 123),
            ("Yellow",
             [455, 266, 103, 350, 150, 322, 476, 107, 452,
              320, 105, 315, 417, 362, 132, 280, 332, 341],
             5285, 65.9, 117),
            ("Red",
             [402, 242, 100, 306, 127, 286, 442, 104, 398,
              280,  98, 311, 374, 313, 102, 273, 295, 298],
             4751, 63.6, 112)
        ]

        for t in teeData {
            let tee = CourseTee(
                name: t.name,
                yardage: t.total,
                courseRating: t.rating,
                slopeRating: t.slope,
                yardages: t.yards
            )
            tee.course = course
            course.tees.append(tee)
        }

        context.insert(course)
    }

    // MARK: - Iron Valley Golf Club, Cornwall / Lebanon PA

    private static func seedIronValley(context: ModelContext) {
        let course = Course(
            name: "Iron Valley Golf Club",
            address: "201 Iron Valley Drive, Lebanon, PA 17042",
            phone: "(717) 279-7409",
            designer: "P.B. Dye",
            openedYear: 2000,
            totalPar: 72
        )
        course.bookingURL = "https://www.ironvalley.com/golf/tee-times"
        course.logoAssetName = "IronValleyLogo"
        // Approximate course center (Cornwall, PA).
        course.latitude = 40.2761
        course.longitude = -76.4078

        // Par + handicap index per hole from the official club scorecard
        // (https://www.ironvalley.com/images/pictures/2018IVSCInside.jpg).
        // Front: 4-4-5-4-3-4-5-3-4 (36) · Back: 4-4-3-5-4-4-5-3-4 (36)
        // HCP 1 = hardest, 18 = easiest. All 18 unique indices verified.
        let pars = [4, 4, 5, 4, 3, 4, 5, 3, 4,
                    4, 4, 3, 5, 4, 4, 5, 3, 4]
        let hcps = [1, 17, 15, 5, 11, 3,  9, 7, 13,
                    4, 14, 16, 10, 8, 6, 18, 12, 2]

        for i in 0..<18 {
            let hole = CourseHole(number: i + 1, par: pars[i], handicapIndex: hcps[i])
            hole.course = course
            course.holes.append(hole)
        }

        // Five tee sets (Black / Blue / White / Gold / Red) with per-hole yardages.
        let teeData: [(name: String, yards: [Int], total: Int, rating: Double, slope: Int)] = [
            ("Black",
             [435, 373, 511, 448, 124, 473, 535, 201, 395,
              469, 356, 177, 588, 383, 456, 494, 181, 427],
             7026, 74.9, 138),
            ("Blue",
             [380, 342, 472, 428, 116, 427, 497, 173, 367,
              423, 340, 138, 542, 360, 422, 471, 165, 389],
             6452, 72.3, 133),
            ("White",
             [351, 327, 451, 410,  95, 385, 456, 155, 357,
              384, 312, 125, 520, 340, 415, 425, 145, 374],
             6027, 69.5, 130),
            ("Gold",
             [295, 233, 395, 308,  85, 294, 440, 141, 302,
              350, 257, 119, 501, 317, 340, 408, 125, 304],
             5214, 65.0, 112),
            ("Red",
             [290, 233, 390, 305,  85, 289, 372, 110, 269,
              344, 255, 113, 442, 262, 335, 405, 121, 285],
             4905, 69.2, 123)
        ]

        for t in teeData {
            let tee = CourseTee(
                name: t.name,
                yardage: t.total,
                courseRating: t.rating,
                slopeRating: t.slope,
                yardages: t.yards
            )
            tee.course = course
            course.tees.append(tee)
        }

        context.insert(course)
    }

    // MARK: - Fairview Golf Course, Lebanon PA

    private static func seedFairview(context: ModelContext) {
        let course = Course(
            name: "Fairview Golf Course",
            address: "2399 Quentin Rd, Lebanon, PA 17042",
            phone: "(717) 273-3411",
            designer: "Frank Murray · Russell Roberts",
            openedYear: 1959,
            totalPar: 71
        )
        course.bookingURL = "https://www.fairview.distinctgolf.com/book-a-tee-time/"
        course.logoAssetName = "FairviewLogo"
        course.latitude = 40.3067
        course.longitude = -76.4422

        // Par + handicap index per hole from Fairview's official scorecard
        // (https://www.fairview.distinctgolf.com/scorecard-ratings/).
        // Front 4-4-4-5-4-3-5-4-3 (36) · Back 4-4-4-3-5-3-4-5-3 (35)
        // Handicap row from Blue/Back tees (men's). All 18 unique, sum=171.
        let pars = [4, 4, 4, 5, 4, 3, 5, 4, 3,
                    4, 4, 4, 3, 5, 3, 4, 5, 3]
        let hcps = [17, 15,  1,  5, 7, 11,  9,  3, 13,
                    14,  4,  2, 18, 6,  8, 12, 10, 16]

        for i in 0..<18 {
            let hole = CourseHole(number: i + 1, par: pars[i], handicapIndex: hcps[i])
            hole.course = course
            course.holes.append(hole)
        }

        // Blue tee per-hole yardages (from GolfLink).
        let blueYards = [310, 345, 446, 501, 430, 202, 508, 398, 195,
                         318, 364, 372, 176, 514, 179, 378, 483, 173]

        // Other tees — per-hole yards not yet confirmed; totals + rating/slope only.
        let teeData: [(name: String, yards: [Int], total: Int, rating: Double, slope: Int)] = [
            ("Blue",  blueYards, 6292, 69.4, 116),
            ("White", [],        5932, 68.1, 113),
            ("Gold",  [],        5536, 67.1, 110),
            ("Red",   [],        5221, 72.9, 115),
            ("Red (L)", [],      5055, 68.0, 114)
        ]

        for t in teeData {
            let tee = CourseTee(
                name: t.name,
                yardage: t.total,
                courseRating: t.rating,
                slopeRating: t.slope,
                yardages: t.yards
            )
            tee.course = course
            course.tees.append(tee)
        }

        context.insert(course)
    }

    // MARK: - Pine Meadows Golf Complex, Lebanon PA

    private static func seedPineMeadows(context: ModelContext) {
        let course = Course(
            name: "Pine Meadows Golf Complex",
            address: "319 Pine Meadow Road, Lebanon, PA 17046",
            phone: "(717) 865-4995",
            designer: "Larry Rabold",
            openedYear: 1965,
            totalPar: 72
        )
        course.bookingURL = "https://www.pinemeadowsgolf.com/"
        course.logoAssetName = "PineMeadowsLogo"
        // Approximate — Northern Lebanon County, PA.
        course.latitude = 40.4215
        course.longitude = -76.4852

        // Real scorecard: front 4-4-4-4-5-5-3-4-3 (36), back 5-4-4-3-4-4-4-3-5 (36).
        let pars = [4, 4, 4, 4, 5, 5, 3, 4, 3,
                    5, 4, 4, 3, 4, 4, 4, 3, 5]
        // Men's handicap indices per hole.
        let handicaps = [5, 3, 1, 9, 17, 13, 7, 15, 11,
                         10, 14, 18, 4, 6, 8, 2, 16, 12]

        for i in 0..<18 {
            let hole = CourseHole(
                number: i + 1,
                par: pars[i],
                handicapIndex: handicaps[i]
            )
            hole.course = course
            course.holes.append(hole)
        }

        // Five tee sets with complete per-hole yardages (from the 2026 scorecard).
        let teeData: [(name: String, yards: [Int], total: Int, rating: Double, slope: Int)] = [
            ("Black",
             [422, 276, 388, 318, 489, 565, 196, 348, 145,
              538, 360, 391, 185, 313, 403, 333, 179, 535],
             6384, 70.6, 123),
            ("Blue",
             [409, 276, 376, 310, 480, 463, 184, 329, 132,
              538, 349, 354, 166, 301, 355, 321, 172, 521],
             6037, 69.2, 119),
            ("White",
             [394, 247, 365, 301, 471, 444, 172, 304, 114,
              490, 336, 338, 147, 290, 340, 314, 160, 506],
             5734, 67.5, 117),
            ("Gold",
             [298, 201, 353, 293, 395, 392, 118, 295, 107,
              407, 284, 275, 129, 286, 266, 237, 142, 381],
             4859, 63.2, 105),
            ("Red",
             [298, 201, 353, 205, 315, 392,  93, 255, 107,
              388, 248, 248,  97, 246, 266, 210, 129, 368],
             4419, 64.1, 109)
        ]

        for t in teeData {
            let tee = CourseTee(
                name: t.name,
                yardage: t.total,
                courseRating: t.rating,
                slopeRating: t.slope,
                yardages: t.yards
            )
            tee.course = course
            course.tees.append(tee)
        }

        context.insert(course)
    }

    // MARK: - Dauphin Highlands Golf Course, Harrisburg PA

    private static func seedDauphinHighlands(context: ModelContext) {
        let course = Course(
            name: "Dauphin Highlands Golf Course",
            address: "650 S Harrisburg St, Harrisburg, PA 17113",
            phone: "(717) 986-1984",
            designer: "William R. Love, ASGCA",
            openedYear: 1995,
            totalPar: 72
        )
        course.bookingURL = "https://www.golfdauphinhighlands.com/book-a-tee-time/"
        course.logoAssetName = "DauphinHighlandsLogo"
        // Approximate — Harrisburg, PA (course sits east of the river).
        course.latitude = 40.2300
        course.longitude = -76.8250

        // Front: 4-4-4-3-5-4-5-3-4 (36), Back: 4-4-5-4-4-3-5-3-4 (36) = 72
        // Handicap indices not provided in the public source.
        let pars = [4, 4, 4, 3, 5, 4, 5, 3, 4,
                    4, 4, 5, 4, 4, 3, 5, 3, 4]
        for i in 0..<18 {
            let hole = CourseHole(number: i + 1, par: pars[i])
            hole.course = course
            course.holes.append(hole)
        }

        // Five tee sets with complete per-hole yardages.
        let teeData: [(name: String, yards: [Int], total: Int, rating: Double, slope: Int)] = [
            ("Black",
             [429, 330, 458, 172, 534, 398, 570, 237, 446,
              366, 425, 541, 440, 392, 204, 580, 196, 403],
             7121, 73.7, 131),
            ("Blue",
             [401, 288, 426, 152, 507, 372, 557, 222, 428,
              344, 412, 520, 421, 375, 188, 565, 188, 390],
             6756, 71.6, 130),
            ("White",
             [381, 269, 421, 132, 480, 346, 500, 200, 410,
              330, 374, 501, 403, 352, 165, 525, 172, 365],
             6326, 70.0, 127),
            ("Gold",
             [345, 257, 375, 119, 425, 285, 455, 146, 348,
              316, 325, 465, 329, 273, 148, 469, 155, 312],
             5547, 66.2, 116),
            ("Red",
             [353, 212, 366,  88, 419, 279, 448, 140, 343,
              287, 315, 401, 324, 268, 145, 464, 152, 306],
             5310, 70.4, 122)
        ]

        for t in teeData {
            let tee = CourseTee(
                name: t.name,
                yardage: t.total,
                courseRating: t.rating,
                slopeRating: t.slope,
                yardages: t.yards
            )
            tee.course = course
            course.tees.append(tee)
        }

        context.insert(course)
    }

    // MARK: - Blue Mountain Golf Course, Fredericksburg PA

    private static func seedBlueMountain(context: ModelContext) {
        let course = Course(
            name: "Blue Mountain Golf Course",
            address: "628 Blue Mountain Road, Fredericksburg, PA 17026",
            phone: "(717) 865-4401",
            designer: "Marlin Gibble",
            openedYear: 1966,
            totalPar: 71
        )
        course.bookingURL = "https://www.bluemountaingolf.com/golf/tee-times"
        course.logoAssetName = "BlueMountainLogo"
        // Approximate — Fredericksburg, PA (Lebanon County, base of Blue Mountain).
        course.latitude = 40.4481
        course.longitude = -76.4772

        // Men's par: front 4-3-4-5-3-4-4-5-4 (36), back 3-4-3-5-4-5-3-4-4 (35) = 71
        // Men's handicap indices per hole.
        let pars = [4, 3, 4, 5, 3, 4, 4, 5, 4,
                    3, 4, 3, 5, 4, 5, 3, 4, 4]
        let handicaps = [5, 9, 17, 7, 15, 11, 13, 1, 3,
                         8, 4, 12, 6, 18, 2, 16, 10, 14]

        for i in 0..<18 {
            let hole = CourseHole(
                number: i + 1,
                par: pars[i],
                handicapIndex: handicaps[i]
            )
            hole.course = course
            course.holes.append(hole)
        }

        // Four tee sets with complete per-hole yardages (from 2023 scorecard).
        let teeData: [(name: String, yards: [Int], total: Int, rating: Double, slope: Int)] = [
            ("Championship",
             [357, 219, 397, 488, 172, 318, 405, 530, 380,
              198, 389, 154, 447, 297, 573, 157, 373, 256],
             6110, 68.8, 115),
            ("Men's",
             [344, 148, 327, 470, 160, 304, 273, 494, 360,
              171, 371, 148, 413, 286, 559, 138, 286, 306],
             5558, 66.2, 107),
            ("Seniors'",
             [273, 137, 259, 412, 150, 279, 247, 444, 251,
              133, 302, 125, 375, 245, 475, 136, 254, 282],
             4779, 62.4, 100),
            ("Ladies'",
             [228, 132, 234, 366, 111, 238, 239, 371, 240,
              115, 291, 124, 337, 239, 465, 113, 214, 190],
             4247, 64.1, 100)
        ]

        for t in teeData {
            let tee = CourseTee(
                name: t.name,
                yardage: t.total,
                courseRating: t.rating,
                slopeRating: t.slope,
                yardages: t.yards
            )
            tee.course = course
            course.tees.append(tee)
        }

        context.insert(course)
    }

    // MARK: - Foxchase Golf Club, Stevens/Ephrata PA

    private static func seedFoxchase(context: ModelContext) {
        let course = Course(
            name: "Foxchase Golf Club",
            address: "300 Stevens Road, Stevens, PA 17578",
            phone: "(717) 336-3673",
            designer: "John Thompson",
            openedYear: 1991,
            totalPar: 72
        )
        course.bookingURL = "https://app.whoosh.io/patron/club/foxchase-golf-club"
        course.logoAssetName = "FoxchaseLogo"
        // Approximate — Stevens, PA (Lancaster County, near Ephrata).
        course.latitude = 40.2857
        course.longitude = -76.1786

        // Front: 4-4-3-4-4-3-5-3-5 (35), Back: 4-5-4-3-5-4-4-4-4 (37) = 72
        let pars = [4, 4, 3, 4, 4, 3, 5, 3, 5,
                    4, 5, 4, 3, 5, 4, 4, 4, 4]
        let handicaps = [2, 14, 6, 12, 10, 8, 16, 18, 4,
                         9, 7, 13, 17, 1, 15, 3, 11, 5]

        for i in 0..<18 {
            let hole = CourseHole(
                number: i + 1,
                par: pars[i],
                handicapIndex: handicaps[i]
            )
            hole.course = course
            course.holes.append(hole)
        }

        // Five tee sets with complete per-hole yardages (from the 2026 scorecard PDF).
        let teeData: [(name: String, yards: [Int], total: Int, rating: Double, slope: Int)] = [
            ("Black",
             [413, 333, 215, 367, 393, 177, 525, 196, 473,
              394, 516, 375, 155, 578, 333, 411, 355, 398],
             6607, 71.9, 131),
            ("Blue",
             [389, 293, 184, 336, 334, 159, 500, 172, 439,
              364, 497, 349, 134, 503, 321, 373, 333, 375],
             6055, 69.4, 127),
            ("White",
             [360, 278, 150, 316, 314, 150, 481, 145, 412,
              341, 466, 331, 114, 452, 302, 354, 315, 353],
             5634, 67.4, 123),
            ("Gold",
             [279, 258, 138, 247, 248, 140, 440, 130, 386,
              322, 417, 268, 108, 375, 295, 342, 253, 299],
             4945, 63.4, 114),
            ("Red",
             [279, 240, 105, 247, 248, 116, 440, 105, 386,
              295, 417, 268,  82, 375, 256, 342, 253, 299],
             4753, 67.7, 120)
        ]

        for t in teeData {
            let tee = CourseTee(
                name: t.name,
                yardage: t.total,
                courseRating: t.rating,
                slopeRating: t.slope,
                yardages: t.yards
            )
            tee.course = course
            course.tees.append(tee)
        }

        context.insert(course)
    }

    // MARK: - Deer Valley Golf Course, Hummelstown PA

    private static func seedDeerValley(context: ModelContext) {
        let course = Course(
            name: "Deer Valley Golf Course",
            address: "101 Stoudt Rd, Hummelstown, PA 17036",
            phone: "(717) 583-4653",
            designer: "Bill Wall",
            openedYear: 2005,
            totalPar: 72
        )
        course.bookingURL = "https://deer-valley-golf-course-2.book.teeitup.golf/?course=9328"
        course.logoAssetName = "DeerValleyLogo"
        // Approximate — Hummelstown, PA.
        course.latitude = 40.2680
        course.longitude = -76.7020

        // Front: 4-5-4-3-5-3-4-5-3 (36), Back: 3-5-4-4-3-5-4-4-4 (36) = 72
        // Handicap indices not published.
        let pars = [4, 5, 4, 3, 5, 3, 4, 5, 3,
                    3, 5, 4, 4, 3, 5, 4, 4, 4]
        for i in 0..<18 {
            let hole = CourseHole(number: i + 1, par: pars[i])
            hole.course = course
            course.holes.append(hole)
        }

        // Three tee sets with complete per-hole yardages.
        let teeData: [(name: String, yards: [Int], total: Int, rating: Double, slope: Int)] = [
            ("White",
             [348, 483, 287, 135, 481, 178, 411, 447, 141,
              161, 501, 416, 304, 215, 517, 286, 371, 345],
             6027, 69.4, 114),
            ("Gold",
             [343, 437, 271, 123, 429, 161, 395, 431, 125,
              141, 469, 400, 282, 163, 485, 254, 339, 329],
             5577, 68.7, 112),
            ("Red",
             [338, 400, 255, 110, 356, 144, 379, 415, 114,
              136, 333, 400, 272, 146, 453, 238, 323, 314],
             5126, 67.2, 111)
        ]

        for t in teeData {
            let tee = CourseTee(
                name: t.name,
                yardage: t.total,
                courseRating: t.rating,
                slopeRating: t.slope,
                yardages: t.yards
            )
            tee.course = course
            course.tees.append(tee)
        }

        context.insert(course)
    }
}
