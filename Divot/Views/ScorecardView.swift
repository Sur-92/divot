import SwiftUI
import SwiftData

/// Vertical scorecard — one row per hole, inline NOTES, snapshot YDS + HDCP.
struct ScorecardView: View {
    @Bindable var round: Round
    @State private var shotsHole: Hole?

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(Theme.hairline).frame(height: 1)
            ForEach(Array(round.sortedHoles.enumerated()), id: \.element.id) { index, hole in
                HoleRow(hole: hole,
                        onLogShots: { shotsHole = hole },
                        isAlternate: index.isMultiple(of: 2))
            }
            Rectangle().fill(Theme.hairline).frame(height: 1)
            totalsRow
        }
        .sheet(item: $shotsHole) { hole in
            HoleShotsView(hole: hole)
        }
    }

    // MARK: - Column header

    private var header: some View {
        HStack(spacing: 0) {
            headerCell("HOLE",  width: 44)
            headerCell("YDS",   width: 56)
            headerCell("PAR",   width: 44)
            headerCell("HDCP",  width: 46)
            headerCell("SCORE", width: 58)
            headerCell("FIR",   width: 44)
            headerCell("GIR",   width: 44)
            headerCell("PUTTS", width: 56)
            headerCell("PEN",   width: 40)
            headerCell("SAND",  width: 42)
            headerCell("DRIVE", width: 54)
            Text("NOTES")
                .font(.system(size: 9, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Theme.accent)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 12)
            headerCell("+/-",   width: 46)
        }
        .padding(.vertical, 10)
    }

    private func headerCell(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .tracking(2)
            .foregroundStyle(Theme.accent)
            .frame(width: width, alignment: .center)
    }

    // MARK: - Totals

    private var totalsRow: some View {
        let holes = round.sortedHoles
        let totalYards = holes.reduce(0) { $0 + $1.yardage }
        let totalPar = round.totalPar
        let totalScore = round.totalScore
        let fairways = round.fairwaysHit
        let greens = round.greensInRegulation
        let putts = round.totalPutts
        let penalties = holes.reduce(0) { $0 + $1.penalties }
        let bunkers = holes.reduce(0) { $0 + $1.bunkerShots }
        let toPar = round.scoreToPar

        return HStack(spacing: 0) {
            totalCell("TOT", width: 44)
            totalNumber(totalYards > 0 ? "\(totalYards)" : "—", width: 56)
            totalNumber("\(totalPar)", width: 44)
            Color.clear.frame(width: 46)
            totalNumber(totalScore > 0 ? "\(totalScore)" : "—", width: 58, bold: true)
            totalNumber(fairways > 0 ? "\(fairways)" : "—", width: 44)
            totalNumber(greens > 0 ? "\(greens)" : "—", width: 44)
            totalNumber(putts > 0 ? "\(putts)" : "—", width: 56)
            totalNumber(penalties > 0 ? "\(penalties)" : "—", width: 40)
            totalNumber(bunkers > 0 ? "\(bunkers)" : "—", width: 42)
            Color.clear.frame(width: 54)
            Color.clear.frame(maxWidth: .infinity)
            let sign = toPar >= 0 ? "+" : ""
            let text = totalScore > 0 ? "\(sign)\(toPar)" : "—"
            Text(text)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(toPar <= 0 && totalScore > 0 ? Theme.accent : Theme.primaryText)
                .frame(width: 46, alignment: .center)
        }
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.04))
    }

    private func totalCell(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .tracking(2)
            .foregroundStyle(Theme.accent)
            .frame(width: width, alignment: .center)
    }

    private func totalNumber(_ text: String, width: CGFloat, bold: Bool = false) -> some View {
        Text(text)
            .font(.system(size: bold ? 14 : 12, weight: .bold, design: .monospaced))
            .foregroundStyle(Theme.primaryText)
            .frame(width: width, alignment: .center)
    }
}

// MARK: - One-hole row

struct HoleRow: View {
    @Bindable var hole: Hole
    var onLogShots: () -> Void
    var isAlternate: Bool = false

    private var scoreColor: Color {
        guard hole.score > 0 else { return Theme.primaryText }
        return ScoreMark.color(for: hole.score - hole.par)
    }

    /// Putts color convention:
    ///   0 (chip-in) → light blue · 1 → light green · 2 → white
    ///   3 → red · 4+ → black (paired with bold weight at the call site)
    private var puttsColor: Color {
        switch hole.putts {
        case ..<0:  return Theme.primaryText
        case 0:     return Color(red: 0.55, green: 0.80, blue: 0.98)    // light blue
        case 1:     return Color(red: 0.55, green: 0.88, blue: 0.60)    // light green
        case 2:     return Theme.primaryText                            // white
        case 3:     return Color(red: 0.92, green: 0.35, blue: 0.32)    // red
        default:    return .black                                       // 4+
        }
    }

    private var scoreToParText: String {
        guard hole.score > 0 else { return "" }
        let diff = hole.score - hole.par
        if diff == 0 { return "E" }
        return diff > 0 ? "+\(diff)" : "\(diff)"
    }

    var body: some View {
        HStack(spacing: 0) {
            // HOLE # (tappable → shots log)
            Button(action: onLogShots) {
                VStack(spacing: 2) {
                    Text("\(hole.number)")
                        .font(.system(size: 11, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.dim)
                    if hole.shots.isEmpty {
                        Color.clear.frame(height: 6)
                    } else {
                        HStack(spacing: 2) {
                            Circle().fill(Theme.accent).frame(width: 4, height: 4)
                            Text("\(hole.shots.count)")
                                .font(.system(size: 8, weight: .bold))
                                .monospacedDigit()
                                .foregroundStyle(Theme.accent)
                        }
                    }
                }
                .frame(width: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Log shots for hole \(hole.number)")

            // YDS (read-only snapshot)
            Text(hole.yardage > 0 ? "\(hole.yardage)" : "—")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(hole.yardage > 0 ? Theme.primaryText : Theme.dimmer)
                .frame(width: 56, alignment: .center)

            // PAR (editable)
            inlineInt(value: $hole.par, width: 44)

            // HDCP (read-only, from course)
            Text(hole.handicapIndex > 0 ? "\(hole.handicapIndex)" : "—")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(hole.handicapIndex > 0 ? Theme.dim : Theme.dimmer)
                .frame(width: 46, alignment: .center)

            // SCORE (editable) — pro-style circle/square notation
            ZStack {
                ScoreMark(score: hole.score, par: hole.par)
                    .allowsHitTesting(false)
                inlineInt(value: $hole.score, width: 58,
                          color: scoreColor, bold: true, size: 14)
            }
            .frame(width: 58)

            // FIR
            DotCheckbox(isOn: $hole.fairwayHit, disabled: hole.par < 4)
                .frame(width: 44)

            // GIR
            DotCheckbox(isOn: $hole.greenInRegulation)
                .frame(width: 44)

            // PUTTS (editable) — color-coded: 0 chip-in, 1 one-putt, 2 neutral, 3 warn, 4+ bad
            inlineInt(value: $hole.putts, width: 56,
                      color: puttsColor,
                      bold: hole.putts >= 4)

            // PEN (editable) — red when > 0
            inlineInt(value: $hole.penalties, width: 40,
                      color: hole.penalties > 0 ? Color(red: 0.92, green: 0.35, blue: 0.32) : Theme.dimmer)

            // SAND (editable) — amber when > 0
            inlineInt(value: $hole.bunkerShots, width: 42,
                      color: hole.bunkerShots > 0 ? Theme.accent : Theme.dimmer)

            // DRIVE (tap → hole sheet to plot the landing)
            Button(action: onLogShots) {
                DriveGlyph(hole: hole)
                    .frame(width: 54)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Tap to plot your drive")

            // NOTES (flex)
            TextField("", text: $hole.notes, prompt: Text("shot notes").foregroundStyle(Theme.dimmer))
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(Theme.primaryText)
                .padding(.leading, 12)
                .padding(.trailing, 8)
                .frame(maxWidth: .infinity, alignment: .leading)

            // +/-
            Text(scoreToParText)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(scoreColor)
                .frame(width: 46, alignment: .center)
        }
        .padding(.vertical, 6)
        .background(isAlternate ? Color.white.opacity(0.04) : Color.clear)
    }

    private func inlineInt(value: Binding<Int>,
                           width: CGFloat,
                           color: Color = Theme.primaryText,
                           bold: Bool = false,
                           size: CGFloat = 12) -> some View {
        TextField("", value: value, format: .number)
            .textFieldStyle(.plain)
            .multilineTextAlignment(.center)
            .font(.system(size: size, weight: bold ? .bold : .medium, design: .monospaced))
            .foregroundStyle(color)
            .frame(width: width)
    }
}

// MARK: - Score mark (pro scorecard shapes)
//
// Convention:
//   score − par ≤ −2   → double circle (eagle / albatross)
//   score − par  = −1   → single circle (birdie)
//   score − par  =  0   → no shape     (par)
//   score − par  = +1   → single square (bogey)
//   score − par  = +2   → double square (double bogey)
//   score − par ≥ +3   → triple square (triple bogey or worse)

struct ScoreMark: View {
    let score: Int
    let par: Int

    private let outerSize: CGFloat = 30
    private let middleSize: CGFloat = 26
    private let innerSize: CGFloat = 22
    private let outerWidth: CGFloat = 1.8
    private let middleWidth: CGFloat = 1.4
    private let innerWidth: CGFloat = 1.2

    /// Color-by-score convention used by both the score number and the mark:
    ///   eagle (−2+) → light blue · birdie (−1) → light green · par → white
    ///   bogey (+1) → muted yellow · double (+2) → orange · triple+ → red
    static func color(for diff: Int) -> Color {
        if diff <= -2 { return Color(red: 0.55, green: 0.80, blue: 0.98) }   // light blue
        if diff == -1 { return Color(red: 0.55, green: 0.88, blue: 0.60) }   // light green
        if diff ==  0 { return Theme.primaryText }                           // white
        if diff ==  1 { return Color(red: 0.95, green: 0.88, blue: 0.40) }   // yellow
        if diff ==  2 { return Color(red: 0.98, green: 0.55, blue: 0.22) }   // orange
        return               Color(red: 0.92, green: 0.35, blue: 0.32)       // red (+3+)
    }

    private var shapeColor: Color {
        ScoreMark.color(for: score - par)
    }

    var body: some View {
        Group {
            if score == 0 || par == 0 {
                EmptyView()
            } else {
                let diff = score - par
                if diff <= -2 {
                    doubleCircle
                } else if diff == -1 {
                    singleCircle
                } else if diff == 0 {
                    EmptyView()
                } else if diff == 1 {
                    singleSquare
                } else if diff == 2 {
                    doubleSquare
                } else {
                    tripleSquare
                }
            }
        }
    }

    private var singleCircle: some View {
        Circle()
            .stroke(shapeColor, lineWidth: outerWidth)
            .frame(width: outerSize, height: outerSize)
    }

    private var doubleCircle: some View {
        ZStack {
            Circle()
                .stroke(shapeColor, lineWidth: outerWidth)
                .frame(width: outerSize, height: outerSize)
            Circle()
                .stroke(shapeColor, lineWidth: innerWidth)
                .frame(width: innerSize, height: innerSize)
        }
    }

    private var singleSquare: some View {
        Rectangle()
            .stroke(shapeColor, lineWidth: outerWidth)
            .frame(width: outerSize, height: outerSize)
    }

    private var doubleSquare: some View {
        ZStack {
            Rectangle()
                .stroke(shapeColor, lineWidth: outerWidth)
                .frame(width: outerSize, height: outerSize)
            Rectangle()
                .stroke(shapeColor.opacity(0.8), lineWidth: innerWidth)
                .frame(width: innerSize, height: innerSize)
        }
    }

    private var tripleSquare: some View {
        ZStack {
            Rectangle()
                .stroke(shapeColor, lineWidth: outerWidth)
                .frame(width: outerSize, height: outerSize)
            Rectangle()
                .stroke(shapeColor.opacity(0.85), lineWidth: middleWidth)
                .frame(width: middleSize, height: middleSize)
            Rectangle()
                .stroke(shapeColor.opacity(0.70), lineWidth: innerWidth)
                .frame(width: innerSize, height: innerSize)
        }
    }
}

// MARK: - Dot checkbox (amber filled circle when on — full-cell hit target)

struct DotCheckbox: View {
    @Binding var isOn: Bool
    var disabled: Bool = false

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            Circle()
                .fill(isOn ? Theme.accent : Color.clear)
                .overlay(
                    Circle().stroke(isOn ? Theme.accent : Theme.hairlineStrong,
                                    lineWidth: 1.5)
                )
                .frame(width: 16, height: 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.25 : 1)
    }
}
