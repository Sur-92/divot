import SwiftUI
import SwiftData

struct StartRoundSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Course.name) private var courses: [Course]

    @State private var selectedCourse: Course?
    @State private var selectedTee: CourseTee?
    @State private var roundDate: Date = .now
    @State private var roundType: RoundType = .full18

    /// Called with the newly inserted Round so caller can open it.
    var onStart: (Round) -> Void

    private var canStart: Bool {
        // Ad-hoc is always fine. Course-based requires a tee.
        selectedCourse == nil || selectedTee != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    dateSection
                    holesSection
                    courseSection
                    if let course = selectedCourse {
                        teeSection(for: course)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
            }

            footer
        }
        .frame(minWidth: 540, idealWidth: 580, minHeight: 560, idealHeight: 680)
        .background(backdrop)
    }

    // MARK: - Backdrop

    private var backdrop: some View {
        ZStack {
            Image("Background")
                .resizable()
                .scaledToFill()
            LinearGradient(
                colors: [.black.opacity(0.82), .black.opacity(0.7)],
                startPoint: .top, endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("START A ROUND")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(4)
                        .foregroundStyle(Theme.accent)
                    Text("Pick a course, pick a tee. Or go ad-hoc.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.dim)
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.dim)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle().stroke(Theme.hairline, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            Rectangle()
                .fill(Theme.accent)
                .frame(width: 28, height: 1.5)
                .padding(.top, 4)
        }
        .padding(.horizontal, 28)
        .padding(.top, 24)
        .padding(.bottom, 18)
    }

    // MARK: - Holes section (Front 9 / Back 9 / 18)

    private var holesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel("Holes", subtitle: "Playing 9 today or the full 18?")
            HStack(spacing: 10) {
                ForEach(RoundType.allCases) { type in
                    roundTypeButton(type)
                }
                Spacer()
            }
        }
    }

    private func roundTypeButton(_ type: RoundType) -> some View {
        let isSelected = roundType == type
        return Button {
            roundType = type
        } label: {
            VStack(spacing: 2) {
                Text(type.shortBadge)
                    .font(.system(size: 16, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(isSelected ? .black : Theme.accent)
                Text(type.displayName.uppercased())
                    .font(.system(size: 8, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(isSelected ? .black.opacity(0.75) : Theme.dim)
            }
            .frame(width: 110, height: 52)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? Theme.accent : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Theme.accent, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Date section

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel("Date")
            HStack {
                DatePicker("", selection: $roundDate, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.field)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .glassPanel(padding: 0)
        }
    }

    // MARK: - Course section

    private var courseSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel("Course", subtitle: "\(courses.count) saved")

            VStack(spacing: 0) {
                ForEach(courses) { course in
                    courseRow(course)
                    Rectangle().fill(Theme.hairline).frame(height: 1)
                }
                adHocRow
            }
            .glassPanel(padding: 0)
        }
    }

    private func courseRow(_ course: Course) -> some View {
        let isSelected = selectedCourse?.id == course.id
        return Button {
            selectedCourse = course
            selectedTee = nil
        } label: {
            HStack(spacing: 14) {
                Rectangle()
                    .fill(isSelected ? Theme.accent : Color.clear)
                    .frame(width: 2, height: 40)
                CourseLogo(assetName: course.logoAssetName, height: 32)
                VStack(alignment: .leading, spacing: 3) {
                    Text(course.name.uppercased())
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(Theme.primaryText)
                    HStack(spacing: 8) {
                        Text("PAR \(course.totalPar)")
                            .font(.system(size: 9, weight: .medium))
                            .tracking(1.5)
                            .foregroundStyle(Theme.accent)
                        Text("·")
                            .foregroundStyle(Theme.dim)
                        Text("\(course.tees.count) TEES")
                            .font(.system(size: 9, weight: .medium))
                            .tracking(1.5)
                            .foregroundStyle(Theme.dim)
                        if !course.address.isEmpty {
                            Text("·")
                                .foregroundStyle(Theme.dim)
                            Text(course.address)
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.dimmer)
                                .lineLimit(1)
                        }
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.accent)
                        .padding(.trailing, 16)
                }
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var adHocRow: some View {
        let isSelected = selectedCourse == nil
        return Button {
            selectedCourse = nil
            selectedTee = nil
        } label: {
            HStack(spacing: 14) {
                Rectangle()
                    .fill(isSelected ? Theme.accent : Color.clear)
                    .frame(width: 2, height: 40)
                VStack(alignment: .leading, spacing: 3) {
                    Text("AD-HOC ROUND")
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(Theme.primaryText)
                    Text("No saved course — fill in manually")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.dim)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.accent)
                        .padding(.trailing, 16)
                }
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tee section

    private func teeSection(for course: Course) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel("Tees", subtitle: "From the tips down")
            VStack(spacing: 0) {
                ForEach(Array(course.sortedTees.enumerated()), id: \.element.id) { index, tee in
                    teeRow(tee)
                    if index < course.sortedTees.count - 1 {
                        Rectangle().fill(Theme.hairline).frame(height: 1)
                    }
                }
            }
            .glassPanel(padding: 0)
        }
    }

    private func teeRow(_ tee: CourseTee) -> some View {
        let isSelected = selectedTee?.id == tee.id
        return Button {
            selectedTee = tee
        } label: {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(isSelected ? Theme.accent : Color.clear)
                    .frame(width: 2, height: 40)
                Text(tee.name.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(isSelected ? Theme.accent : Theme.primaryText)
                    .frame(width: 110, alignment: .leading)
                    .padding(.leading, 14)

                Spacer()

                teeStat(label: "Yds", value: "\(tee.yardage)")
                teeStat(label: "Rating", value: String(format: "%.1f", tee.courseRating))
                teeStat(label: "Slope", value: "\(tee.slopeRating)")

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 16)
                } else {
                    Color.clear.frame(width: 33)
                }
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func teeStat(label: String, value: String) -> some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text(label.uppercased())
                .font(.system(size: 8, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Theme.dim)
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Theme.primaryText)
        }
        .frame(width: 70, alignment: .trailing)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Theme.hairline).frame(height: 1)
            HStack {
                Button {
                    dismiss()
                } label: {
                    Text("CANCEL")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(Theme.dim)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: startRound) {
                    HStack(spacing: 8) {
                        Text("START ROUND")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(2.5)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(canStart ? .black : Theme.dim)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(canStart ? Theme.accent : Color.white.opacity(0.05))
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canStart)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Action

    private func startRound() {
        let range = roundType.holeRange
        let round: Round

        if let course = selectedCourse, let tee = selectedTee {
            round = Round(
                date: roundDate,
                courseName: course.name,
                tees: tee.name,
                courseRating: tee.courseRating,
                slopeRating: tee.slopeRating,
                course: course
            )
            round.roundType = roundType
            for courseHole in course.sortedHoles where range.contains(courseHole.number) {
                let hole = Hole(
                    number: courseHole.number,
                    par: courseHole.par,
                    yardage: tee.yardage(forHole: courseHole.number),
                    handicapIndex: courseHole.handicapIndex
                )
                hole.round = round
                round.holes.append(hole)
            }
        } else {
            round = Round(date: roundDate, courseName: "New Course")
            round.roundType = roundType
            for i in range {
                let hole = Hole(number: i, par: 4)
                hole.round = round
                round.holes.append(hole)
            }
        }
        modelContext.insert(round)
        try? modelContext.save()

        // Audit
        let courseLabel = round.courseName.isEmpty ? "Untitled Round" : round.courseName
        let typeTag = roundType == .full18 ? "18 holes" : (roundType == .front9 ? "front 9" : "back 9")
        AuditService.shared.log(
            entityType: "Round",
            entityID: round.idempotencyKey,
            entityLabel: courseLabel,
            action: "insert",
            summary: "Started \(typeTag) round at \(courseLabel)"
        )

        onStart(round)
        dismiss()
    }
}
