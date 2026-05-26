import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \Round.date, order: .reverse) private var rounds: [Round]
    @State private var selectedRound: Round?

    // MARK: - Round pools

    private var played: [Round] {
        // Excludes reconstructed rounds: their hole-by-hole detail was
        // synthesized to match a known total, so they'd pollute averages,
        // FIR/GIR rates, and putts/hole. The rounds still show on the
        // main list with a badge — they just don't count here.
        rounds.filter {
            $0.totalScore > 0 && !$0.isArchived && !$0.isReconstructed
        }
    }

    private var played18: [Round] { played.filter { $0.holeCount == 18 } }
    private var played9:  [Round] { played.filter { $0.holeCount == 9 } }

    // MARK: - Hole-normalized averages (per 9 holes)
    //
    // Rather than averaging totals across 9- and 18-hole rounds
    // (which is nonsense — a 44 on 9 is not the same as a 44 on 18),
    // we sum strokes + holes across every round and re-scale to a
    // 9-hole basis. One round played at any length contributes fairly.

    private var totalStrokes: Int { played.reduce(0) { $0 + $1.totalScore } }
    private var totalParSum:  Int { played.reduce(0) { $0 + $1.totalPar } }
    private var totalHoles:   Int { played.reduce(0) { $0 + $1.holeCount } }

    private var avgPer9: Double {
        guard totalHoles > 0 else { return 0 }
        return Double(totalStrokes) / Double(totalHoles) * 9
    }

    private var avgToParPer9: Double {
        guard totalHoles > 0 else { return 0 }
        return Double(totalStrokes - totalParSum) / Double(totalHoles) * 9
    }

    private var avgFairway: Double {
        guard !played.isEmpty else { return 0 }
        return played.reduce(0) { $0 + $1.fairwayPercentage } / Double(played.count)
    }

    private var avgGir: Double {
        guard !played.isEmpty else { return 0 }
        return played.reduce(0) { $0 + $1.girPercentage } / Double(played.count)
    }

    private var avgPutts: Double {
        guard !played.isEmpty else { return 0 }
        return played.reduce(0) { $0 + $1.averagePutts } / Double(played.count)
    }

    // MARK: - Split bests — 18 and 9 tracked separately

    private var low18: Round? {
        played18.min { $0.totalScore < $1.totalScore }
    }
    private var low9: Round? {
        played9.min { $0.totalScore < $1.totalScore }
    }

    private var bestToPar18: Round? {
        played18.min { $0.scoreToPar < $1.scoreToPar }
    }
    private var bestToPar9: Round? {
        played9.min { $0.scoreToPar < $1.scoreToPar }
    }

    /// Headline "Low Round" for the main stat grid — picks 18 if you have any,
    /// otherwise falls back to 9. Subtitle makes the round type explicit.
    private var headlineLow: (round: Round, typeLabel: String)? {
        if let r = low18 { return (r, "best 18") }
        if let r = low9  { return (r, "best 9")  }
        return nil
    }

    // MARK: - Personal bests (hole-level counts)

    private var bests: PersonalBests {
        PersonalBests.compute(from: played)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header

                    if played.isEmpty {
                        emptyState
                    } else {
                        identityCard
                        statGrid
                        performanceSection
                        personalBestsSection
                        recentRoundsSection
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
            .navigationDestination(item: $selectedRound) { round in
                RoundDetailView(round: round)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("STATS")
                .font(.system(size: 11, weight: .semibold))
                .tracking(4)
                .foregroundStyle(Theme.accent)
            Text(headerSubtitle)
                .font(.system(size: 13))
                .foregroundStyle(Theme.dim)
            Rectangle()
                .fill(Theme.accent)
                .frame(width: 28, height: 1.5)
                .padding(.top, 2)
        }
    }

    private var headerSubtitle: String {
        let n = played.count
        let base = "Built from \(n) \(n == 1 ? "round" : "rounds")"
        // Show the mix so the "/9 normalization" makes sense.
        if played18.count > 0 && played9.count > 0 {
            return "\(base) · \(played18.count) × 18 · \(played9.count) × 9 · normalized per 9 holes."
        } else if played18.count > 0 {
            return "\(base) — all 18-hole."
        } else {
            return "\(base) — all 9-hole."
        }
    }

    // MARK: - Identity card (who you are · who you can be · who you'd become)
    //
    // Three-tier player label driven by score-per-9 average. The middle
    // label is "now"; the upper is one rung above ("ascend"); the lower
    // is one rung below ("descend"). Designed to read fast at a glance —
    // no paragraphs, just a short tag for each tier.

    private enum PlayerTier: Int, CaseIterable {
        case hazardDonor    // 53+
        case tripleHunter   // 48-52
        case bogeyGolfer    // 44-47
        case midEightyThreat // 40-43
        case singleDigit    // 36-39
        case scratchTerritory // <36

        /// Map a per-9 score average onto a tier.
        static func from(scorePer9 s: Double) -> PlayerTier {
            switch s {
            case ..<36:   return .scratchTerritory
            case 36..<40: return .singleDigit
            case 40..<44: return .midEightyThreat
            case 44..<48: return .bogeyGolfer
            case 48..<53: return .tripleHunter
            default:      return .hazardDonor
            }
        }

        var label: String {
            switch self {
            case .hazardDonor:      return "Hazard donor"
            case .tripleHunter:     return "Triple-bogey hunter"
            case .bogeyGolfer:      return "Bogey golfer"
            case .midEightyThreat:  return "Mid-80s threat"
            case .singleDigit:      return "Single-digit player"
            case .scratchTerritory: return "Scratch territory"
            }
        }

        /// Score-per-9 band that defines this tier (for the subtitle).
        var bandText: String {
            switch self {
            case .hazardDonor:      return "53+/9"
            case .tripleHunter:     return "48–52/9"
            case .bogeyGolfer:      return "44–47/9"
            case .midEightyThreat:  return "40–43/9"
            case .singleDigit:      return "36–39/9"
            case .scratchTerritory: return "under 36/9"
            }
        }

        /// Rung above (aspirational). Caps at the top.
        var ascend: PlayerTier {
            PlayerTier(rawValue: rawValue + 1) ?? self
        }

        /// Rung below (warning). Caps at the bottom.
        var descend: PlayerTier {
            PlayerTier(rawValue: rawValue - 1) ?? self
        }
    }

    private var currentTier: PlayerTier { .from(scorePer9: avgPer9) }

    private var identityCard: some View {
        let now    = currentTier
        let ascend = now.ascend
        let descend = now.descend

        return VStack(alignment: .leading, spacing: 0) {
            // ASCEND
            tierRow(label: "ASCEND",
                    arrow: "arrow.up",
                    tier: ascend,
                    isCurrent: false,
                    color: Color(red: 0.55, green: 0.88, blue: 0.60))   // light green

            Rectangle()
                .fill(Theme.hairline.opacity(0.5))
                .frame(height: 1)

            // NOW (highlighted)
            tierRow(label: "NOW",
                    arrow: "circle.fill",
                    tier: now,
                    isCurrent: true,
                    color: Theme.accent)

            Rectangle()
                .fill(Theme.hairline.opacity(0.5))
                .frame(height: 1)

            // DESCEND
            tierRow(label: "DESCEND",
                    arrow: "arrow.down",
                    tier: descend,
                    isCurrent: false,
                    color: Color(red: 0.92, green: 0.40, blue: 0.36))   // soft red
        }
        .glassPanel(cornerRadius: 6, padding: 0)
    }

    private func tierRow(label: String,
                         arrow: String,
                         tier: PlayerTier,
                         isCurrent: Bool,
                         color: Color) -> some View {
        HStack(spacing: 14) {
            // Left status column
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: arrow)
                        .font(.system(size: 9, weight: .bold))
                    Text(label)
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2)
                }
                .foregroundStyle(color)
            }
            .frame(width: 96, alignment: .leading)

            // Tier label
            Text(tier.label)
                .font(.system(size: isCurrent ? 18 : 14,
                              weight: isCurrent ? .bold : .medium))
                .foregroundStyle(isCurrent ? Theme.primaryText : Theme.dim)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Score band
            Text(tier.bandText)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.dimmer)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, isCurrent ? 14 : 10)
        .background(isCurrent ? color.opacity(0.10) : Color.clear)
    }

    private var statGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 14),
            GridItem(.flexible(), spacing: 14),
            GridItem(.flexible(), spacing: 14)
        ], spacing: 14) {
            StatCard(label: "Avg / 9",
                     value: String(format: "%.1f", avgPer9),
                     sublabel: String(format: "%+.1f vs par · per 9 holes", avgToParPer9))
            StatCard(label: "Fairways",
                     value: String(format: "%.0f%%", avgFairway),
                     sublabel: "off the tee")
            StatCard(label: "GIR",
                     value: String(format: "%.0f%%", avgGir),
                     sublabel: "greens in regulation")
            StatCard(label: "Putts / Hole",
                     value: String(format: "%.2f", avgPutts),
                     sublabel: "short-game pulse")
            StatCard(label: "Low Round",
                     value: headlineLow.map { "\($0.round.totalScore)" } ?? "—",
                     sublabel: headlineLow?.typeLabel ?? "no rounds yet")
            StatCard(label: "Rounds",
                     value: "\(played.count)",
                     sublabel: roundsMixSublabel)
        }
    }

    private var roundsMixSublabel: String {
        switch (played18.count, played9.count) {
        case (0, _):  return "all 9-hole"
        case (_, 0):  return "all 18-hole"
        case let (a, b): return "\(a) × 18 · \(b) × 9"
        }
    }

    private var recentRoundsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel("Last 5 Rounds", subtitle: "Trajectory check · tap to open")

            VStack(spacing: 0) {
                ForEach(Array(played.prefix(5).enumerated()), id: \.element.id) { index, round in
                    Button {
                        selectedRound = round
                    } label: {
                        recentRoundRow(round)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if index < min(4, played.count - 1) {
                        Rectangle()
                            .fill(Theme.hairline)
                            .frame(height: 1)
                    }
                }
            }
            .glassPanel(padding: 0)
        }
    }

    private func recentRoundRow(_ round: Round) -> some View {
        let sign = round.scoreToPar >= 0 ? "+" : ""
        let typeBadge = round.holeCount == 9 ? "9" : "18"
        return HStack(spacing: 14) {
            CourseLogo(assetName: round.course?.logoAssetName, height: 26)
            VStack(alignment: .leading, spacing: 3) {
                Text(round.courseName.isEmpty ? "UNTITLED" : round.courseName.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(Theme.primaryText)
                HStack(spacing: 6) {
                    Text(round.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.dim)
                    Text("·").foregroundStyle(Theme.dim)
                    Text("\(typeBadge) HOLES")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(Theme.accent.opacity(0.8))
                }
            }
            Spacer()
            Text("\(round.totalScore)")
                .font(.system(size: 20, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Theme.primaryText)
            Text("\(sign)\(round.scoreToPar)")
                .font(.system(size: 13, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(round.scoreToPar <= 0 ? Theme.accent : Theme.dim)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Performance chart (all rounds, normalized per 9)

    enum ChartMetric: String, CaseIterable, Identifiable {
        case toPar = "vs Par / 9"
        case total = "Score / 9"
        case fairways = "Fairways %"
        case gir = "GIR %"
        case putts = "Putts/hole"

        var id: String { rawValue }

        var lowerIsBetter: Bool {
            switch self {
            case .toPar, .total, .putts: return true
            case .fairways, .gir:         return false
            }
        }
    }

    @State private var chartMetric: ChartMetric = .toPar

    /// All played rounds — 9- and 18-hole included, because vs-par and score
    /// are normalized per 9 and the other metrics are already per-hole.
    private var eligibleRoundsForChart: [Round] {
        played
            .filter { $0.holeCount > 0 && $0.totalScore > 0 }
            .sorted { $0.date < $1.date }
    }

    private var performanceSection: some View {
        let rounds = eligibleRoundsForChart
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .bottom) {
                SectionLabel(
                    "Performance",
                    subtitle: "Trend across your rounds · normalized per 9 holes"
                )
                Spacer()
                metricPicker
            }

            if rounds.isEmpty {
                Text("Log a round to see your trend.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.dim)
                    .frame(maxWidth: .infinity, minHeight: 140, alignment: .center)
                    .glassPanel(padding: 24)
            } else {
                performanceChart(rounds: rounds)
                    .frame(height: 220)
                    .glassPanel(padding: 18)
            }
        }
    }

    private var metricPicker: some View {
        HStack(spacing: 6) {
            ForEach(ChartMetric.allCases) { m in
                Button {
                    chartMetric = m
                } label: {
                    Text(m.rawValue.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(chartMetric == m ? .black : Theme.accent)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(chartMetric == m ? Theme.accent : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Theme.accent.opacity(0.6), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func performanceChart(rounds: [Round]) -> some View {
        Chart(rounds, id: \.id) { round in
            let value = metricValue(for: round)
            BarMark(
                x: .value("Date", round.date, unit: .day),
                y: .value(chartMetric.rawValue, value)
            )
            .foregroundStyle(barColor(for: value))
            .cornerRadius(2)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine().foregroundStyle(Theme.hairline)
                AxisValueLabel(format: .dateTime.month(.abbreviated).day(), anchor: .top)
                    .foregroundStyle(Theme.dim)
                    .font(.system(size: 9, weight: .medium))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine().foregroundStyle(Theme.hairline.opacity(0.5))
                AxisValueLabel()
                    .foregroundStyle(Theme.dim)
                    .font(.system(size: 9, weight: .medium))
            }
        }
    }

    private func metricValue(for round: Round) -> Double {
        switch chartMetric {
        case .toPar:    return round.scoreToParPer9
        case .total:    return round.scorePer9
        case .fairways: return round.fairwayPercentage
        case .gir:      return round.girPercentage
        case .putts:    return round.averagePutts
        }
    }

    /// Amber = good (better than average), dim = worse.
    /// For "lower is better" metrics we flip the test.
    private func barColor(for value: Double) -> Color {
        let values = eligibleRoundsForChart.map(metricValue)
        guard !values.isEmpty else { return Theme.accent }
        let avg = values.reduce(0, +) / Double(values.count)
        let isBetter = chartMetric.lowerIsBetter ? value <= avg : value >= avg
        return isBetter ? Theme.accent : Color.white.opacity(0.35)
    }

    // MARK: - Personal Bests
    //
    // Low Round and Best vs Par each appear twice — once for 18-hole rounds
    // and once for 9-hole rounds — so a clean 9-hole round doesn't fake out
    // an 18-hole personal best (and vice versa).

    private var personalBestsSection: some View {
        let b = bests
        return VStack(alignment: .leading, spacing: 14) {
            SectionLabel("Personal Bests", subtitle: "Records across all your rounds")

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 14),
                GridItem(.flexible(), spacing: 14),
                GridItem(.flexible(), spacing: 14)
            ], spacing: 14) {
                StatCard(
                    label: "Low 18",
                    value: low18.map { "\($0.totalScore)" } ?? "—",
                    sublabel: low18.map(Self.dateLine) ?? "no 18-hole rounds yet"
                )
                StatCard(
                    label: "Low 9",
                    value: low9.map { "\($0.totalScore)" } ?? "—",
                    sublabel: low9.map(Self.dateLine) ?? "no 9-hole rounds yet"
                )
                StatCard(
                    label: "Best vs Par (18)",
                    value: bestToPar18.map { Self.sign($0.scoreToPar) } ?? "—",
                    sublabel: bestToPar18.map(Self.dateLine) ?? "no 18-hole rounds yet"
                )
                StatCard(
                    label: "Best vs Par (9)",
                    value: bestToPar9.map { Self.sign($0.scoreToPar) } ?? "—",
                    sublabel: bestToPar9.map(Self.dateLine) ?? "no 9-hole rounds yet"
                )
                StatCard(
                    label: "Longest Drive",
                    value: b.longestDrive.map { "\($0.distance)" } ?? "—",
                    sublabel: b.longestDrive.map { "yds · \(Self.dateLine($0.round))" }
                        ?? "from shot log"
                )
                StatCard(
                    label: "Average Drive",
                    value: b.avgDrive.map { "\($0.distance)" } ?? "—",
                    sublabel: b.avgDrive.map { "yds · \($0.sampleCount) drives (trimmed)" }
                        ?? "need 3+ logged drives"
                )
                StatCard(
                    label: "Holes in One",
                    value: "\(b.holeInOneCount)",
                    sublabel: b.holeInOneCount == 0 ? "still chasing" : "pure magic"
                )
                StatCard(
                    label: "Eagles",
                    value: "\(b.eagleCount)",
                    sublabel: b.eagleCount == 0 ? "2 under par" : "swung hard, made them count"
                )
                StatCard(
                    label: "Birdies",
                    value: "\(b.birdieCount)",
                    sublabel: "1 under par"
                )
                StatCard(
                    label: "Pars",
                    value: "\(b.parCount)",
                    sublabel: "the backbone"
                )
                StatCard(
                    label: "Best Streak",
                    value: b.bestParOrBetterStreak > 0 ? "\(b.bestParOrBetterStreak)" : "—",
                    sublabel: b.bestParOrBetterStreak > 0
                        ? "par-or-better holes in a row"
                        : "log some pars"
                )
                StatCard(
                    label: "GIR Best",
                    value: b.bestGirCount > 0 ? "\(b.bestGirCount)" : "—",
                    sublabel: b.bestGirRound.map { r in
                        "\(b.bestGirCount) of \(r.holeCount) · \(Self.dateLine(r))"
                    } ?? "hit the most greens in one round"
                )
            }
        }
    }

    private static func sign(_ n: Int) -> String {
        if n == 0 { return "E" }
        return n > 0 ? "+\(n)" : "\(n)"
    }

    private static func dateLine(_ round: Round) -> String {
        let name = round.courseName.isEmpty ? "round" : round.courseName
        return "\(name) · \(round.date.formatted(date: .abbreviated, time: .omitted))"
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.bar")
                .font(.system(size: 42, weight: .ultraLight))
                .foregroundStyle(Theme.accent.opacity(0.6))
            Text("NO STATS YET")
                .font(.system(size: 12, weight: .semibold))
                .tracking(3)
                .foregroundStyle(Theme.primaryText)
            Text("Log a round and the numbers write themselves.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.dim)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .glassPanel(padding: 32)
    }
}

// MARK: - Personal Bests aggregate
//
// Hole-level counts only — Low Round and Best vs Par are split 18 vs 9
// directly in the StatsView (they're simple filter+min reductions and
// keeping them out of this struct avoids mixing round-length pools).

struct PersonalBests {
    var longestDrive: (distance: Int, round: Round)?
    var avgDrive: (distance: Int, sampleCount: Int)?
    var holeInOneCount: Int
    var eagleCount: Int
    var birdieCount: Int
    var parCount: Int
    var bestParOrBetterStreak: Int
    var bestGirCount: Int
    var bestGirRound: Round?

    static func compute(from rounds: [Round]) -> PersonalBests {
        var longestDrive: (distance: Int, round: Round)?
        var driverDistances: [Int] = []
        var hole1Count = 0
        var eagleCount = 0
        var birdieCount = 0
        var parCount = 0
        var bestStreak = 0
        var bestGir = 0
        var bestGirRound: Round?

        for round in rounds {
            let holes = round.sortedHoles

            // Scoring-level records (per-hole, so 9- and 18-hole rounds both count)
            var currentStreak = 0
            for hole in holes where hole.score > 0 && hole.par > 0 {
                let diff = hole.score - hole.par
                if hole.par == 3 && hole.score == 1 {
                    hole1Count += 1
                } else if diff == -2 {
                    eagleCount += 1
                } else if diff == -1 {
                    birdieCount += 1
                } else if diff == 0 {
                    parCount += 1
                }

                if diff <= 0 {
                    currentStreak += 1
                    bestStreak = max(bestStreak, currentStreak)
                } else {
                    currentStreak = 0
                }
            }

            // Best GIR in a single round (raw count — subtitle includes the
            // "of N" context so 9-hole and 18-hole rounds read clearly).
            let girCount = round.greensInRegulation
            if girCount > bestGir {
                bestGir = girCount
                bestGirRound = round
            }

            // Longest drive that finished in the fairway — scan shot logs.
            //
            // Landed in fairway is true if either:
            //   (a) the next logged shot's lie is .fairway (full shot log), OR
            //   (b) this is the last (or only) logged shot on the hole and the
            //       hole's scorecard flag `fairwayHit` is on.
            // That way a user who logs just the driver with a distance, and
            // who also checked the FIR box, still contributes a personal best.
            for hole in holes {
                let shots = hole.sortedShots
                for (i, shot) in shots.enumerated() {
                    guard shot.club == .driver, shot.distance > 0 else { continue }

                    driverDistances.append(shot.distance)

                    let landedFairway: Bool
                    if i + 1 < shots.count {
                        landedFairway = shots[i + 1].lie == .fairway
                    } else {
                        landedFairway = hole.fairwayHit
                    }

                    if landedFairway, shot.distance > (longestDrive?.distance ?? 0) {
                        longestDrive = (shot.distance, round)
                    }
                }
            }
        }

        // Trimmed average drive: drop the single longest and single shortest,
        // average the rest. Needs at least 3 samples (so one stays after trim).
        var avgDrive: (distance: Int, sampleCount: Int)?
        if driverDistances.count >= 3 {
            let sorted = driverDistances.sorted()
            let trimmed = sorted.dropFirst().dropLast()
            let sum = trimmed.reduce(0, +)
            avgDrive = (Int((Double(sum) / Double(trimmed.count)).rounded()), trimmed.count)
        }

        return PersonalBests(
            longestDrive: longestDrive,
            avgDrive: avgDrive,
            holeInOneCount: hole1Count,
            eagleCount: eagleCount,
            birdieCount: birdieCount,
            parCount: parCount,
            bestParOrBetterStreak: bestStreak,
            bestGirCount: bestGir,
            bestGirRound: bestGirRound
        )
    }
}
