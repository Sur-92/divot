import SwiftUI
import SwiftData

/// Pro-scorecard-style grid:
/// rows = tees + par + handicap, cols = holes 1-9, OUT, 10-18, IN, TOT.
struct YardagesScorecard: View {
    @Bindable var course: Course

    private let cellWidth: CGFloat = 40
    private let totalCellWidth: CGFloat = 52
    private let labelWidth: CGFloat = 82

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(spacing: 0) {
                headerRow
                Rectangle().fill(Theme.hairline).frame(height: 1)

                ForEach(Array(course.sortedTees.enumerated()), id: \.element.id) { index, tee in
                    TeeYardageRow(tee: tee,
                                  cellWidth: cellWidth,
                                  totalCellWidth: totalCellWidth,
                                  labelWidth: labelWidth)
                    if index < course.sortedTees.count - 1 {
                        Rectangle().fill(Theme.hairline.opacity(0.5)).frame(height: 1)
                    }
                }

                Rectangle().fill(Theme.hairline).frame(height: 1)
                parRow
                Rectangle().fill(Theme.hairline.opacity(0.5)).frame(height: 1)
                handicapRow
            }
        }
        .glassPanel(padding: 12)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 0) {
            Text("HOLE")
                .frame(width: labelWidth, alignment: .leading)
                .padding(.leading, 8)
            ForEach(1...9, id: \.self) { n in
                headerCell("\(n)", width: cellWidth)
            }
            headerCell("OUT", width: totalCellWidth, accent: true)
            ForEach(10...18, id: \.self) { n in
                headerCell("\(n)", width: cellWidth)
            }
            headerCell("IN",  width: totalCellWidth, accent: true)
            headerCell("TOT", width: totalCellWidth, accent: true)
        }
        .font(.system(size: 10, weight: .semibold))
        .tracking(1.5)
        .foregroundStyle(Theme.accent)
        .padding(.vertical, 8)
    }

    private func headerCell(_ text: String, width: CGFloat, accent: Bool = false) -> some View {
        Text(text)
            .frame(width: width)
            .foregroundStyle(accent ? Theme.primaryText : Theme.accent)
    }

    // MARK: - Par row

    private var parRow: some View {
        let holes = course.sortedHoles
        let front = Array(holes.prefix(9))
        let back = Array(holes.dropFirst(9))
        let frontTotal = front.reduce(0) { $0 + $1.par }
        let backTotal = back.reduce(0) { $0 + $1.par }
        let total = frontTotal + backTotal

        return HStack(spacing: 0) {
            Text("PAR")
                .frame(width: labelWidth, alignment: .leading)
                .padding(.leading, 8)
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundStyle(Theme.accent)
            ForEach(front) { h in
                readonlyCell("\(h.par)", width: cellWidth)
            }
            totalCell("\(frontTotal)", width: totalCellWidth)
            ForEach(back) { h in
                readonlyCell("\(h.par)", width: cellWidth)
            }
            totalCell("\(backTotal)", width: totalCellWidth)
            totalCell("\(total)", width: totalCellWidth)
        }
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.04))
    }

    // MARK: - Handicap row

    private var handicapRow: some View {
        let holes = course.sortedHoles
        let front = Array(holes.prefix(9))
        let back = Array(holes.dropFirst(9))

        return HStack(spacing: 0) {
            Text("HDCP")
                .frame(width: labelWidth, alignment: .leading)
                .padding(.leading, 8)
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundStyle(Theme.accent)
            ForEach(front) { h in
                handicapCell(hole: h, width: cellWidth)
            }
            Color.clear.frame(width: totalCellWidth)
            ForEach(back) { h in
                handicapCell(hole: h, width: cellWidth)
            }
            Color.clear.frame(width: totalCellWidth)
            Color.clear.frame(width: totalCellWidth)
        }
        .padding(.vertical, 8)
    }

    private func handicapCell(hole: CourseHole, width: CGFloat) -> some View {
        TextField("", value: Binding(
            get: { hole.handicapIndex },
            set: { hole.handicapIndex = $0 }
        ), format: .number)
        .textFieldStyle(.plain)
        .multilineTextAlignment(.center)
        .font(.system(size: 11, weight: .medium, design: .monospaced))
        .foregroundStyle(hole.handicapIndex > 0 ? Theme.dim : Theme.dimmer)
        .frame(width: width)
    }

    private func readonlyCell(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .foregroundStyle(Theme.primaryText)
            .frame(width: width)
    }

    private func totalCell(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundStyle(Theme.accent)
            .frame(width: width)
    }
}

// MARK: - Editable row for one tee

struct TeeYardageRow: View {
    @Bindable var tee: CourseTee
    let cellWidth: CGFloat
    let totalCellWidth: CGFloat
    let labelWidth: CGFloat

    private var frontTotal: Int {
        (0..<min(9, tee.yardages.count)).reduce(0) { $0 + tee.yardages[$1] }
    }
    private var backTotal: Int {
        guard tee.yardages.count > 9 else { return 0 }
        return (9..<min(18, tee.yardages.count)).reduce(0) { $0 + tee.yardages[$1] }
    }
    private var grandTotal: Int { frontTotal + backTotal }

    var body: some View {
        HStack(spacing: 0) {
            Text(tee.name.uppercased())
                .frame(width: labelWidth, alignment: .leading)
                .padding(.leading, 8)
                .font(.system(size: 11, weight: .bold))
                .tracking(2)
                .foregroundStyle(Theme.primaryText)

            ForEach(0..<9, id: \.self) { i in
                yardageCell(index: i)
            }
            computedCell(frontTotal)
            ForEach(9..<18, id: \.self) { i in
                yardageCell(index: i)
            }
            computedCell(backTotal)
            computedCell(grandTotal)
        }
        .padding(.vertical, 6)
    }

    private func yardageCell(index: Int) -> some View {
        TextField("", value: yardageBinding(for: index), format: .number.grouping(.never))
            .textFieldStyle(.plain)
            .multilineTextAlignment(.center)
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(value(at: index) > 0 ? Theme.primaryText : Theme.dimmer)
            .frame(width: cellWidth)
    }

    private func computedCell(_ value: Int) -> some View {
        Text(value > 0 ? "\(value)" : "—")
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(Theme.accent)
            .frame(width: totalCellWidth)
    }

    private func value(at index: Int) -> Int {
        tee.yardages.indices.contains(index) ? tee.yardages[index] : 0
    }

    private func yardageBinding(for index: Int) -> Binding<Int> {
        Binding(
            get: { value(at: index) },
            set: { newValue in
                // Pad to 18 entries before writing.
                while tee.yardages.count < 18 {
                    tee.yardages.append(0)
                }
                tee.yardages[index] = max(0, newValue)
                tee.yardage = tee.yardages.reduce(0, +)
            }
        )
    }
}
