import SwiftUI
import SwiftData
import AppKit

/// Training & exercise tracker. Two tabs:
///   • Sessions — workouts you've actually done, newest first
///   • Library  — saved exercise definitions you can pull from
struct TrainingView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \TrainingSession.date, order: .reverse)
    private var sessions: [TrainingSession]
    @Query(sort: \TrainingExercise.name)
    private var exercises: [TrainingExercise]

    @State private var tab: Tab = .sessions
    @State private var editingSession: TrainingSession?
    @State private var editingExercise: TrainingExercise?

    enum Tab: String, CaseIterable, Identifiable {
        case sessions, library
        var id: String { rawValue }
        var label: String { self == .sessions ? "SESSIONS" : "LIBRARY" }
    }

    private var visibleSessions: [TrainingSession] {
        sessions.filter { !$0.isArchived }
    }
    private var activeExercises: [TrainingExercise] {
        exercises.filter { !$0.isArchived }
            .sorted { lhs, rhs in
                if lhs.category.sortOrder != rhs.category.sortOrder {
                    return lhs.category.sortOrder < rhs.category.sortOrder
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                tabBar
                if tab == .sessions {
                    sessionsSection
                } else {
                    librarySection
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .sheet(item: $editingSession) { session in
            TrainingSessionEditSheet(session: session) {
                try? modelContext.save()
            }
        }
        .sheet(item: $editingExercise) { exercise in
            TrainingExerciseEditSheet(exercise: exercise) {
                try? modelContext.save()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                Text("TRAINING")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(4)
                    .foregroundStyle(Theme.accent)
                Text("Exercises and sessions — build the engine that swings the club.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.dim)
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: 28, height: 1.5)
                    .padding(.top, 2)
            }
            Spacer()
            Button {
                if tab == .sessions { addSession() } else { addExercise() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text(tab == .sessions ? "NEW SESSION" : "NEW EXERCISE")
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

    // MARK: - Tab bar

    private var tabBar: some View {
        HStack(spacing: 8) {
            ForEach(Tab.allCases) { t in
                Button {
                    tab = t
                } label: {
                    Text(t.label)
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(tab == t ? .black : Theme.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Group {
                                if tab == t {
                                    RoundedRectangle(cornerRadius: 3).fill(Theme.accent)
                                } else {
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(Theme.accent.opacity(0.55), lineWidth: 1)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
            // Counts
            Text("\(visibleSessions.count) \(visibleSessions.count == 1 ? "SESSION" : "SESSIONS")")
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Theme.dim)
            Text("·").foregroundStyle(Theme.dim)
            Text("\(activeExercises.count) IN LIBRARY")
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Theme.dim)
        }
    }

    // MARK: - Sessions section

    private var sessionsSection: some View {
        Group {
            if visibleSessions.isEmpty {
                emptyState(icon: "calendar.badge.clock",
                           title: "NO SESSIONS LOGGED",
                           sub: "Tap NEW SESSION to log your first workout.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(visibleSessions.enumerated()), id: \.element.id) { index, session in
                        Button {
                            editingSession = session
                        } label: {
                            sessionRow(session,
                                       isAlternate: index.isMultiple(of: 2))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Open") { editingSession = session }
                            Divider()
                            Button("Delete", role: .destructive) {
                                deleteSession(session)
                            }
                        }
                        if index < visibleSessions.count - 1 {
                            Rectangle()
                                .fill(Theme.hairline.opacity(0.5))
                                .frame(height: 1)
                        }
                    }
                }
                .glassPanel(padding: 0)
            }
        }
    }

    private func sessionRow(_ session: TrainingSession, isAlternate: Bool) -> some View {
        HStack(alignment: .center, spacing: 14) {
            // Date column
            VStack(alignment: .leading, spacing: 2) {
                Text(session.date.formatted(.dateTime.month(.abbreviated).day()).uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.accent)
                Text(session.date.formatted(.dateTime.year()))
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.dim)
            }
            .frame(width: 56, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                Text(session.displayTitle.uppercased())
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(Theme.primaryText)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(session.summaryLine)
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.dim)
                    if !session.notes.isEmpty {
                        Text("·").foregroundStyle(Theme.dim)
                        Text(session.notes)
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.dim)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.accent.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(isAlternate ? Color.white.opacity(0.04) : Color.clear)
    }

    // MARK: - Library section

    private var librarySection: some View {
        Group {
            if activeExercises.isEmpty {
                emptyState(icon: "list.clipboard",
                           title: "NO EXERCISES SAVED",
                           sub: "Build your library — sessions pull from these.")
            } else {
                VStack(spacing: 16) {
                    ForEach(TrainingCategory.allCases) { cat in
                        let inCat = activeExercises.filter { $0.category == cat }
                        if !inCat.isEmpty {
                            categoryGroup(cat: cat, exercises: inCat)
                        }
                    }
                }
            }
        }
    }

    private func categoryGroup(cat: TrainingCategory,
                               exercises: [TrainingExercise]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(cat.shortName)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(cat.color)
                Text("\(exercises.count)")
                    .font(.system(size: 9, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.dim)
                Rectangle()
                    .fill(LinearGradient(
                        colors: [cat.color.opacity(0.4), Theme.hairline, .clear],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(height: 1)
            }

            VStack(spacing: 0) {
                ForEach(Array(exercises.enumerated()), id: \.element.id) { index, ex in
                    Button {
                        editingExercise = ex
                    } label: {
                        exerciseRow(ex,
                                    isAlternate: index.isMultiple(of: 2))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Edit") { editingExercise = ex }
                        Divider()
                        Button("Delete", role: .destructive) {
                            deleteExercise(ex)
                        }
                    }
                    if index < exercises.count - 1 {
                        Rectangle()
                            .fill(Theme.hairline.opacity(0.4))
                            .frame(height: 1)
                    }
                }
            }
            .glassPanel(padding: 0)
        }
    }

    private func exerciseRow(_ ex: TrainingExercise,
                             isAlternate: Bool) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Rectangle()
                .fill(ex.category.color)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 3) {
                Text(ex.displayTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ex.category.color)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if !ex.targetArea.isEmpty {
                        Text(ex.targetArea.uppercased())
                            .font(.system(size: 8, weight: .semibold))
                            .tracking(1.5)
                            .foregroundStyle(Theme.dim)
                    }
                    if !ex.equipment.isEmpty {
                        Text("·").foregroundStyle(Theme.dim)
                        Text(ex.equipment)
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.dim)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
            if !ex.prescriptionSummary.isEmpty {
                Text(ex.prescriptionSummary)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.primaryText)
            }
            if !ex.videoURL.isEmpty,
               let url = URL(string: ex.videoURL) {
                Button {
                    NSWorkspace.shared.open(url)
                } label: {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
                .help("Open tutorial video")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            ZStack {
                ex.category.color.opacity(0.10)
                if isAlternate {
                    Color.white.opacity(0.03)
                }
            }
        )
    }

    // MARK: - Empty state

    private func emptyState(icon: String, title: String, sub: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 38, weight: .ultraLight))
                .foregroundStyle(Theme.accent.opacity(0.6))
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .tracking(3)
                .foregroundStyle(Theme.primaryText)
            Text(sub)
                .font(.system(size: 12))
                .foregroundStyle(Theme.dim)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .glassPanel(padding: 32)
    }

    // MARK: - Actions

    private func addSession() {
        let session = TrainingSession(date: .now)
        modelContext.insert(session)
        try? modelContext.save()
        AuditService.shared.log(
            entityType: "TrainingSession",
            entityID: session.idempotencyKey,
            entityLabel: "New training session",
            action: "insert",
            summary: "Started a new training session"
        )
        editingSession = session
    }

    private func addExercise() {
        let ex = TrainingExercise()
        modelContext.insert(ex)
        try? modelContext.save()
        AuditService.shared.log(
            entityType: "TrainingExercise",
            entityID: ex.idempotencyKey,
            entityLabel: "New exercise",
            action: "insert",
            summary: "Added a new exercise to the training library"
        )
        editingExercise = ex
    }

    private func deleteSession(_ session: TrainingSession) {
        let label = session.displayTitle
        let id = session.idempotencyKey
        modelContext.delete(session)
        try? modelContext.save()
        AuditService.shared.log(
            entityType: "TrainingSession",
            entityID: id,
            entityLabel: label,
            action: "delete",
            summary: "Deleted training session \(label)"
        )
    }

    private func deleteExercise(_ ex: TrainingExercise) {
        let label = ex.displayTitle
        let id = ex.idempotencyKey
        modelContext.delete(ex)
        try? modelContext.save()
        AuditService.shared.log(
            entityType: "TrainingExercise",
            entityID: id,
            entityLabel: label,
            action: "delete",
            summary: "Deleted exercise \(label) from library"
        )
    }
}

// MARK: - Per-category color (mirrors Clubs convention)

extension TrainingCategory {
    var color: Color {
        switch self {
        case .mobility:  return Color(red: 0.55, green: 0.80, blue: 0.98)   // light blue
        case .stability: return Color(red: 0.40, green: 0.85, blue: 0.85)   // teal
        case .power:     return Color(red: 1.00, green: 0.70, blue: 0.20)   // gold
        case .strength:  return Color(red: 0.95, green: 0.55, blue: 0.30)   // orange
        case .cardio:    return Color(red: 0.55, green: 0.88, blue: 0.60)   // light green
        }
    }
}
