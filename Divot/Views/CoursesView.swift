import SwiftUI
import SwiftData

struct CoursesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.name) private var courses: [Course]
    @State private var editingCourse: Course?

    /// Alphabetical by name, case-insensitive and diacritic-insensitive.
    private var sortedCourses: [Course] {
        courses.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    if sortedCourses.isEmpty {
                        emptyState
                    } else {
                        ForEach(sortedCourses) { course in
                            Button {
                                editingCourse = course
                            } label: {
                                courseCard(course)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
            .navigationDestination(item: $editingCourse) { course in
                CourseDetailView(course: course)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                Text("COURSES")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(4)
                    .foregroundStyle(Theme.accent)
                Text("Your saved tracks. Tap any card to edit.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.dim)
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: 28, height: 1.5)
                    .padding(.top, 2)
            }
            Spacer()
            Button(action: addCourse) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("NEW COURSE")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2)
                }
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .overlay(RoundedRectangle(cornerRadius: 3)
                    .stroke(Theme.accent, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "map.fill")
                .font(.system(size: 38, weight: .ultraLight))
                .foregroundStyle(Theme.accent.opacity(0.6))
            Text("NO COURSES SAVED")
                .font(.system(size: 12, weight: .semibold))
                .tracking(3)
                .foregroundStyle(Theme.primaryText)
            Text("Tap NEW COURSE to add your first track.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.dim)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .glassPanel(padding: 32)
    }

    private func courseCard(_ course: Course) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 20) {
                CourseLogo(assetName: course.logoAssetName, height: 120, corner: 10)
                VStack(alignment: .leading, spacing: 4) {
                    Text(course.name.uppercased())
                        .font(.system(size: 18, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(Theme.primaryText)
                    if !course.address.isEmpty {
                        Text(course.address)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.dim)
                    }
                    HStack(spacing: 12) {
                        if course.openedYear > 0 {
                            metaChip("EST \(course.openedYear)")
                        }
                        if !course.designer.isEmpty {
                            metaChip("BY \(course.designer.uppercased())")
                        }
                        if !course.phone.isEmpty {
                            metaChip(course.phone)
                        }
                    }
                    .padding(.top, 2)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("PAR")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(Theme.dim)
                    Text("\(course.computedPar)")
                        .font(.system(size: 44, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.accent)
                        .shadow(color: Theme.accent.opacity(0.4), radius: 14)
                }
            }

            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 1)
                .padding(.vertical, 16)

            VStack(alignment: .leading, spacing: 8) {
                Text("HOLES")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Theme.dim)
                nineRow(holes: Array(course.sortedHoles.prefix(9)), label: "FRONT")
                nineRow(holes: Array(course.sortedHoles.dropFirst(9)), label: "BACK")
            }

            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 1)
                .padding(.vertical, 16)

            VStack(alignment: .leading, spacing: 8) {
                Text("TEES")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Theme.dim)
                VStack(spacing: 0) {
                    ForEach(Array(course.sortedTees.enumerated()), id: \.element.id) { index, tee in
                        teeRow(tee)
                        if index < course.sortedTees.count - 1 {
                            Rectangle().fill(Theme.hairline.opacity(0.5)).frame(height: 1)
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                if let url = URL(string: course.bookingURL), !course.bookingURL.isEmpty {
                    Button {
                        NSWorkspace.shared.open(url)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 10, weight: .bold))
                            Text("BOOK TEE TIME")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(2)
                        }
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 3).fill(Theme.accent))
                    }
                    .buttonStyle(.plain)
                    .help("Open \(course.bookingURL)")
                }

                Spacer()

                Text("TAP TO EDIT")
                    .font(.system(size: 8, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Theme.accent.opacity(0.6))
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.accent.opacity(0.6))
            }
            .padding(.top, 16)
        }
        .glassPanel(cornerRadius: 6, padding: 22)
    }

    private func metaChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .semibold))
            .tracking(1.5)
            .foregroundStyle(Theme.accent.opacity(0.9))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .overlay(RoundedRectangle(cornerRadius: 2)
                .stroke(Theme.accent.opacity(0.45), lineWidth: 1))
    }

    private func nineRow(holes: [CourseHole], label: String) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Theme.accent)
                .frame(width: 48, alignment: .leading)
            ForEach(holes) { h in
                VStack(spacing: 1) {
                    Text("\(h.number)")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(Theme.dimmer)
                    Text("\(h.par)")
                        .font(.system(size: 13, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.primaryText)
                }
                .frame(minWidth: 28)
            }
            Spacer(minLength: 0)
            let total = holes.reduce(0) { $0 + $1.par }
            VStack(spacing: 1) {
                Text("TOT")
                    .font(.system(size: 8, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(Theme.dimmer)
                Text("\(total)")
                    .font(.system(size: 13, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.accent)
            }
            .frame(width: 36)
        }
    }

    private func teeRow(_ tee: CourseTee) -> some View {
        HStack {
            Text(tee.name.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Theme.primaryText)
                .frame(width: 165, alignment: .leading)
            Spacer()
            teeField("YDS", value: "\(tee.yardage)")
            teeField("RATING", value: String(format: "%.1f", tee.courseRating))
            teeField("SLOPE", value: "\(tee.slopeRating)")
        }
        .padding(.vertical, 10)
    }

    private func teeField(_ label: String, value: String) -> some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Theme.dim)
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Theme.primaryText)
        }
        .frame(width: 74, alignment: .trailing)
    }

    // MARK: - Actions

    private func addCourse() {
        let course = Course(name: "New Course", totalPar: 72)
        for i in 1...18 {
            let h = CourseHole(number: i, par: 4)
            h.course = course
            course.holes.append(h)
            modelContext.insert(h)
        }
        let tee = CourseTee(name: "White", yardage: 6000,
                            courseRating: 70.0, slopeRating: 113)
        tee.course = course
        course.tees.append(tee)
        modelContext.insert(tee)
        modelContext.insert(course)
        try? modelContext.save()

        AuditService.shared.log(
            entityType: "Course",
            entityID: course.idempotencyKey,
            entityLabel: course.name,
            action: "insert",
            summary: "Created course \(course.name)"
        )

        editingCourse = course
    }
}
