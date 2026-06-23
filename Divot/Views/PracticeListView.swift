import SwiftUI
import SwiftData

struct PracticeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PracticeSession.date, order: .reverse) private var allSessions: [PracticeSession]
    @Query(sort: \PrepPlan.date, order: .reverse) private var allPreps: [PrepPlan]
    @State private var selectedSession: PracticeSession?
    @State private var selectedPrep: PrepPlan?
    @State private var showAddPrep = false
    @State private var showArchived = false

    /// A practice session or a pre-round prep, merged into one timeline.
    private enum PracticeItem: Identifiable {
        case session(PracticeSession)
        case prep(PrepPlan)
        var id: String {
            switch self {
            case .session(let s): return "s-" + s.idempotencyKey
            case .prep(let p):    return "p-" + p.idempotencyKey
            }
        }
        var date: Date {
            switch self {
            case .session(let s): return s.date
            case .prep(let p):    return p.date
            }
        }
        var isArchived: Bool {
            switch self {
            case .session(let s): return s.isArchived
            case .prep(let p):    return p.isArchived
            }
        }
    }

    private var visibleSessions: [PracticeSession] {
        allSessions.filter { $0.isArchived == showArchived }
    }

    private var visibleItems: [PracticeItem] {
        let items = allSessions.map(PracticeItem.session) + allPreps.map(PracticeItem.prep)
        return items.filter { $0.isArchived == showArchived }.sorted { $0.date > $1.date }
    }

    private var archivedCount: Int {
        allSessions.filter(\.isArchived).count + allPreps.filter(\.isArchived).count
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                header

                if !visibleItems.isEmpty {
                    summaryRow
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                }

                if visibleItems.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
                                switch item {
                                case .session(let session):
                                    Button {
                                        selectedSession = session
                                    } label: {
                                        PracticeRow(session: session, isAlternate: index.isMultiple(of: 2))
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu { sessionMenu(session) }
                                case .prep(let prep):
                                    Button {
                                        selectedPrep = prep
                                    } label: {
                                        PrepRow(prep: prep, isAlternate: index.isMultiple(of: 2))
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu { prepMenu(prep) }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            .navigationDestination(item: $selectedSession) { session in
                PracticeDetailView(session: session)
            }
            .navigationDestination(item: $selectedPrep) { prep in
                PrepDetailView(prep: prep)
            }
            .sheet(isPresented: $showAddPrep) {
                AddPrepView { prep in selectedPrep = prep }
            }
        }
    }

    @ViewBuilder
    private func sessionMenu(_ session: PracticeSession) -> some View {
        Button("Open") { selectedSession = session }
        if session.isArchived {
            Button("Restore") { restore(session) }
        } else {
            Button("Archive") { archive(session) }
        }
        Divider()
        Button("Delete Forever", role: .destructive) { delete(session) }
    }

    @ViewBuilder
    private func prepMenu(_ prep: PrepPlan) -> some View {
        Button("Open") { selectedPrep = prep }
        if prep.isArchived {
            Button("Restore") { restorePrep(prep) }
        } else {
            Button("Archive") { archivePrep(prep) }
        }
        Divider()
        Button("Delete Forever", role: .destructive) { deletePrep(prep) }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(showArchived ? "ARCHIVED PRACTICE" : "PRACTICE")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(4)
                    .foregroundStyle(Theme.accent)
                Text(showArchived
                     ? "Sessions you benched. Still tracked."
                     : "Grind the weak spots. Log the reps.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.dim)
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: 28, height: 1.5)
                    .padding(.top, 2)
            }
            Spacer()

            if archivedCount > 0 || showArchived {
                Button {
                    showArchived.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: showArchived ? "tray.full" : "archivebox")
                            .font(.system(size: 10, weight: .bold))
                        Text(showArchived
                             ? "SHOW ACTIVE"
                             : "ARCHIVED (\(archivedCount))")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(2)
                    }
                    .foregroundStyle(showArchived ? Theme.primaryText : Theme.dim)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .overlay(RoundedRectangle(cornerRadius: 3)
                        .stroke(Theme.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
            }

            VStack(spacing: 8) {
                Button(action: addSession) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("NEW SESSION")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(2)
                    }
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .overlay(RoundedRectangle(cornerRadius: 3)
                        .stroke(Theme.accent, lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button { showAddPrep = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .bold))
                        Text("ADD PREP")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(2)
                    }
                    .foregroundStyle(Theme.dim)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.05)))
                    .overlay(RoundedRectangle(cornerRadius: 3)
                        .stroke(Theme.dim.opacity(0.5), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .help("Generate a pre-round prep from your history + playbook")
            }
            .frame(width: 150)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 18)
    }

    // MARK: - Summary chips

    private var summaryRow: some View {
        let totalHours = visibleSessions.reduce(0) { $0 + $1.durationMinutes } / 60
        let totalBalls = visibleSessions.reduce(0) { $0 + $1.ballsHit }

        let prepCount = allPreps.filter { $0.isArchived == showArchived }.count

        return HStack(spacing: 12) {
            if !visibleSessions.isEmpty { chip(label: "SESSIONS", value: "\(visibleSessions.count)") }
            if prepCount > 0 { chip(label: "PREPS", value: "\(prepCount)") }
            if totalHours > 0 { chip(label: "HOURS", value: "\(totalHours)") }
            if totalBalls > 0 { chip(label: "BALLS", value: "\(totalBalls)") }

            ForEach(PracticeType.allCases) { type in
                let count = visibleSessions.filter { $0.type == type }.count
                if count > 0 {
                    chip(label: type.shortName, value: "\(count)")
                }
            }
            Spacer()
        }
    }

    private func chip(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .tracking(1.8)
                .foregroundStyle(Theme.dim)
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Theme.primaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassPanel(cornerRadius: 3, padding: 0)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: showArchived ? "archivebox" : "figure.golf")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(Theme.accent.opacity(0.7))
            Text(showArchived ? "NO ARCHIVED SESSIONS" : "NO PRACTICE LOGGED")
                .font(.system(size: 12, weight: .semibold))
                .tracking(3)
                .foregroundStyle(Theme.primaryText)
            Text(showArchived
                 ? "Archived sessions and preps will show up here."
                 : "Tap NEW SESSION to log reps, or ADD PREP for a pre-round plan.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.dim)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func addSession() {
        let session = PracticeSession(date: .now, type: .drivingRange)
        modelContext.insert(session)
        modelContext.saveOrReport()

        AuditService.shared.log(
            entityType: "PracticeSession",
            entityID: session.idempotencyKey,
            entityLabel: session.type.displayName,
            action: "insert",
            summary: "Started \(session.type.displayName) practice session"
        )

        selectedSession = session
    }

    private func delete(_ session: PracticeSession) {
        let label = session.location.isEmpty ? session.type.displayName : session.location
        let id = session.idempotencyKey
        modelContext.delete(session)
        modelContext.saveOrReport()
        AuditService.shared.log(
            entityType: "PracticeSession",
            entityID: id,
            entityLabel: label,
            action: "delete",
            summary: "Deleted practice session \(label)"
        )
    }

    private func archive(_ session: PracticeSession) {
        session.isArchived = true
        modelContext.saveOrReport()
        let label = session.location.isEmpty ? session.type.displayName : session.location
        AuditService.shared.log(
            entityType: "PracticeSession",
            entityID: session.idempotencyKey,
            entityLabel: label,
            action: "archive",
            summary: "Archived practice session \(label)"
        )
    }

    private func restore(_ session: PracticeSession) {
        session.isArchived = false
        modelContext.saveOrReport()
        let label = session.location.isEmpty ? session.type.displayName : session.location
        AuditService.shared.log(
            entityType: "PracticeSession",
            entityID: session.idempotencyKey,
            entityLabel: label,
            action: "restore",
            summary: "Restored practice session \(label)"
        )
    }

    // MARK: - Prep actions

    private func deletePrep(_ prep: PrepPlan) {
        let id = prep.idempotencyKey
        let label = prep.courseName
        modelContext.delete(prep)
        modelContext.saveOrReport()
        AuditService.shared.log(
            entityType: "PrepPlan", entityID: id, entityLabel: label,
            action: "delete", summary: "Deleted pre-round prep for \(label)")
    }

    private func archivePrep(_ prep: PrepPlan) {
        prep.isArchived = true
        modelContext.saveOrReport()
        AuditService.shared.log(
            entityType: "PrepPlan", entityID: prep.idempotencyKey, entityLabel: prep.courseName,
            action: "archive", summary: "Archived pre-round prep for \(prep.courseName)")
    }

    private func restorePrep(_ prep: PrepPlan) {
        prep.isArchived = false
        modelContext.saveOrReport()
        AuditService.shared.log(
            entityType: "PrepPlan", entityID: prep.idempotencyKey, entityLabel: prep.courseName,
            action: "restore", summary: "Restored pre-round prep for \(prep.courseName)")
    }
}

// MARK: - Prep row

struct PrepRow: View {
    let prep: PrepPlan
    var isAlternate: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(prep.date.formatted(.dateTime.month(.abbreviated).day()).uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Theme.accent)
                Text(prep.date.formatted(.dateTime.year()))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Theme.dimmer)
            }
            .frame(width: 56, alignment: .leading)

            Rectangle()
                .fill(Theme.hairline)
                .frame(width: 1, height: 32)

            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text("PREP")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.8)
                            .foregroundStyle(Theme.accent)
                        Text("·").foregroundStyle(Theme.dim)
                        Text(prep.courseName.uppercased())
                            .font(.system(size: 13, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(Theme.primaryText)
                            .lineLimit(1)
                        if prep.isArchived {
                            Text("ARCHIVED")
                                .font(.system(size: 8, weight: .bold))
                                .tracking(2)
                                .foregroundStyle(Theme.dim)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .overlay(RoundedRectangle(cornerRadius: 2)
                                    .stroke(Theme.hairline, lineWidth: 1))
                        }
                    }
                    Text("\(prep.advisories.count) advisor\(prep.advisories.count == 1 ? "y" : "ies") · pre-round plan")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.dim)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.dimmer)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .background(isAlternate ? Color.white.opacity(0.04) : Color.clear)
        .opacity(prep.isArchived ? 0.55 : 1)
    }
}

// MARK: - Practice row

struct PracticeRow: View {
    let session: PracticeSession
    var isAlternate: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Date block
            VStack(alignment: .leading, spacing: 3) {
                Text(session.date.formatted(.dateTime.month(.abbreviated).day()).uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Theme.accent)
                Text(session.date.formatted(.dateTime.year()))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Theme.dimmer)
            }
            .frame(width: 56, alignment: .leading)

            Rectangle()
                .fill(Theme.hairline)
                .frame(width: 1, height: 32)

            // Type + location
            HStack(spacing: 10) {
                Image(systemName: session.type.systemImage)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(session.type.shortName)
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.8)
                            .foregroundStyle(Theme.accent)
                        if !session.location.isEmpty {
                            Text("·").foregroundStyle(Theme.dim)
                            Text(session.location.uppercased())
                                .font(.system(size: 13, weight: .semibold))
                                .tracking(1.2)
                                .foregroundStyle(Theme.primaryText)
                                .lineLimit(1)
                        }
                        if session.isArchived {
                            Text("ARCHIVED")
                                .font(.system(size: 8, weight: .bold))
                                .tracking(2)
                                .foregroundStyle(Theme.dim)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .overlay(RoundedRectangle(cornerRadius: 2)
                                    .stroke(Theme.hairline, lineWidth: 1))
                        }
                    }
                    if !session.focus.isEmpty {
                        Text("focus: \(session.focus)")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.dim)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Right-side metrics
            HStack(spacing: 14) {
                if session.durationMinutes > 0 {
                    metric(label: "TIME", value: session.durationDisplay)
                }
                if session.ballsHit > 0 {
                    metric(label: "BALLS", value: "\(session.ballsHit)")
                }
                if session.rating > 0 {
                    ratingStars
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.dimmer)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .background(isAlternate ? Color.white.opacity(0.04) : Color.clear)
        .opacity(session.isArchived ? 0.55 : 1)
    }

    private func metric(label: String, value: String) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .tracking(1.8)
                .foregroundStyle(Theme.dim)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Theme.primaryText)
        }
    }

    private var ratingStars: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= session.rating ? "star.fill" : "star")
                    .font(.system(size: 9))
                    .foregroundStyle(i <= session.rating ? Theme.accent : Theme.dimmer)
            }
        }
    }
}
