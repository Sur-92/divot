import SwiftUI
import SwiftData

struct RoundDetailView: View {
    @Bindable var round: Round
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false
    @State private var showDatePicker = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM, d, yyyy"
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                ScorecardView(round: round)
                    .glassPanel(padding: 14)

                VStack(alignment: .leading, spacing: 14) {
                    SectionLabel("Summary", subtitle: "The numbers this round wrote")
                    summaryPanel
                }

                VStack(alignment: .leading, spacing: 14) {
                    SectionLabel("Notes")
                    TextEditor(text: $round.notes)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.primaryText)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 100)
                        .glassPanel(padding: 10)
                }

                removeButton
                    .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .navigationTitle(round.courseName.isEmpty ? "New Round" : round.courseName)
        .onAppear { backfillHoleData() }
        .alert(alertTitle, isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            if round.isArchived {
                Button("Restore") { restoreRound() }
            } else {
                Button("Archive") { archiveRound() }
            }
            Button("Delete Forever", role: .destructive) { deleteRound() }
        } message: {
            Text(round.isArchived
                 ? "Restore this round to your active list, or delete it forever. Deleting removes every hole and shot and can't be undone."
                 : "Archive hides this round from your list, stats, and handicap but keeps the data safe — you can restore it anytime. Deleting removes every hole and shot and can't be undone.")
        }
    }

    private var alertTitle: String {
        let name = round.courseName.isEmpty ? "this round" : round.courseName
        return round.isArchived
            ? "Restore or delete \(name)?"
            : "Archive or delete \(name)?"
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 22) {
            // Big course logo on the far left, spans the three rows to its right
            CourseLogo(assetName: round.course?.logoAssetName, height: 120, corner: 10)

            // Three rows: name / date+tees+rating+slope / SCORECARD
            VStack(alignment: .leading, spacing: 12) {
                // Row 1: course name + round-type badge
                HStack(spacing: 12) {
                    Text(round.courseName.isEmpty ? "Untitled Round" : round.courseName)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(1)
                    if round.roundType != .full18 {
                        Text(round.roundType.shortBadge)
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 3).fill(Theme.accent))
                    }
                }

                // Row 2: date (editable) + tees + rating/slope on one line
                HStack(spacing: 22) {
                    dateButton
                    teeBadge
                    ratingSlopeBadge
                }

                // Row 3: SCORECARD label (replaces the separate section label below)
                VStack(alignment: .leading, spacing: 6) {
                    Text("SCORECARD")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(4)
                        .foregroundStyle(Theme.accent)
                    Rectangle()
                        .fill(Theme.accent)
                        .frame(width: 28, height: 1.5)
                }
            }

            Spacer()
        }
    }

    // MARK: - Remove button (below Notes, left-aligned)

    private var removeButton: some View {
        Button { showDeleteConfirm = true } label: {
            HStack(spacing: 8) {
                Image(systemName: round.isArchived ? "archivebox.fill" : "trash")
                    .font(.system(size: 11, weight: .bold))
                Text(round.isArchived ? "ARCHIVED" : "REMOVE…")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
            }
            .foregroundStyle(Color.red.opacity(0.85))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.red.opacity(0.6), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .help(round.isArchived
              ? "Restore or delete this archived round"
              : "Archive or delete this round")
    }

    // MARK: - Date

    private var dateButton: some View {
        HStack(spacing: 8) {
            Text("DATE")
                .font(.system(size: 9, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Theme.dim)
            Button {
                showDatePicker.toggle()
            } label: {
                Text(Self.dateFormatter.string(from: round.date))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.primaryText)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Click to change date")
            .popover(isPresented: $showDatePicker, arrowEdge: .bottom) {
                DatePicker("", selection: $round.date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding(16)
                    .frame(width: 300, height: 300)
            }
        }
    }

    // MARK: - Header badges

    private var teeBadge: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(teeSwatchColor)
                .frame(width: 18, height: 18)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                )
            Text(round.tees.isEmpty ? "NO TEE" : round.tees.uppercased())
                .font(.system(size: 13, weight: .bold))
                .tracking(2)
                .foregroundStyle(Theme.primaryText)
        }
    }

    private var ratingSlopeBadge: some View {
        HStack(spacing: 14) {
            miniStat(label: "RATING",
                     value: round.courseRating > 0
                        ? String(format: "%.1f", round.courseRating)
                        : "—")
            Rectangle()
                .fill(Theme.hairline)
                .frame(width: 1, height: 24)
            miniStat(label: "SLOPE",
                     value: round.slopeRating > 0 ? "\(round.slopeRating)" : "—")
        }
    }

    private func miniStat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .tracking(1.8)
                .foregroundStyle(Theme.dim)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.primaryText)
        }
    }

    /// Maps a tee name to a visual swatch color.
    private var teeSwatchColor: Color {
        let s = round.tees.lowercased()
        if s.isEmpty { return Color.gray.opacity(0.5) }
        if s.contains("blue")   { return Color.blue }
        if s.contains("white")  { return Color(white: 0.95) }
        if s.contains("yellow") { return Color.yellow }
        if s.contains("red")    { return Color.red }
        if s.contains("gold")   { return Color(red: 0.90, green: 0.70, blue: 0.18) }
        if s.contains("silver") { return Color(white: 0.75) }
        if s.contains("bronze") { return Color(red: 0.72, green: 0.48, blue: 0.25) }
        if s.contains("black")  { return Color.black }
        if s.contains("green")  { return Color.green }
        if s.contains("pink")   { return Color.pink }
        if s.contains("purple") { return Color.purple }
        return Theme.accent
    }

    private func deleteRound() {
        let label = round.courseName.isEmpty ? "Untitled Round" : round.courseName
        let id = round.idempotencyKey
        modelContext.delete(round)
        try? modelContext.save()
        AuditService.shared.log(
            entityType: "Round",
            entityID: id,
            entityLabel: label,
            action: "delete",
            summary: "Deleted round at \(label)"
        )
        dismiss()
    }

    private func archiveRound() {
        round.isArchived = true
        try? modelContext.save()
        let label = round.courseName.isEmpty ? "Untitled Round" : round.courseName
        AuditService.shared.log(
            entityType: "Round",
            entityID: round.idempotencyKey,
            entityLabel: label,
            action: "archive",
            summary: "Archived round at \(label)"
        )
        dismiss()
    }

    private func restoreRound() {
        round.isArchived = false
        try? modelContext.save()
        let label = round.courseName.isEmpty ? "Untitled Round" : round.courseName
        AuditService.shared.log(
            entityType: "Round",
            entityID: round.idempotencyKey,
            entityLabel: label,
            action: "restore",
            summary: "Restored round at \(label)"
        )
    }

    /// Repair an existing round: re-link to course by name if the
    /// relationship was broken by an earlier course delete/re-seed,
    /// and fill any missing yardage/handicap snapshots from the course.
    private func backfillHoleData() {
        if round.course == nil, !round.courseName.isEmpty {
            var fd = FetchDescriptor<Course>()
            let target = round.courseName
            fd.predicate = #Predicate { $0.name == target }
            if let found = try? modelContext.fetch(fd).first {
                round.course = found
            }
        }

        guard let course = round.course else { return }
        let tee = course.tees.first { $0.name.caseInsensitiveCompare(round.tees) == .orderedSame }

        var changed = false
        for hole in round.sortedHoles {
            if hole.yardage == 0, let t = tee {
                let y = t.yardage(forHole: hole.number)
                if y > 0 { hole.yardage = y; changed = true }
            }
            if hole.handicapIndex == 0,
               let ch = course.holes.first(where: { $0.number == hole.number }) {
                if ch.handicapIndex > 0 {
                    hole.handicapIndex = ch.handicapIndex
                    changed = true
                }
            }
        }
        if changed { try? modelContext.save() }
    }

    private var summaryPanel: some View {
        let sign = round.scoreToPar >= 0 ? "+" : ""
        let penalties = round.holes.reduce(0) { $0 + $1.penalties }
        let bunkers = round.holes.reduce(0) { $0 + $1.bunkerShots }
        return LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            StatCard(label: "Total",
                     value: "\(round.totalScore)",
                     sublabel: round.totalScore > 0 ? "\(sign)\(round.scoreToPar) vs par" : "in progress")
            StatCard(label: "Fairways",
                     value: "\(round.fairwaysHit)/\(round.fairwayAttempts)",
                     sublabel: String(format: "%.0f%%", round.fairwayPercentage))
            StatCard(label: "GIR",
                     value: "\(round.greensInRegulation)/\(round.holes.count)",
                     sublabel: String(format: "%.0f%%", round.girPercentage))
            StatCard(label: "Putts",
                     value: "\(round.totalPutts)",
                     sublabel: String(format: "%.1f / hole", round.averagePutts))
            StatCard(label: "Penalties",
                     value: "\(penalties)",
                     sublabel: penalties == 1 ? "stroke" : "strokes")
            StatCard(label: "Sand",
                     value: "\(bunkers)",
                     sublabel: bunkers == 1 ? "bunker shot" : "bunker shots")
            if round.isComplete {
                StatCard(label: "Differential",
                         value: String(format: "%.1f", round.scoreDifferential),
                         sublabel: "handicap feed")
            }
        }
    }
}
