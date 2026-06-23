import SwiftUI
import SwiftData

/// Sheet for creating a pre-round prep: pick a course, (first time) paste an
/// Anthropic API key, and generate three advisories from your history +
/// recent form + adopted playbook teachings.
struct AddPrepView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Course.name) private var courses: [Course]
    @Query(sort: \Round.date, order: .reverse) private var allRounds: [Round]

    /// Called with the freshly created prep so the list can open it.
    var onCreated: (PrepPlan) -> Void

    @State private var selectedCourse: Course?
    @State private var keyInput = ""
    @State private var hasKey = KeychainStore.hasAnthropicKey
    @State private var editingKey = false
    @State private var isGenerating = false
    @State private var errorText: String?

    private var playableCourses: [Course] {
        courses.filter { !$0.isSimulator }
    }

    private var courseRoundCount: Int {
        guard let c = selectedCourse else { return 0 }
        return roundsAt(c).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().overlay(Theme.hairline)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    coursePicker
                    keySection
                    if let errorText {
                        Text(errorText)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.red.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(20)
            }
            Divider().overlay(Theme.hairline)
            footer
        }
        .frame(width: 500, height: 460)
        .background(sheetBackground)
    }

    private var sheetBackground: some View {
        ZStack {
            Color(red: 0.05, green: 0.09, blue: 0.16)
            LinearGradient(
                colors: [Color.white.opacity(0.03), Color.black.opacity(0.18)],
                startPoint: .top, endPoint: .bottom)
        }
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text("ADD PREP")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(3)
                    .foregroundStyle(Theme.accent)
                Text("Pre-round advisories from your history + playbook")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.dim)
            }
            Spacer()
        }
        .padding(20)
    }

    // MARK: - Course picker

    private var coursePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("COURSE")
            if playableCourses.isEmpty {
                Text("No courses saved yet — add one on the Courses page first.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.dim)
            } else {
                Menu {
                    ForEach(playableCourses, id: \.idempotencyKey) { c in
                        Button(c.name) { selectedCourse = c }
                    }
                } label: {
                    HStack {
                        Text(selectedCourse?.name ?? "Select a course…")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(selectedCourse == nil ? Theme.dim : Theme.primaryText)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.dim)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)

                if selectedCourse != nil {
                    Text("Will use \(courseRoundCount) round\(courseRoundCount == 1 ? "" : "s") here + your last 3 rounds anywhere + your playbook.")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.dim)
                }
            }
        }
    }

    // MARK: - API key

    @ViewBuilder
    private var keySection: some View {
        if hasKey && !editingKey {
            HStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.accent.opacity(0.8))
                Text("Anthropic API key saved")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.dim)
                Spacer()
                Button("Replace") { editingKey = true; keyInput = "" }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .padding(.vertical, 4)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                fieldLabel("ANTHROPIC API KEY")
                SecureField("sk-ant-…", text: $keyInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.hairline, lineWidth: 1))
                HStack(spacing: 6) {
                    Text("Stored only in your macOS Keychain. Get one at")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.dim)
                    Link("console.anthropic.com", destination: URL(string: "https://console.anthropic.com/settings/keys")!)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
                HStack {
                    Button("Save Key") { saveKey() }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(keyInput.isEmpty ? Theme.dim : Theme.accent)
                        .disabled(keyInput.isEmpty)
                    if hasKey {
                        Button("Cancel") { editingKey = false }
                            .buttonStyle(.plain)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.dim)
                    }
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.dim)
            Spacer()
            Button(action: generate) {
                HStack(spacing: 8) {
                    if isGenerating {
                        ProgressView().controlSize(.small).tint(.black)
                    } else {
                        Image(systemName: "sparkles").font(.system(size: 11, weight: .bold))
                    }
                    Text(isGenerating ? "GENERATING…" : "GENERATE PREP")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.5)
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 4).fill(canGenerate ? Theme.accent : Theme.dimmer))
            }
            .buttonStyle(.plain)
            .disabled(!canGenerate)
        }
        .padding(20)
    }

    private var canGenerate: Bool {
        selectedCourse != nil && hasKey && !editingKey && !isGenerating
    }

    // MARK: - Helpers

    private func fieldLabel(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 9, weight: .semibold))
            .tracking(2)
            .foregroundStyle(Theme.dim)
    }

    private func roundsAt(_ course: Course) -> [Round] {
        allRounds.filter {
            $0.isScoringEligible && $0.course?.persistentModelID == course.persistentModelID
        }
    }

    private func saveKey() {
        let trimmed = keyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if KeychainStore.setAnthropicKey(trimmed) {
            hasKey = true
            editingKey = false
            keyInput = ""
            errorText = nil
        } else {
            errorText = "Couldn't save the key to the Keychain."
        }
    }

    private func generate() {
        guard let course = selectedCourse, let key = KeychainStore.anthropicKey else {
            errorText = "Pick a course and add your API key first."
            return
        }
        let courseRounds = roundsAt(course)
        let recent = Array(allRounds.filter(\.isScoringEligible).prefix(3))
        let brief = PrepContext.brief(course: course,
                                      courseRounds: courseRounds,
                                      recentRounds: recent)
        isGenerating = true
        errorText = nil
        Task {
            do {
                let advisories = try await AnthropicService.generatePrep(brief: brief, apiKey: key)
                let json = (try? JSONEncoder().encode(advisories))
                    .flatMap { String(data: $0, encoding: .utf8) } ?? ""
                await MainActor.run {
                    let prep = PrepPlan(date: .now,
                                        courseName: course.name,
                                        modelUsed: AnthropicService.defaultModel,
                                        advisoriesJSON: json,
                                        brief: brief)
                    modelContext.insert(prep)
                    modelContext.saveOrReport()
                    AuditService.shared.log(
                        entityType: "PrepPlan",
                        entityID: prep.idempotencyKey,
                        entityLabel: prep.courseName,
                        action: "insert",
                        summary: "Generated pre-round prep for \(prep.courseName)")
                    isGenerating = false
                    onCreated(prep)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorText = (error as? LocalizedError)?.errorDescription
                        ?? error.localizedDescription
                }
            }
        }
    }
}
