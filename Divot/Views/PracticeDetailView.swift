import SwiftUI
import SwiftData

struct PracticeDetailView: View {
    @Bindable var session: PracticeSession
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showRemoveConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                VStack(alignment: .leading, spacing: 14) {
                    SectionLabel("Session", subtitle: "Type · location · date")
                    sessionInfoPanel
                }

                VStack(alignment: .leading, spacing: 14) {
                    SectionLabel("Metrics", subtitle: "Duration · balls · self-rating")
                    metricsPanel
                }

                VStack(alignment: .leading, spacing: 14) {
                    SectionLabel("Focus", subtitle: "What you worked on")
                    focusPanel
                }

                VStack(alignment: .leading, spacing: 14) {
                    SectionLabel("Drills")
                    drillsPanel
                }

                VStack(alignment: .leading, spacing: 14) {
                    SectionLabel("Notes")
                    TextEditor(text: $session.notes)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.primaryText)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 100)
                        .glassPanel(padding: 10)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .navigationTitle(session.location.isEmpty
                         ? session.type.displayName
                         : "\(session.type.displayName) · \(session.location)")
        .alert(alertTitle, isPresented: $showRemoveConfirm) {
            Button("Cancel", role: .cancel) { }
            if session.isArchived {
                Button("Restore") { restore() }
            } else {
                Button("Archive") { archive() }
            }
            Button("Delete Forever", role: .destructive) { deleteSession() }
        } message: {
            Text(session.isArchived
                 ? "Restore this session to your active list, or delete it forever. Deleting can't be undone."
                 : "Archive hides this session from your list and summary but keeps the data safe — restore anytime. Deleting can't be undone.")
        }
    }

    private var alertTitle: String {
        let name = session.location.isEmpty
            ? session.type.displayName
            : "\(session.type.displayName) at \(session.location)"
        return session.isArchived
            ? "Restore or delete \(name)?"
            : "Archive or delete \(name)?"
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 22) {
            HStack(spacing: 14) {
                Image(systemName: session.type.systemImage)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 36, height: 36)
                    .overlay(Circle().stroke(Theme.accent, lineWidth: 1.5))
                VStack(alignment: .leading, spacing: 3) {
                    Text(session.type.displayName.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(3)
                        .foregroundStyle(Theme.accent)
                    Text(session.location.isEmpty ? "Untitled session" : session.location)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack(spacing: 10) {
                Text("DATE")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Theme.dim)
                DatePicker("", selection: $session.date, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.field)
            }

            Button { showRemoveConfirm = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: session.isArchived ? "archivebox.fill" : "trash")
                        .font(.system(size: 11, weight: .bold))
                    Text(session.isArchived ? "ARCHIVED" : "REMOVE…")
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
        }
    }

    // MARK: - Session info panel

    private var sessionInfoPanel: some View {
        VStack(spacing: 0) {
            infoRow("Type") {
                Menu {
                    ForEach(PracticeType.allCases) { t in
                        Button {
                            session.type = t
                        } label: {
                            Label(t.displayName, systemImage: t.systemImage)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: session.type.systemImage)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.accent)
                        Text(session.type.displayName.uppercased())
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(1.5)
                            .foregroundStyle(Theme.primaryText)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Theme.dim)
                    }
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
            }
            divider
            infoRow("Location") {
                TextField("", text: $session.location,
                          prompt: Text("Range name, course, or home"))
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.primaryText)
                    .multilineTextAlignment(.trailing)
            }
        }
        .glassPanel(padding: 0)
    }

    // MARK: - Metrics panel

    private var metricsPanel: some View {
        VStack(spacing: 0) {
            infoRow("Duration (min)") {
                TextField("", value: $session.durationMinutes, format: .number)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(Theme.primaryText)
                    .frame(width: 80)
            }
            divider
            infoRow("Balls Hit") {
                TextField("", value: $session.ballsHit, format: .number)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(Theme.primaryText)
                    .frame(width: 80)
            }
            divider
            infoRow("Self-Rating") {
                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { i in
                        Button {
                            session.rating = session.rating == i ? 0 : i
                        } label: {
                            Image(systemName: i <= session.rating ? "star.fill" : "star")
                                .font(.system(size: 16))
                                .foregroundStyle(i <= session.rating ? Theme.accent : Theme.dim)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .glassPanel(padding: 0)
    }

    // MARK: - Focus / Drills

    private var focusPanel: some View {
        TextEditor(text: $session.focus)
            .font(.system(size: 13))
            .foregroundStyle(Theme.primaryText)
            .scrollContentBackground(.hidden)
            .frame(minHeight: 60)
            .glassPanel(padding: 10)
    }

    private var drillsPanel: some View {
        TextEditor(text: $session.drills)
            .font(.system(size: 13))
            .foregroundStyle(Theme.primaryText)
            .scrollContentBackground(.hidden)
            .frame(minHeight: 80)
            .glassPanel(padding: 10)
    }

    // MARK: - Helpers

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

    // MARK: - Actions

    private func deleteSession() {
        modelContext.delete(session)
        modelContext.saveOrReport()
        dismiss()
    }

    private func archive() {
        session.isArchived = true
        modelContext.saveOrReport()
        dismiss()
    }

    private func restore() {
        session.isArchived = false
        modelContext.saveOrReport()
    }
}
