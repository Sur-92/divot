import SwiftUI
import SwiftData

/// Editor for one training session — date, name, notes, duration, plus
/// the list of exercises performed (sets/reps/weight per row).
///
/// MVP version: a placeholder shell so the rest of TrainingView compiles
/// while the full set/rep editor lands.
struct TrainingSessionEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var session: TrainingSession
    var onSave: () -> Void

    @Query(sort: \TrainingExercise.name) private var library: [TrainingExercise]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TRAINING SESSION")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(3)
                        .foregroundStyle(Theme.accent)
                    Text("Log what you actually did.")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.dim)
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.dim)
                        .frame(width: 26, height: 26)
                        .overlay(Circle().stroke(Theme.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            Rectangle().fill(Theme.accent).frame(width: 28, height: 1.5)

            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("DATE")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(Theme.dim)
                    DatePicker("", selection: $session.date,
                               displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
                Spacer()
                VStack(alignment: .leading, spacing: 6) {
                    Text("DURATION (MIN)")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(Theme.dim)
                    TextField("", value: $session.durationMinutes,
                              format: .number.grouping(.never))
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 13, weight: .semibold,
                                      design: .monospaced))
                        .foregroundStyle(Theme.primaryText)
                        .frame(width: 80)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.05)))
                        .overlay(RoundedRectangle(cornerRadius: 3)
                            .stroke(Theme.hairline, lineWidth: 1))
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("NAME")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Theme.dim)
                TextField("", text: $session.name,
                          prompt: Text("e.g. Pre-round warm-up")
                            .foregroundStyle(Theme.dimmer))
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.primaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.05)))
                    .overlay(RoundedRectangle(cornerRadius: 3)
                        .stroke(Theme.hairline, lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("NOTES")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Theme.dim)
                TextEditor(text: $session.notes)
                    .font(.system(size: 12))
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(Theme.primaryText)
                    .frame(minHeight: 60)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.05)))
                    .overlay(RoundedRectangle(cornerRadius: 3)
                        .stroke(Theme.hairline, lineWidth: 1))
            }

            HStack(spacing: 8) {
                Text("EXERCISES")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Theme.accent)
                Text("\(session.performances.count)")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.dim)
                Spacer()
                Menu {
                    if library.isEmpty {
                        Text("No exercises in your library yet")
                    } else {
                        ForEach(library) { ex in
                            Button(ex.displayTitle) { addPerformance(ex) }
                        }
                    }
                } label: {
                    Text("+ ADD")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .overlay(RoundedRectangle(cornerRadius: 3)
                            .stroke(Theme.accent.opacity(0.6), lineWidth: 1))
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
            }

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(session.sortedPerformances) { perf in
                        performanceRow(perf)
                        Rectangle()
                            .fill(Theme.hairline.opacity(0.4))
                            .frame(height: 1)
                    }
                }
            }
            .frame(minHeight: 120, maxHeight: 320)

            HStack {
                Spacer()
                Button {
                    onSave()
                    dismiss()
                } label: {
                    Text("DONE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(RoundedRectangle(cornerRadius: 3)
                            .fill(Theme.accent))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(28)
        .frame(minWidth: 600, idealWidth: 700, minHeight: 520)
        .background(
            ZStack {
                Color.black.opacity(0.92)
                LinearGradient(
                    colors: [.black.opacity(0.7), .black.opacity(0.95)],
                    startPoint: .top, endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        )
    }

    private func performanceRow(_ perf: PerformedExercise) -> some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(perf.exercise?.category.color ?? Theme.accent)
                .frame(width: 3, height: 30)
            Text(perf.exercise?.displayTitle ?? "—")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(perf.exercise?.category.color ?? Theme.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)

            miniInt("SETS", value: bindingForSets(perf))
            miniInt("REPS", value: bindingForReps(perf))
            miniDouble("LB", value: bindingForWeight(perf))
            miniInt("HOLD s", value: bindingForDuration(perf))

            Button {
                deletePerformance(perf)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.red.opacity(0.7))
                    .frame(width: 24, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private func miniInt(_ label: String,
                         value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 7, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.dim)
            TextField("", value: value, format: .number.grouping(.never))
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .font(.system(size: 11, weight: .semibold,
                              design: .monospaced))
                .foregroundStyle(Theme.primaryText)
                .frame(width: 44)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.05)))
                .overlay(RoundedRectangle(cornerRadius: 2)
                    .stroke(Theme.hairline, lineWidth: 1))
        }
    }

    private func miniDouble(_ label: String,
                            value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 7, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.dim)
            TextField("", value: value, format: .number)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .font(.system(size: 11, weight: .semibold,
                              design: .monospaced))
                .foregroundStyle(Theme.primaryText)
                .frame(width: 50)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.05)))
                .overlay(RoundedRectangle(cornerRadius: 2)
                    .stroke(Theme.hairline, lineWidth: 1))
        }
    }

    // MARK: - Bindings (PerformedExercise isn't @Bindable directly here)

    private func bindingForSets(_ p: PerformedExercise) -> Binding<Int> {
        Binding(get: { p.sets }, set: { p.sets = $0 })
    }
    private func bindingForReps(_ p: PerformedExercise) -> Binding<Int> {
        Binding(get: { p.reps }, set: { p.reps = $0 })
    }
    private func bindingForWeight(_ p: PerformedExercise) -> Binding<Double> {
        Binding(get: { p.weightLbs }, set: { p.weightLbs = $0 })
    }
    private func bindingForDuration(_ p: PerformedExercise) -> Binding<Int> {
        Binding(get: { p.durationSeconds }, set: { p.durationSeconds = $0 })
    }

    // MARK: - Actions

    private func addPerformance(_ exercise: TrainingExercise) {
        let order = (session.performances.map(\.order).max() ?? -1) + 1
        let perf = PerformedExercise(
            session: session,
            exercise: exercise,
            order: order,
            sets: exercise.defaultSets,
            reps: exercise.defaultReps,
            durationSeconds: exercise.defaultDurationSeconds
        )
        modelContext.insert(perf)
        session.performances.append(perf)
        try? modelContext.save()
    }

    private func deletePerformance(_ perf: PerformedExercise) {
        if let idx = session.performances.firstIndex(where: { $0.id == perf.id }) {
            session.performances.remove(at: idx)
        }
        modelContext.delete(perf)
        try? modelContext.save()
    }
}
