import SwiftUI
import SwiftData
import CoreLocation

struct RoundDetailView: View {
    @Bindable var round: Round
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false
    @State private var showDatePicker = false
    @State private var showTimePicker = false
    @State private var loadingWeather = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM, d, yyyy"
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
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
                    SectionLabel("Conditions", subtitle: "Course, situation, and how you felt")
                    lostBallsRow
                    ConditionsSection(round: round)
                        .glassPanel(padding: 14)
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
        .task(id: round.teeTimeMinutes) { await loadWeather() }
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
                    teeTimeButton
                    teeBadge
                    ratingSlopeBadge
                }

                weatherBadge

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

    private var teeTimeButton: some View {
        HStack(spacing: 8) {
            Text("TEE TIME")
                .font(.system(size: 9, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Theme.dim)
            Button {
                showTimePicker.toggle()
            } label: {
                Text(round.hasTeeTime ? Self.timeFormatter.string(from: teeTimeBinding.wrappedValue) : "Set")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(round.hasTeeTime ? Theme.primaryText : Theme.accent)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Set your front-9 tee time for time-of-play weather (≈2 hrs per nine)")
            .popover(isPresented: $showTimePicker, arrowEdge: .bottom) {
                VStack(spacing: 8) {
                    DatePicker("", selection: teeTimeBinding, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.stepperField)
                        .labelsHidden()
                    Text("≈ 2 hrs per nine")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.dim)
                }
                .padding(16)
                .frame(width: 240)
            }
        }
    }

    private var teeTimeBinding: Binding<Date> {
        Binding(
            get: {
                let cal = Calendar.current
                var c = cal.dateComponents([.year, .month, .day], from: round.date)
                c.hour = round.hasTeeTime ? round.teeTimeMinutes / 60 : 9
                c.minute = round.hasTeeTime ? round.teeTimeMinutes % 60 : 0
                return cal.date(from: c) ?? round.date
            },
            set: { newDate in
                let cal = Calendar.current
                let h = cal.component(.hour, from: newDate)
                let m = cal.component(.minute, from: newDate)
                round.teeTimeMinutes = h * 60 + m
                round.frontCode = -1          // force a fresh per-nine fetch
                round.backCode = -1
                try? modelContext.save()
            }
        )
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

    // MARK: - Weather

    @ViewBuilder
    private var weatherBadge: some View {
        if round.hasNineWeather {
            HStack(spacing: 18) {
                nineChip(label: nineLabel(front: true), code: round.frontCode,
                         temp: round.frontTempF, wind: round.frontWindMph)
                if round.roundType == .full18 && round.backCode >= 0 {
                    nineChip(label: "BACK 9", code: round.backCode,
                             temp: round.backTempF, wind: round.backWindMph)
                }
            }
        } else if round.hasWeather {
            HStack(spacing: 10) {
                Image(systemName: WeatherService.symbol(for: round.weatherCode))
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 20)
                Text("\(Int(round.weatherHighF.rounded()))° / \(Int(round.weatherLowF.rounded()))°")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.primaryText)
                Text("·").foregroundStyle(Theme.dimmer)
                Text(WeatherService.label(for: round.weatherCode))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.dim)
                Text("·").foregroundStyle(Theme.dimmer)
                Text("\(Int(round.weatherWindMph.rounded())) mph")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.dim)
                if round.weatherPrecipIn >= 0.05 {
                    Text("·").foregroundStyle(Theme.dimmer)
                    Text(String(format: "%.2f″", round.weatherPrecipIn))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.dim)
                }
            }
        } else if loadingWeather {
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Looking up the weather…")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.dim)
            }
        }
    }

    private func nineLabel(front: Bool) -> String {
        switch round.roundType {
        case .full18: return front ? "FRONT 9" : "BACK 9"
        case .front9: return "FRONT 9"
        case .back9:  return "BACK 9"
        }
    }

    private func nineChip(label: String, code: Int, temp: Double, wind: Double) -> some View {
        HStack(spacing: 8) {
            Image(systemName: WeatherService.symbol(for: code))
                .font(.system(size: 14))
                .foregroundStyle(Theme.accent)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 8, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(Theme.dim)
                Text("\(Int(temp.rounded()))° · \(Int(wind.rounded())) mph")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.primaryText)
            }
        }
    }

    private func loadWeather() async {
        guard !loadingWeather else { return }
        if round.hasTeeTime {
            // Time-of-play, per-nine conditions (≈2 hrs per nine).
            guard !round.hasNineWeather else { return }
            loadingWeather = true; defer { loadingWeather = false }
            guard let coord = await weatherLocation() else { return }
            guard let day = await WeatherService.fetchHourly(
                lat: coord.latitude, lon: coord.longitude, date: round.date) else { return }
            let startH = round.teeTimeMinutes / 60
            if let f = day.at(startH + 1) {                      // mid front nine
                round.frontCode = f.code; round.frontTempF = f.tempF; round.frontWindMph = f.windMph
            }
            if round.roundType == .full18, let b = day.at(startH + 3) {   // mid back nine
                round.backCode = b.code; round.backTempF = b.tempF; round.backWindMph = b.windMph
            }
            try? modelContext.save()
        } else {
            // No tee time → daily summary fallback.
            guard !round.hasWeather else { return }
            loadingWeather = true; defer { loadingWeather = false }
            guard let coord = await weatherLocation() else { return }
            if let w = await WeatherService.fetch(
                lat: coord.latitude, lon: coord.longitude, date: round.date) {
                round.weatherCode = w.code
                round.weatherHighF = w.highF
                round.weatherLowF = w.lowF
                round.weatherWindMph = w.windMph
                round.weatherPrecipIn = w.precipIn
                try? modelContext.save()
            }
        }
    }

    /// Best available coordinate for the round: saved course center, else a
    /// hole's tee, else geocode the course address.
    private func weatherLocation() async -> CLLocationCoordinate2D? {
        if let c = round.course?.coordinate { return c }
        if let ch = round.course?.holes.first(where: { $0.hasTee }) { return ch.teeCoordinate }
        if let addr = round.course?.address, !addr.isEmpty {
            let geocoder = CLGeocoder()
            if let loc = (try? await geocoder.geocodeAddressString(addr))?.first?.location {
                round.course?.latitude = loc.coordinate.latitude
                round.course?.longitude = loc.coordinate.longitude
                try? modelContext.save()
                return loc.coordinate
            }
        }
        return nil
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

    private var lostBallsRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle.dotted")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.accent.opacity(0.85))
            Text("LOST BALLS")
                .font(.system(size: 11, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Theme.dim)
            Spacer()
            stepperButton(systemName: "minus") {
                if round.lostBalls > 0 { round.lostBalls -= 1 }
            }
            Text("\(round.lostBalls)")
                .font(.system(size: 18, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(round.lostBalls > 0 ? Theme.primaryText : Theme.dim)
                .frame(minWidth: 34)
            stepperButton(systemName: "plus") {
                round.lostBalls += 1
            }
        }
        .glassPanel(padding: 12)
    }

    private func stepperButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.accent)
                .frame(width: 30, height: 30)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.accent.opacity(0.6), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var summaryPanel: some View {
        let penalties = round.holes.reduce(0) { $0 + $1.penalties }
        let bunkers = round.holes.reduce(0) { $0 + $1.bunkerShots }
        return LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            StatCard(label: "Total",
                     value: "\(round.totalScore)",
                     sublabel: round.totalScore > 0 ? "\(round.scoreToPar.toParText) vs par" : "in progress")
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
