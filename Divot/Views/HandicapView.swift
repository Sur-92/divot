import SwiftUI
import SwiftData

struct HandicapView: View {
    @Query(sort: \Round.date, order: .reverse) private var rounds: [Round]
    @State private var selectedRound: Round?

    // MARK: - Pool construction (USGA World Handicap System)
    //
    // The pool is built from the last 20 "handicap entries". An entry is either:
    //   • one complete 18-hole round → diff = round.scoreDifferential
    //   • one PAIR of complete 9-hole rounds, combined chronologically →
    //     diff = firstNine.scoreDifferential + secondNine.scoreDifferential
    //
    // Per WHS Rule 5.1 / Appendix E: a 9-hole score is held aside until the
    // player's next 9-hole score arrives; then the two 9-hole differentials
    // are summed into a single 18-hole-equivalent differential. A lone
    // (unpaired) 9-hole round is "pending" and does not enter the pool.

    /// One row in the handicap differential pool.
    struct PoolEntry: Identifiable {
        let id = UUID()
        /// 18-hole-equivalent differential.
        let differential: Double
        /// One round (for 18-hole entries) or two 9-hole rounds paired chronologically.
        let rounds: [Round]
        /// Representative date — later of the pair, or the round itself.
        let date: Date
        /// True if this entry was built from two 9-hole rounds paired up.
        var isPaired: Bool { rounds.count == 2 }
    }

    private var complete: [Round] {
        // Reconstructed rounds ARE included. Their totals are accurate
        // (synthetic hole scores were distributed to match the known
        // total) and the distribution algorithm caps each synthetic
        // hole at par + 2 — exactly the net-double-bogey ceiling the
        // WHS adjusted-gross calculation uses. So adjusted gross equals
        // raw total on these rounds and the differential is correct.
        rounds.filter { $0.isComplete && !$0.isArchived }
    }

    /// 9-hole rounds that don't have a partner yet — oldest leftover first.
    /// These are "pending" and shown in a separate section.
    private var pendingNines: [Round] {
        let nines = complete.filter { $0.holeCount == 9 }
            .sorted { $0.date < $1.date }   // oldest first
        // Pair chronologically: if the count is odd, the last one is pending.
        return nines.count.isMultiple(of: 2) ? [] : [nines.last!]
    }

    /// Full pool, newest entries first, up to 20.
    private var pool: [PoolEntry] {
        var entries: [PoolEntry] = []

        // 18-hole rounds go in one-for-one.
        for r in complete where r.holeCount == 18 {
            entries.append(PoolEntry(
                differential: r.scoreDifferential,
                rounds: [r],
                date: r.date
            ))
        }

        // 9-hole rounds: pair chronologically (oldest two together, next two, …).
        // An odd trailing round stays out of the pool (it's in pendingNines).
        let nines = complete.filter { $0.holeCount == 9 }
            .sorted { $0.date < $1.date }   // oldest first
        let pairedCount = nines.count - (nines.count.isMultiple(of: 2) ? 0 : 1)
        var i = 0
        while i + 1 < pairedCount + 1 && i + 1 < nines.count {
            let a = nines[i]
            let b = nines[i + 1]
            entries.append(PoolEntry(
                differential: a.scoreDifferential + b.scoreDifferential,
                rounds: [a, b],
                date: max(a.date, b.date)
            ))
            i += 2
        }

        // Newest first, cap at 20.
        return Array(entries.sorted { $0.date > $1.date }.prefix(20))
    }

    private var differentials: [Double] {
        pool.map(\.differential).sorted()
    }

    /// USGA WHS table: number of lowest differentials to average,
    /// based on the size of the pool of acceptable score-equivalents.
    /// (One entry = one 18-hole round OR one paired set of 9s.)
    private var useBest: Int {
        switch pool.count {
        case 0...2:   return 0
        case 3, 4, 5: return 1
        case 6:       return 2
        case 7...8:   return 2
        case 9...11:  return 3
        case 12...14: return 4
        case 15...16: return 5
        case 17...18: return 6
        case 19:      return 7
        default:      return 8
        }
    }

    /// USGA WHS small-pool adjustment applied AFTER averaging the
    /// best N differentials. Per the official Rules of Handicapping
    /// (Rule 5.2b table):
    ///   3 diffs → −2.0
    ///   4 diffs → −1.0
    ///   6 diffs → −1.0
    ///   any other size → 0
    /// The adjustment compensates for the smaller, less-representative
    /// pool early in a player's record.
    private var smallPoolAdjustment: Double {
        switch pool.count {
        case 3:      return -2.0
        case 4:      return -1.0
        case 6:      return -1.0
        default:     return 0
        }
    }

    private var handicapIndex: Double? {
        guard useBest > 0 else { return nil }
        let best = differentials.prefix(useBest)
        let avg = best.reduce(0, +) / Double(useBest)
        return avg + smallPoolAdjustment
    }

    private var trend: (delta: Double, improving: Bool)? {
        guard pool.count >= 6 else { return nil }
        let recent = pool.prefix(3).map(\.differential)
        let older = pool.dropFirst(3).prefix(3).map(\.differential)
        guard recent.count == 3, older.count == 3 else { return nil }
        let rAvg = recent.reduce(0, +) / 3
        let oAvg = older.reduce(0, +) / 3
        let delta = rAvg - oAvg
        return (abs(delta), delta < 0)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    heroCard

                    if !pool.isEmpty {
                        differentialSection
                    }
                    if !pendingNines.isEmpty {
                        pendingNinesSection
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
            Text("HANDICAP")
                .font(.system(size: 11, weight: .semibold))
                .tracking(4)
                .foregroundStyle(Theme.accent)
            Text("USGA index · 18s and paired 9s feed the pool.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.dim)
            Rectangle()
                .fill(Theme.accent)
                .frame(width: 28, height: 1.5)
                .padding(.top, 2)
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text("INDEX")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(3)
                            .foregroundStyle(Theme.dim)
                        HelpDot(title: "Handicap Index", text: indexHelpText)
                    }
                    if let idx = handicapIndex {
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text(String(format: "%.1f", idx))
                                .font(.system(size: 96, weight: .bold))
                                .monospacedDigit()
                                .foregroundStyle(Theme.primaryText)
                                .shadow(color: Theme.accent.opacity(0.45), radius: 20)
                            VStack(alignment: .leading, spacing: 4) {
                                Rectangle()
                                    .fill(Theme.accent)
                                    .frame(width: 28, height: 2)
                                Text("HANDICAP")
                                    .font(.system(size: 10, weight: .semibold))
                                    .tracking(3)
                                    .foregroundStyle(Theme.accent)
                                Text("INDEX")
                                    .font(.system(size: 10, weight: .semibold))
                                    .tracking(3)
                                    .foregroundStyle(Theme.accent)
                            }
                            .padding(.bottom, 10)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("—")
                                .font(.system(size: 96, weight: .bold))
                                .foregroundStyle(Theme.dim)
                            Text(emptyIndexHint)
                                .font(.system(size: 10, weight: .semibold))
                                .tracking(2)
                                .foregroundStyle(Theme.accent.opacity(0.7))
                        }
                    }
                }
                Spacer()
                if let trend {
                    trendBadge(trend)
                }
            }

            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 1)
                .padding(.top, 20)
                .padding(.bottom, 16)

            HStack(spacing: 24) {
                heroStat(label: "Using", value: "\(useBest)",
                         sub: useBest == 1 ? "round" : "rounds",
                         help: usingHelpText)
                divider
                heroStat(label: "Pool", value: "\(pool.count)",
                         sub: "of last 20",
                         help: poolHelpText)
                divider
                heroStat(label: "Best Diff",
                         value: differentials.first.map { String(format: "%.1f", $0) } ?? "—",
                         sub: "low mark",
                         help: bestDiffHelpText)
                if smallPoolAdjustment < 0 {
                    divider
                    heroStat(label: "WHS Adj.",
                             value: String(format: "%.1f", smallPoolAdjustment),
                             sub: "small-pool credit",
                             help: whsAdjHelpText)
                }
                Spacer()
            }
        }
        .glassPanel(cornerRadius: 6, padding: 28)
    }

    private var emptyIndexHint: String {
        // Tailored nudge based on what you have.
        let eighteens = complete.filter { $0.holeCount == 18 }.count
        let nines = complete.filter { $0.holeCount == 9 }.count
        let poolSize = pool.count

        if poolSize == 0 {
            if nines == 1 && eighteens == 0 {
                return "ONE MORE 9 OR AN 18 TO START"
            }
            return "NEED 3 ROUNDS (18S OR PAIRED 9S)"
        }
        return "NEED \(3 - poolSize) MORE \(poolSize == 2 ? "ROUND" : "ROUNDS")"
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.hairline)
            .frame(width: 1, height: 36)
    }

    private func heroStat(label: String,
                          value: String,
                          sub: String,
                          help: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Theme.dim)
                if let help {
                    HelpDot(title: label, text: help)
                }
            }
            Text(value)
                .font(.system(size: 22, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Theme.primaryText)
            Text(sub.uppercased())
                .font(.system(size: 8, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(Theme.accent.opacity(0.8))
        }
    }

    // MARK: - Help texts

    private var usingHelpText: String {
        """
        How many of your lowest score differentials get averaged to \
        produce your handicap index. The count scales with your pool \
        size: 1 of 3-5, 2 of 6-8, 3 of 9-11, 4 of 12-14, 5 of 15-16, \
        6 of 17-18, 7 of 19, 8 of 20. Bigger pool, more representative \
        average.
        """
    }

    private var poolHelpText: String {
        """
        Your acceptable score-equivalents — a rolling window of your \
        most recent 20 entries. One full 18-hole round counts as one \
        entry. Two 9-hole rounds pair chronologically (oldest with \
        next-oldest) and combine into one 18-hole-equivalent entry. \
        As you log more rounds, older entries roll out the back.
        """
    }

    private var bestDiffHelpText: String {
        """
        The lowest score differential in your pool. Differential = \
        (113 / Slope) × (Adjusted Gross − Course Rating). It \
        normalizes a round across course difficulty so a 90 at a \
        hard track and a 90 at an easy track aren't treated the \
        same. Lower is better. Adjusted Gross caps each hole at \
        net double bogey (par + 2 + handicap strokes).
        """
    }

    private var whsAdjHelpText: String {
        """
        USGA WHS small-pool credit applied after averaging. With \
        just 3 differentials WHS subtracts 2.0; with 4 or 6 it \
        subtracts 1.0. The adjustment compensates for an early, \
        less-representative record — without it, a single low \
        differential would dominate. The credit goes to 0.0 once \
        your pool reaches 7+.
        """
    }

    private var indexHelpText: String {
        """
        Your USGA Handicap Index — a portable measure of your \
        playing ability that travels between courses. Computed by \
        averaging the lowest N of your last 20 score differentials, \
        then applying the small-pool adjustment if the pool has \
        fewer than 7 entries. Lower is better. A 0.0 is scratch; \
        the higher the number, the more strokes you get on a given \
        course relative to par.
        """
    }

    private func trendBadge(_ trend: (delta: Double, improving: Bool)) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: trend.improving ? "arrow.down.right" : "arrow.up.right")
                    .font(.system(size: 11, weight: .bold))
                Text(String(format: "%.1f", trend.delta))
                    .font(.system(size: 14, weight: .semibold))
                    .monospacedDigit()
            }
            .foregroundStyle(trend.improving ? Theme.accent : Theme.dim)
            Text(trend.improving ? "TRENDING DOWN" : "TRENDING UP")
                .font(.system(size: 8, weight: .semibold))
                .tracking(2)
                .foregroundStyle(trend.improving ? Theme.accent : Theme.dim)
        }
    }

    // MARK: - Differential list

    private var differentialSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(
                "Score Differentials",
                subtitle: "Best \(useBest) highlighted · tap a row to open that round"
            )

            VStack(spacing: 0) {
                ForEach(Array(pool.enumerated()), id: \.element.id) { index, entry in
                    let sorted = differentials
                    let countsTowardIndex = sorted.prefix(useBest)
                        .contains { abs($0 - entry.differential) < 0.001 }
                    poolRow(entry, counts: countsTowardIndex)
                    if index < pool.count - 1 {
                        Rectangle().fill(Theme.hairline).frame(height: 1)
                    }
                }
            }
            .glassPanel(padding: 0)
        }
    }

    @ViewBuilder
    private func poolRow(_ entry: PoolEntry, counts: Bool) -> some View {
        if entry.isPaired {
            pairedRow(entry, counts: counts)
        } else if let r = entry.rounds.first {
            Button {
                selectedRound = r
            } label: {
                singleRow(r, diff: entry.differential, counts: counts)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func singleRow(_ round: Round, diff: Double, counts: Bool) -> some View {
        HStack(spacing: 14) {
            Rectangle()
                .fill(counts ? Theme.accent : Color.clear)
                .frame(width: 2, height: 34)
            CourseLogo(assetName: round.course?.logoAssetName, height: 24)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(round.courseName.isEmpty ? "UNTITLED" : round.courseName.uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(Theme.primaryText)
                    Text("·").foregroundStyle(Theme.dim)
                    Text("18")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(Theme.accent.opacity(0.85))
                }
                Text(round.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.dim)
            }
            Spacer()
            Text(String(format: "%.1f", diff))
                .font(.system(size: 16, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(counts ? Theme.accent : Theme.primaryText)
                .frame(width: 56, alignment: .trailing)
        }
        .padding(.trailing, 16)
        .padding(.vertical, 12)
    }

    private func pairedRow(_ entry: PoolEntry, counts: Bool) -> some View {
        // Show both 9-hole rounds stacked, with the combined diff on the right.
        let a = entry.rounds[0]
        let b = entry.rounds[1]
        return HStack(alignment: .top, spacing: 14) {
            Rectangle()
                .fill(counts ? Theme.accent : Color.clear)
                .frame(width: 2, height: 52)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("PAIRED 9s")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .overlay(RoundedRectangle(cornerRadius: 2)
                            .stroke(Theme.accent.opacity(0.5), lineWidth: 1))
                    Spacer(minLength: 0)
                }
                pairedMini(a)
                pairedMini(b)
            }
            Spacer()
            Text(String(format: "%.1f", entry.differential))
                .font(.system(size: 16, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(counts ? Theme.accent : Theme.primaryText)
                .frame(width: 56, alignment: .trailing)
        }
        .padding(.trailing, 16)
        .padding(.vertical, 12)
    }

    private func pairedMini(_ round: Round) -> some View {
        Button {
            selectedRound = round
        } label: {
            HStack(spacing: 10) {
                CourseLogo(assetName: round.course?.logoAssetName, height: 18)
                Text(round.courseName.isEmpty ? "UNTITLED" : round.courseName.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.primaryText)
                Text("·").foregroundStyle(Theme.dim)
                Text(round.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.dim)
                Text("·").foregroundStyle(Theme.dim)
                Text(String(format: "%.1f", round.scoreDifferential))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.dimmer)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Pending 9-hole rounds (waiting for a partner)

    private var pendingNinesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(
                "Waiting for Partner",
                subtitle: "9-hole rounds pair chronologically — next 9 you play combines with this one"
            )
            VStack(spacing: 0) {
                ForEach(Array(pendingNines.enumerated()), id: \.element.id) { index, round in
                    Button {
                        selectedRound = round
                    } label: {
                        pendingRow(round)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if index < pendingNines.count - 1 {
                        Rectangle().fill(Theme.hairline).frame(height: 1)
                    }
                }
            }
            .glassPanel(padding: 0)
        }
    }

    private func pendingRow(_ round: Round) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "hourglass")
                .font(.system(size: 12))
                .foregroundStyle(Theme.accent.opacity(0.8))
                .frame(width: 18)
            CourseLogo(assetName: round.course?.logoAssetName, height: 24)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(round.courseName.isEmpty ? "UNTITLED" : round.courseName.uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(Theme.primaryText)
                    Text("·").foregroundStyle(Theme.dim)
                    Text("9")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(Theme.accent.opacity(0.85))
                }
                Text(round.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.dim)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f", round.scoreDifferential))
                    .font(.system(size: 14, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.primaryText)
                Text("9-HOLE DIFF")
                    .font(.system(size: 8, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(Theme.dim)
            }
            .frame(width: 84, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Help dot (circled question mark with tap-to-show popover)

private struct HelpDot: View {
    let title: String
    let text: String

    @State private var showing = false

    var body: some View {
        Button {
            showing.toggle()
        } label: {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.accent.opacity(0.85))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(title)
        .popover(isPresented: $showing, arrowEdge: .top) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.accent)
                    Text(title.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2.5)
                        .foregroundStyle(Theme.accent)
                }

                Rectangle()
                    .fill(LinearGradient(
                        colors: [Theme.accent.opacity(0.5), Theme.hairline, .clear],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(height: 1)

                Text(text)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.primaryText)
                    .lineSpacing(2)
                    .frame(maxWidth: 320, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(
                ZStack {
                    Color.black.opacity(0.92)
                    LinearGradient(
                        colors: [
                            Color(red: 0.06, green: 0.14, blue: 0.30).opacity(0.55),
                            Color(red: 0.04, green: 0.10, blue: 0.22).opacity(0.65)
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                }
            )
        }
    }
}
