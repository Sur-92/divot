import SwiftUI
import SwiftData

/// Editor for one library exercise — fills in name, category, target,
/// instructions, equipment, default prescription, and an optional
/// tutorial video URL.
struct TrainingExerciseEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var exercise: TrainingExercise
    var onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("EXERCISE")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(3)
                        .foregroundStyle(Theme.accent)
                    Text("Library entry — sessions pull from here.")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.dim)
                }
                Spacer()
                closeButton
            }

            Rectangle().fill(Theme.accent).frame(width: 28, height: 1.5)

            field(label: "NAME", text: $exercise.name,
                  prompt: "e.g. Pallof Press")

            // Category
            VStack(alignment: .leading, spacing: 6) {
                Text("CATEGORY")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Theme.dim)
                HStack(spacing: 8) {
                    ForEach(TrainingCategory.allCases) { cat in
                        Button {
                            exercise.category = cat
                        } label: {
                            Text(cat.shortName)
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1.5)
                                .foregroundStyle(exercise.category == cat
                                                 ? .black : cat.color)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Group {
                                        if exercise.category == cat {
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(cat.color)
                                        } else {
                                            RoundedRectangle(cornerRadius: 3)
                                                .stroke(cat.color.opacity(0.5),
                                                        lineWidth: 1)
                                        }
                                    }
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack(spacing: 14) {
                field(label: "TARGET AREA", text: $exercise.targetArea,
                      prompt: "Hips · Core · T-spine")
                field(label: "EQUIPMENT", text: $exercise.equipment,
                      prompt: "Dumbbells · Band · None")
            }

            // Default prescription
            VStack(alignment: .leading, spacing: 6) {
                Text("DEFAULT PRESCRIPTION")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Theme.dim)
                HStack(spacing: 12) {
                    smallNumberField("SETS", value: $exercise.defaultSets)
                    smallNumberField("REPS", value: $exercise.defaultReps)
                    smallNumberField("HOLD (s)",
                                     value: $exercise.defaultDurationSeconds)
                    Spacer()
                }
            }

            field(label: "VIDEO URL", text: $exercise.videoURL,
                  prompt: "https://youtube.com/...",
                  monospaced: true)

            VStack(alignment: .leading, spacing: 6) {
                Text("FORM CUES")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Theme.dim)
                TextEditor(text: $exercise.instructions)
                    .font(.system(size: 12))
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(Theme.primaryText)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.05)))
                    .overlay(RoundedRectangle(cornerRadius: 3)
                        .stroke(Theme.hairline, lineWidth: 1))
            }

            HStack {
                Spacer()
                Button {
                    onSave()
                    dismiss()
                } label: {
                    Text("SAVE")
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
        .frame(minWidth: 560, idealWidth: 620)
        .background(sheetBackdrop)
    }

    // MARK: - Pieces

    private var closeButton: some View {
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

    private var sheetBackdrop: some View {
        ZStack {
            Color.black.opacity(0.92)
            LinearGradient(
                colors: [.black.opacity(0.7), .black.opacity(0.95)],
                startPoint: .top, endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }

    private func field(label: String,
                       text: Binding<String>,
                       prompt: String,
                       monospaced: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Theme.dim)
            TextField("", text: text,
                      prompt: Text(prompt).foregroundStyle(Theme.dimmer))
                .textFieldStyle(.plain)
                .font(.system(size: 13,
                              design: monospaced ? .monospaced : .default))
                .foregroundStyle(Theme.primaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.05)))
                .overlay(RoundedRectangle(cornerRadius: 3)
                    .stroke(Theme.hairline, lineWidth: 1))
        }
        .frame(maxWidth: .infinity)
    }

    private func smallNumberField(_ label: String,
                                  value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Theme.dim)
            TextField("", value: value, format: .number.grouping(.never))
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .font(.system(size: 13, weight: .semibold,
                              design: .monospaced))
                .foregroundStyle(Theme.primaryText)
                .frame(width: 64)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.05)))
                .overlay(RoundedRectangle(cornerRadius: 3)
                    .stroke(Theme.hairline, lineWidth: 1))
        }
    }
}
