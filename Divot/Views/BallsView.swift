import SwiftUI

/// Comparison matrix of golf balls — top section is a tight,
/// scannable head-to-head; bottom section expands each ball into a
/// detail card with the longer take. Read-only static content;
/// data lives in Services/Balls.swift.
struct BallsView: View {
    private var balls: [Ball] { Balls.all }

    // MARK: - Sorting (multi-column, click-to-layer)

    enum SortColumn: Equatable { case mfr, model, price, build, cover, comp, driver, greenside, feel, fit }

    /// Ordered active sort keys + direction. Empty = curated default order.
    /// Activation order IS the priority — the first key is the primary sort,
    /// later keys break ties.
    @State private var sorts: [(col: SortColumn, asc: Bool)] = []

    /// Cycle a column through: off → ascending → descending → off. A newly
    /// activated column is appended at the lowest priority.
    private func cycleSort(_ col: SortColumn) {
        if let i = sorts.firstIndex(where: { $0.col == col }) {
            if sorts[i].asc { sorts[i].asc = false } else { sorts.remove(at: i) }
        } else {
            sorts.append((col, true))
        }
    }

    /// 1-based priority of a column, or nil if it isn't in the sort.
    private func sortPriority(_ col: SortColumn) -> Int? {
        sorts.firstIndex(where: { $0.col == col }).map { $0 + 1 }
    }
    private func sortDirection(_ col: SortColumn) -> Bool? {
        sorts.first(where: { $0.col == col })?.asc
    }

    /// Rows in the active multi-key sort order, or the curated default.
    private var sortedBalls: [Ball] {
        guard !sorts.isEmpty else { return Balls.all }
        return Balls.all.sorted { a, b in
            for s in sorts {
                let c = compare(a, b, by: s.col)
                if c != 0 { return s.asc ? c < 0 : c > 0 }
            }
            return false   // equal across all keys → stable
        }
    }

    /// Three-way comparison for one column: negative if a<b, 0 if equal.
    private func compare(_ a: Ball, _ b: Ball, by col: SortColumn) -> Int {
        switch col {
        case .mfr:       return order(a.brand.localizedCaseInsensitiveCompare(b.brand))
        case .model:     return order(a.model.localizedCaseInsensitiveCompare(b.model))
        case .cover:     return order(a.cover.rawValue.localizedCaseInsensitiveCompare(b.cover.rawValue))
        case .price:     return a.pricePerDozen - b.pricePerDozen
        case .build:     return a.pieces - b.pieces
        case .comp:      return a.compression - b.compression
        case .driver:    return a.driverSpin - b.driverSpin
        case .greenside: return a.greensideSpin - b.greensideSpin
        case .feel:      return a.feel - b.feel
        case .fit:       return rank(a.fit) - rank(b.fit)
        }
    }
    private func order(_ r: ComparisonResult) -> Int {
        r == .orderedAscending ? -1 : (r == .orderedDescending ? 1 : 0)
    }

    private func rank(_ f: FitStatus) -> Int {
        switch f {
        case .gamer: return 0; case .benchmark: return 1; case .alt: return 2
        case .sleeper: return 3; case .avoid: return 4
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    matrixSection
                    Rectangle().fill(Theme.hairline).frame(height: 1)
                    detailsSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                Text("BALLS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(4)
                    .foregroundStyle(Theme.accent)
                Text("Comparison matrix · matched to this player's profile.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.dim)
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: 28, height: 1.5)
                    .padding(.top, 2)
            }
            Spacer()
            Text("\(balls.count) BALLS")
                .font(.system(size: 9, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Theme.dim)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 14)
    }

    // MARK: - Matrix

    private var matrixSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .bottom) {
                SectionLabel(
                    "Matrix",
                    subtitle: sorts.isEmpty
                        ? "Tap a header to sort; tap more headers to layer (①②③)"
                        : "Tap a header again to flip direction, a third time to drop it"
                )
                Spacer()
                if !sorts.isEmpty {
                    Button {
                        sorts.removeAll()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 9, weight: .semibold))
                            Text("CLEAR SORT")
                                .font(.system(size: 9, weight: .semibold))
                                .tracking(1)
                        }
                        .foregroundStyle(Theme.dim)
                    }
                    .buttonStyle(.plain)
                    .help("Reset to the default order")
                }
            }

            VStack(spacing: 0) {
                matrixHeaderRow
                Rectangle().fill(Theme.hairline.opacity(0.6)).frame(height: 1)
                ForEach(Array(sortedBalls.enumerated()), id: \.element.model) { idx, ball in
                    matrixRow(ball: ball, isAlternate: idx.isMultiple(of: 2))
                    if idx < sortedBalls.count - 1 {
                        Rectangle().fill(Theme.hairline.opacity(0.4)).frame(height: 1)
                    }
                }
            }
            .background(Color.black.opacity(0.35))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.hairline, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }

    // Column widths balance an 1100px window. Model column flexes.
    private let widthMfr: CGFloat = 112
    private let widthPrice: CGFloat = 73
    private let widthPieces: CGFloat = 65
    private let widthCover: CGFloat = 104
    private let widthComp: CGFloat = 78
    private let widthSpin: CGFloat = 86
    private let widthFeel: CGFloat = 90
    private let widthFit: CGFloat = 117

    private var matrixHeaderRow: some View {
        HStack(spacing: 8) {
            metricHeader("MFR", sort: .mfr, help: HelpText.manufacturer)
                .frame(width: widthMfr, alignment: .leading)
            metricHeader("MODEL", sort: .model, help: HelpText.model)
                .frame(maxWidth: .infinity, alignment: .leading)
            metricHeader("$/DZ", sort: .price, help: HelpText.price)
                .frame(width: widthPrice, alignment: .trailing)
            metricHeader("BUILD", sort: .build, help: HelpText.build)
                .frame(width: widthPieces, alignment: .center)
            metricHeader("COVER", sort: .cover, help: HelpText.cover)
                .frame(width: widthCover, alignment: .leading)
            metricHeader("COMP", sort: .comp, help: HelpText.compression)
                .frame(width: widthComp, alignment: .center)
            metricHeader("DRIVER", sort: .driver, help: HelpText.driverSpin)
                .frame(width: widthSpin, alignment: .center)
            metricHeader("GREEN", sort: .greenside, help: HelpText.greensideSpin)
                .frame(width: widthSpin, alignment: .center)
            metricHeader("FEEL", sort: .feel, help: HelpText.feel)
                .frame(width: widthFeel, alignment: .center)
            metricHeader("FIT", sort: .fit, help: HelpText.fit)
                .frame(width: widthFit, alignment: .center)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    /// Tracks which column's help popover is open. Only one open at a
    /// time; clicking a second info dot moves the popover to that one.
    @State private var activeHelp: String?

    /// Column header: a clickable LABEL that sorts the matrix by this
    /// column (click again to flip direction; an arrow shows the active
    /// direction), plus an info dot that opens the metric explanation.
    private func metricHeader(_ label: String, sort: SortColumn, help: String) -> some View {
        let isShowing = Binding<Bool>(
            get: { activeHelp == help },
            set: { showing in
                if showing { activeHelp = help }
                else if activeHelp == help { activeHelp = nil }
            }
        )
        let direction = sortDirection(sort)       // nil = inactive
        let priority = sortPriority(sort)
        return HStack(spacing: 4) {
            Button {
                cycleSort(sort)
            } label: {
                HStack(spacing: 3) {
                    Text(label)
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.8)
                        .foregroundStyle(Theme.accent)
                    Image(systemName: direction == nil
                          ? "arrow.up.arrow.down"
                          : (direction! ? "arrow.up" : "arrow.down"))
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(direction == nil ? Theme.dim.opacity(0.5) : Theme.accent)
                    // Priority badge — only when layering (2+ active sorts).
                    if sorts.count > 1, let p = priority {
                        Text("\(p)")
                            .font(.system(size: 7, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(.black)
                            .frame(width: 12, height: 12)
                            .background(Circle().fill(Theme.accent))
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Sort by \(label) — tap to layer")

            Button {
                isShowing.wrappedValue.toggle()
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(activeHelp == help ? Theme.accent : Theme.dim)
                    .contentShape(Rectangle().inset(by: -4))
            }
            .buttonStyle(.plain)
            .help(help)
            .popover(isPresented: isShowing, arrowEdge: .bottom) {
                helpPopover(title: label, body: help)
            }
        }
    }

    /// Reusable styled card shown inside a column's info popover.
    private func helpPopover(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundStyle(Theme.accent)
            Text(body)
                .font(.system(size: 12))
                .foregroundStyle(Theme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
        .padding(16)
        .frame(width: 300)
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

    /// Tooltip copy for each column. Plain-English, one-paragraph each.
    private enum HelpText {
        static let manufacturer = """
        The brand that makes the ball. Brand alone doesn't define \
        performance — cover, construction, and compression do — but it's \
        handy for grouping (Titleist, Srixon, Callaway, DTC names, etc.).
        """
        static let model = """
        The specific model within the brand. This is the line that \
        actually determines behavior — e.g. Titleist's Pro V1 vs Pro V1x, \
        or Srixon's Z-Star vs Q-Star Tour, differ a lot despite the badge.
        """
        static let price = """
        Current price per dozen in USD. Direct-to-consumer brands \
        (Legato, Snell, Vice) skip retail markup; major-brand prices \
        reflect MSRP and typical street price.
        """
        static let build = """
        Number of layers in the ball. More pieces (4-5) let engineers \
        tune each layer for a specific job — high-compression core for \
        distance, soft mantle for spin, urethane skin for greenside \
        feel. Three-piece balls do the same with fewer trade-offs.
        """
        static let cover = """
        Outer material. Urethane is soft, grabs grooves, and produces \
        high greenside spin — the mark of a tour ball. Surlyn / ionomer \
        is harder, more durable, kills wedge spin — used on distance \
        and value balls.
        """
        static let compression = """
        How much the ball deforms at impact (0-110 scale). Lower = \
        softer feel, energy transfer at slower swing speeds (good \
        for sub-90 mph). Higher = firmer, optimal at 100+ mph. A \
        mid-90s number matches the ~100 mph driver swing in this app.
        """
        static let driverSpin = """
        Backspin off the driver, on a six-step scale: V.Low · Low · M.Low \
        · M.High · High · V.High. Lower spin = less side spin on off-line \
        strikes and more rollout (good for a push/slice); higher = more \
        carry and height, but amplifies any curve. Where measured, driver \
        spin comes from MyGolfSpy's 2025 robot test; otherwise estimated \
        from cover and construction.
        """
        static let greensideSpin = """
        How much the ball checks up on pitch, chip, and wedge shots, on a \
        six-step scale: V.Low … V.High. V.High grabs and stops where it \
        lands (urethane tour balls); V.Low rolls out with little bite \
        (hard distance balls). For a scramble-heavy game, more is what \
        saves pars.
        """
        static let feel = """
        Sensation off the face and putter, on a six-step scale: V.Soft · \
        Soft · M.Soft · M.Firm · Firm · V.Firm. Soft = muted, \
        "marshmallow" (low compression); firm = sharp click (high \
        compression). Pure preference — not a performance number. Tracks \
        measured compression closely.
        """
        static let fit = """
        How well this ball matches THIS player's profile (14 hcp, \
        ~100 mph swing, push pattern, forged irons). GAMER = \
        currently in the bag. BENCHMARK = the standard others get \
        judged against. ALT = strong alternative, trial-worthy. \
        SLEEPER = less obvious pick worth trying. AVOID = wrong \
        fit for this profile.
        """
    }

    private func matrixRow(ball: Ball, isAlternate: Bool) -> some View {
        HStack(spacing: 8) {
            // Manufacturer
            Text(ball.brand.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.dim)
                .lineLimit(1)
                .frame(width: widthMfr, alignment: .leading)

            // Model — flex column
            Text(ball.model)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.primaryText)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Price
            Text("$\(ball.pricePerDozen)")
                .font(.system(size: 13, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Theme.primaryText)
                .frame(width: widthPrice, alignment: .trailing)

            // Build / pieces
            Text("\(ball.pieces)pc")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.dim)
                .frame(width: widthPieces, alignment: .center)

            // Cover
            Text(ball.cover.rawValue)
                .font(.system(size: 11))
                .foregroundStyle(Theme.dim)
                .frame(width: widthCover, alignment: .leading)

            // Compression
            Text("\(ball.compression)")
                .font(.system(size: 12, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(Theme.primaryText)
                .frame(width: widthComp, alignment: .center)

            // Driver spin (V.Low … V.High)
            scaleChip(ball.driverSpin, .spin)
                .frame(width: widthSpin)

            // Greenside spin (V.Low … V.High)
            scaleChip(ball.greensideSpin, .spin)
                .frame(width: widthSpin)

            // Feel (V.Soft … V.Firm)
            scaleChip(ball.feel, .feel)
                .frame(width: widthFeel)

            // Fit status
            fitBadge(ball.fit)
                .frame(width: widthFit)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(isAlternate ? Color.white.opacity(0.02) : Color.clear)
    }

    /// Which named scale a chip uses — spin (low→high) or feel (soft→firm).
    enum ScaleKind {
        case spin, feel
        /// Labels for levels 1…6.
        var labels: [String] {
            switch self {
            case .spin: return ["V.Low", "Low", "M.Low", "M.High", "High", "V.High"]
            case .feel: return ["V.Soft", "Soft", "M.Soft", "M.Firm", "Firm", "V.Firm"]
            }
        }
    }

    /// A 1–6 rating shown as a compact filled gauge: a bar that fills left-
    /// to-right in proportion to the level, with a graduated NAME centered
    /// (V.Low … V.High for spin, V.Soft … V.Firm for feel). More fill =
    /// higher (more spin / firmer). The value still sorts numerically.
    private func scaleChip(_ value: Int, _ kind: ScaleKind) -> some View {
        let v = max(1, min(6, value))
        let frac = Double(v) / 6.0
        return ZStack {
            GeometryReader { geo in
                Theme.accent.opacity(0.32)
                    .frame(width: geo.size.width * frac)
            }
            Text(kind.labels[v - 1])
                .font(.system(size: 9.5, weight: .bold))
                .foregroundStyle(Theme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 18)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Theme.hairline, lineWidth: 1))
    }

    @ViewBuilder
    private func fitBadge(_ fit: FitStatus) -> some View {
        switch fit {
        case .gamer:
            Text(fit.rawValue)
                .font(.system(size: 9, weight: .bold))
                .tracking(1.8)
                .foregroundStyle(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 2).fill(Theme.accent))
        case .benchmark:
            Text(fit.rawValue)
                .font(.system(size: 9, weight: .bold))
                .tracking(1.8)
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(Theme.accent, lineWidth: 1))
        case .alt:
            Text(fit.rawValue)
                .font(.system(size: 9, weight: .bold))
                .tracking(1.8)
                .foregroundStyle(Theme.dim)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(Theme.hairline, lineWidth: 1))
        case .sleeper:
            Text(fit.rawValue)
                .font(.system(size: 9, weight: .bold))
                .tracking(1.8)
                .foregroundStyle(Theme.dim)
                .italic()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(Theme.dim.opacity(0.5), lineWidth: 1))
        case .avoid:
            Text(fit.rawValue)
                .font(.system(size: 9, weight: .bold))
                .tracking(1.8)
                .foregroundStyle(Color.red.opacity(0.75))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.red.opacity(0.5), lineWidth: 1))
        }
    }

    // MARK: - Details

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel("Detail", subtitle: "Why each ball lands where it does")
            VStack(spacing: 14) {
                ForEach(Array(balls.enumerated()), id: \.offset) { _, ball in
                    detailCard(ball: ball)
                }
            }
        }
    }

    private func detailCard(ball: Ball) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(ball.brand.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Theme.dim)
                Text(ball.model)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                fitBadge(ball.fit)
            }

            HStack(spacing: 6) {
                Image(systemName: "person.fill")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.accent.opacity(0.8))
                Text("BEST FOR")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.8)
                    .foregroundStyle(Theme.accent.opacity(0.8))
                Text(ball.bestFor)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.primaryText.opacity(0.85))
            }

            Text(ball.take)
                .font(.system(size: 13))
                .foregroundStyle(Theme.primaryText.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
        .padding(16)
        .background(Color.black.opacity(0.35))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.hairline, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

#Preview {
    BallsView()
        .frame(width: 1100, height: 700)
        .background(Color.black)
}
