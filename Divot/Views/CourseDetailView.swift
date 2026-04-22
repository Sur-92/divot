import SwiftUI
import SwiftData

struct CourseDetailView: View {
    @Bindable var course: Course
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                VStack(alignment: .leading, spacing: 14) {
                    SectionLabel("Course Info")
                    courseInfoPanel
                }

                VStack(alignment: .leading, spacing: 14) {
                    SectionLabel("Holes & Par", subtitle: "Tap a par to edit")
                    holesPanel
                }

                VStack(alignment: .leading, spacing: 14) {
                    SectionLabel("Yardages", subtitle: "Per-hole yards by tee · par · handicap")
                    YardagesScorecard(course: course)
                }

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .center) {
                        SectionLabel("Tees", subtitle: "Name · Yardage · Rating · Slope")
                        Spacer()
                        Button(action: addTee) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 10, weight: .bold))
                                Text("ADD TEE")
                                    .font(.system(size: 9, weight: .semibold))
                                    .tracking(2)
                            }
                            .foregroundStyle(Theme.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .overlay(RoundedRectangle(cornerRadius: 3)
                                .stroke(Theme.accent, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    teesPanel
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .navigationTitle(course.name.isEmpty ? "New Course" : course.name)
        .alert("Delete \(course.name.isEmpty ? "this course" : course.name)?",
               isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Course", role: .destructive) { deleteCourse() }
        } message: {
            Text("This removes the course, its holes, tees, and yardages. Existing rounds played at this course will keep their own data but lose the course link. This can't be undone.")
        }
        .onDisappear {
            syncTotalPar()
            try? modelContext.save()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 18) {
            // Course logo (if provided)
            CourseLogo(assetName: course.logoAssetName, height: 96, corner: 8)

            VStack(alignment: .leading, spacing: 6) {
                Text("COURSE")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(4)
                    .foregroundStyle(Theme.accent)
                Text(course.name.isEmpty ? "Untitled Course" : course.name)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Theme.primaryText)
                HStack(spacing: 10) {
                    Text("PAR \(course.computedPar)")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(Theme.accent)
                    Text("·")
                        .foregroundStyle(Theme.dim)
                    Text("\(course.holes.count) HOLES")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(Theme.dim)
                    Text("·")
                        .foregroundStyle(Theme.dim)
                    Text("\(course.tees.count) TEES")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(Theme.dim)
                }
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: 28, height: 1.5)
                    .padding(.top, 4)
            }

            Spacer()

            // Book Tee Time button (only when a booking URL is set)
            if let bookingURL = URL(string: course.bookingURL), !course.bookingURL.isEmpty {
                Button {
                    NSWorkspace.shared.open(bookingURL)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("BOOK TEE TIME")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(2)
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 3).fill(Theme.accent))
                }
                .buttonStyle(.plain)
                .help("Open \(course.bookingURL) in your browser")
            }

            Button { showDeleteConfirm = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                        .font(.system(size: 11, weight: .bold))
                    Text("DELETE")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2)
                }
                .foregroundStyle(Color.red.opacity(0.85))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .overlay(RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.red.opacity(0.6), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help("Delete this course")
        }
    }

    // MARK: - Course info

    private var courseInfoPanel: some View {
        VStack(spacing: 0) {
            infoRow("Name") {
                TextField("", text: $course.name, prompt: Text("Course name"))
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.primaryText)
                    .multilineTextAlignment(.trailing)
            }
            divider
            infoRow("Address") {
                TextField("", text: $course.address, prompt: Text("Street, City, State"))
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.primaryText)
                    .multilineTextAlignment(.trailing)
            }
            divider
            infoRow("Phone") {
                TextField("", text: $course.phone, prompt: Text("(555) 555-5555"))
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.primaryText)
                    .multilineTextAlignment(.trailing)
            }
            divider
            infoRow("Designer") {
                TextField("", text: $course.designer, prompt: Text("Architect name"))
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.primaryText)
                    .multilineTextAlignment(.trailing)
            }
            divider
            infoRow("Opened") {
                TextField("", value: $course.openedYear, format: .number.grouping(.never))
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Theme.primaryText)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
            divider
            infoRow("Book URL") {
                TextField("", text: $course.bookingURL,
                          prompt: Text("https://course.com/teetimes"))
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.primaryText)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(1)
            }
        }
        .glassPanel(padding: 0)
    }

    private func infoRow<Content: View>(_ label: String, @ViewBuilder trailing: () -> Content) -> some View {
        HStack {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Theme.dim)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var divider: some View {
        Rectangle().fill(Theme.hairline).frame(height: 1)
    }

    // MARK: - Holes panel

    private var holesPanel: some View {
        let sorted = course.sortedHoles
        let front = Array(sorted.prefix(9))
        let back = Array(sorted.dropFirst(9))
        return VStack(spacing: 18) {
            nineEditRow(label: "FRONT", holes: front)
            Rectangle().fill(Theme.hairline).frame(height: 1)
            nineEditRow(label: "BACK", holes: back)
        }
        .glassPanel(padding: 18)
    }

    private func nineEditRow(label: String, holes: [CourseHole]) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Theme.accent)
                .frame(width: 52, alignment: .leading)
            ForEach(holes) { h in
                HoleParEditCell(hole: h)
            }
            Spacer(minLength: 0)
            VStack(spacing: 2) {
                Text("TOT")
                    .font(.system(size: 8, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(Theme.dim)
                Text("\(holes.reduce(0) { $0 + $1.par })")
                    .font(.system(size: 14, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.accent)
            }
            .frame(width: 44)
        }
    }

    // MARK: - Tees panel

    private var teesPanel: some View {
        VStack(spacing: 0) {
            if course.tees.isEmpty {
                Text("NO TEES — TAP “ADD TEE”")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Theme.dim)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
            } else {
                teeColumnHeader
                Rectangle().fill(Theme.hairline).frame(height: 1)
                ForEach(Array(course.sortedTees.enumerated()), id: \.element.id) { index, tee in
                    TeeEditRow(tee: tee, onDelete: { deleteTee(tee) })
                    if index < course.sortedTees.count - 1 {
                        Rectangle().fill(Theme.hairline.opacity(0.5)).frame(height: 1)
                    }
                }
            }
        }
        .glassPanel(padding: 0)
    }

    private var teeColumnHeader: some View {
        HStack(spacing: 0) {
            Text("NAME")
                .frame(width: 140, alignment: .leading)
                .padding(.leading, 16)
            Spacer()
            Text("YDS").frame(width: 80, alignment: .trailing)
            Text("RATING").frame(width: 80, alignment: .trailing)
            Text("SLOPE").frame(width: 80, alignment: .trailing)
            Color.clear.frame(width: 44)
        }
        .font(.system(size: 9, weight: .semibold))
        .tracking(2)
        .foregroundStyle(Theme.accent)
        .padding(.vertical, 10)
    }

    // MARK: - Actions

    private func addTee() {
        let tee = CourseTee(name: "New Tee", yardage: 6000,
                            courseRating: 70.0, slopeRating: 113)
        tee.course = course
        course.tees.append(tee)
        modelContext.insert(tee)
        try? modelContext.save()
    }

    private func deleteTee(_ tee: CourseTee) {
        if let idx = course.tees.firstIndex(where: { $0.id == tee.id }) {
            course.tees.remove(at: idx)
        }
        modelContext.delete(tee)
        try? modelContext.save()
    }

    private func deleteCourse() {
        let label = course.name.isEmpty ? "Untitled Course" : course.name
        let id = course.idempotencyKey
        modelContext.delete(course)
        try? modelContext.save()
        AuditService.shared.log(
            entityType: "Course",
            entityID: id,
            entityLabel: label,
            action: "delete",
            summary: "Deleted course \(label)"
        )
        dismiss()
    }

    private func syncTotalPar() {
        course.totalPar = course.computedPar
    }
}

// MARK: - Hole par cell (editable)

struct HoleParEditCell: View {
    @Bindable var hole: CourseHole

    var body: some View {
        VStack(spacing: 4) {
            Text("\(hole.number)")
                .font(.system(size: 9, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Theme.dimmer)
            TextField("", value: $hole.par, format: .number)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .font(.system(size: 15, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Theme.primaryText)
                .frame(width: 34, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Theme.hairline, lineWidth: 1)
                )
        }
    }
}

// MARK: - Tee edit row

struct TeeEditRow: View {
    @Bindable var tee: CourseTee
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            TextField("", text: $tee.name, prompt: Text("Tee name"))
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.primaryText)
                .frame(width: 140, alignment: .leading)
                .padding(.leading, 16)

            Spacer()

            numField(value: $tee.yardage, format: .number, width: 80)

            doubleField(value: $tee.courseRating, width: 80)

            numField(value: $tee.slopeRating, format: .number, width: 80)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.red.opacity(0.7))
                    .frame(width: 44, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Delete tee")
        }
        .padding(.vertical, 8)
    }

    private func numField(value: Binding<Int>, format: IntegerFormatStyle<Int>, width: CGFloat) -> some View {
        TextField("", value: value, format: format)
            .textFieldStyle(.plain)
            .multilineTextAlignment(.trailing)
            .font(.system(size: 13, design: .monospaced))
            .foregroundStyle(Theme.primaryText)
            .frame(width: width, alignment: .trailing)
    }

    private func doubleField(value: Binding<Double>, width: CGFloat) -> some View {
        TextField("", value: value, format: .number.precision(.fractionLength(1)))
            .textFieldStyle(.plain)
            .multilineTextAlignment(.trailing)
            .font(.system(size: 13, design: .monospaced))
            .foregroundStyle(Theme.primaryText)
            .frame(width: width, alignment: .trailing)
    }
}
