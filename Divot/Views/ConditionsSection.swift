import SwiftUI

/// Per-nine conditions editor shown on the round detail. Front/back toggle
/// for 18-hole rounds (single nine for 9-hole rounds), graded 3-way pickers
/// and checkboxes grouped by category, plus a "copy front → back" shortcut.
/// All controls default to unset, so an untouched round records nothing.
struct ConditionsSection: View {
    let round: Round
    @State private var showBack: Bool

    init(round: Round) {
        self.round = round
        _showBack = State(initialValue: round.roundType == .back9)
    }

    private var isFull18: Bool { round.roundType == .full18 }

    // MARK: - Current nine read/write

    private var current: NineConditions {
        showBack ? round.backConditionsValue : round.frontConditionsValue
    }
    private func setCurrent(_ v: NineConditions) {
        if showBack { round.backConditionsValue = v } else { round.frontConditionsValue = v }
    }
    private func gradedBinding(_ kp: WritableKeyPath<NineConditions, Int>) -> Binding<Int> {
        Binding(get: { current[keyPath: kp] },
                set: { var c = current; c[keyPath: kp] = $0; setCurrent(c) })
    }
    private func flagBinding(_ kp: WritableKeyPath<NineConditions, Bool>) -> Binding<Bool> {
        Binding(get: { current[keyPath: kp] },
                set: { var c = current; c[keyPath: kp] = $0; setCurrent(c) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isFull18 { nineToggle }
            ForEach(ConditionCategory.allCases) { cat in
                categoryBlock(cat)
            }
        }
    }

    // MARK: - Front / back toggle + copy

    private var nineToggle: some View {
        HStack(spacing: 12) {
            Picker("", selection: $showBack) {
                Text("FRONT 9").tag(false)
                Text("BACK 9").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            .labelsHidden()

            Spacer()

            Button {
                round.backConditionsValue = round.frontConditionsValue
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 9, weight: .semibold))
                    Text("COPY FRONT → BACK")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(1)
                }
                .foregroundStyle(Theme.dim)
            }
            .buttonStyle(.plain)
            .help("Copy the front-nine conditions onto the back nine")
        }
    }

    // MARK: - Per-category block

    @ViewBuilder
    private func categoryBlock(_ cat: ConditionCategory) -> some View {
        let graded = ConditionsCatalog.graded(in: cat)
        let flags = ConditionsCatalog.flags(in: cat)
        if !graded.isEmpty || !flags.isEmpty {
            VStack(alignment: .leading, spacing: 9) {
                Text(cat.rawValue.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Theme.accent.opacity(0.85))

                ForEach(graded) { spec in
                    let wide = spec.options.count > 3   // numbered scale vs word picker
                    HStack(alignment: wide ? .top : .center, spacing: 12) {
                        Text(spec.label)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.dim)
                            .frame(width: 78, alignment: .leading)
                            .padding(.top, wide ? 5 : 0)
                        if wide {
                            ScalePicker(options: spec.options, value: gradedBinding(spec.keyPath))
                        } else {
                            TriPicker(options: spec.options, value: gradedBinding(spec.keyPath))
                        }
                    }
                }

                if !flags.isEmpty {
                    LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading),
                                        GridItem(.flexible(), alignment: .leading)],
                              alignment: .leading, spacing: 7) {
                        ForEach(flags) { spec in
                            ConditionCheckbox(label: spec.label, on: flagBinding(spec.keyPath))
                        }
                    }
                    .padding(.top, graded.isEmpty ? 0 : 2)
                }
            }
        }
    }
}

// MARK: - 3-way graded picker (tap a segment to set, tap again to clear)

private struct TriPicker: View {
    let options: [String]
    @Binding var value: Int   // 0 = unset, 1...3

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { idx, opt in
                let v = idx + 1
                let selected = value == v
                Button {
                    value = selected ? 0 : v
                } label: {
                    Text(opt)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(selected ? .black : Theme.dim)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(selected ? Theme.accent : Color.clear)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if idx < options.count - 1 {
                    Rectangle().fill(Theme.hairline).frame(width: 1)
                }
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.hairline, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Numbered scale picker (for many-level graded items, e.g. green speed)

private struct ScalePicker: View {
    let options: [String]     // descriptor per level; index 0 = level 1
    @Binding var value: Int   // 0 = unset, 1...options.count

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 0) {
                ForEach(0..<options.count, id: \.self) { idx in
                    let v = idx + 1
                    let selected = value == v
                    Button {
                        value = selected ? 0 : v
                    } label: {
                        Text("\(v)")
                            .font(.system(size: 10, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(selected ? .black : Theme.dim)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(selected ? Theme.accent : Color.clear)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if idx < options.count - 1 {
                        Rectangle().fill(Theme.hairline).frame(width: 1)
                    }
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.hairline, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 4))

            // Anchors + the selected level's plain-English descriptor.
            HStack {
                Text("SLOW")
                    .font(.system(size: 8, weight: .medium)).tracking(0.5)
                    .foregroundStyle(Theme.dimmer)
                Spacer()
                if value > 0, value <= options.count {
                    Text(options[value - 1])
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
                Spacer()
                Text("FAST")
                    .font(.system(size: 8, weight: .medium)).tracking(0.5)
                    .foregroundStyle(Theme.dimmer)
            }
        }
    }
}

// MARK: - Checkbox row

private struct ConditionCheckbox: View {
    let label: String
    @Binding var on: Bool

    var body: some View {
        Button {
            on.toggle()
        } label: {
            HStack(spacing: 7) {
                Image(systemName: on ? "checkmark.square.fill" : "square")
                    .font(.system(size: 13))
                    .foregroundStyle(on ? Theme.accent : Theme.dim)
                Text(label)
                    .font(.system(size: 11))
                    .foregroundStyle(on ? Theme.primaryText : Theme.dim)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
