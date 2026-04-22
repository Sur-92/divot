import SwiftUI
import SwiftData

struct HoleShotsView: View {
    @Bindable var hole: Hole
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if hole.shots.isEmpty {
                        emptyState
                    } else {
                        shotsHeader
                        shotsList
                    }
                    holeNotesSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }

            footer
        }
        .frame(minWidth: 760, idealWidth: 880, minHeight: 480, idealHeight: 640)
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
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("SHOT LOG")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(4)
                    .foregroundStyle(Theme.accent)
                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    Text("HOLE \(hole.number)")
                        .font(.system(size: 26, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(Theme.primaryText)
                    Text("PAR \(hole.par)")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(Theme.accent)
                    if hole.score > 0 {
                        let diff = hole.score - hole.par
                        let sign = diff >= 0 ? "+" : ""
                        Text("SCORE \(hole.score) (\(sign)\(diff))")
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(2)
                            .foregroundStyle(diff <= 0 ? Theme.accent : Theme.dim)
                    }
                }
                Text("\(hole.shots.count) \(hole.shots.count == 1 ? "shot" : "shots") logged")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.dim)
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: 28, height: 1.5)
                    .padding(.top, 2)
            }

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.dim)
                    .frame(width: 28, height: 28)
                    .overlay(Circle().stroke(Theme.hairline, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 18)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "figure.golf")
                .font(.system(size: 38, weight: .ultraLight))
                .foregroundStyle(Theme.accent.opacity(0.6))
            Text("NO SHOTS LOGGED")
                .font(.system(size: 12, weight: .semibold))
                .tracking(3)
                .foregroundStyle(Theme.primaryText)
            Text("Tap “Add Shot” to log every swing for this hole.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.dim)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .glassPanel(padding: 32)
    }

    // MARK: - Shots table

    private var shotsHeader: some View {
        HStack(spacing: 0) {
            Text("#").frame(width: 28, alignment: .center)
            Text("CLUB").frame(width: 90, alignment: .center)
            Text("DIST").frame(width: 64, alignment: .trailing).padding(.trailing, 10)
            Text("LIE").frame(width: 110, alignment: .leading)
            Text("RESULT").frame(width: 130, alignment: .leading)
            Text("NOTES").frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 8)
            Color.clear.frame(width: 30)
        }
        .font(.system(size: 9, weight: .semibold))
        .tracking(2)
        .foregroundStyle(Theme.accent)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }

    private var shotsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(hole.sortedShots.enumerated()), id: \.element.id) { idx, shot in
                ShotEditRow(shot: shot, onDelete: { deleteShot(shot) })
                if idx < hole.shots.count - 1 {
                    Rectangle().fill(Theme.hairline).frame(height: 1)
                }
            }
        }
        .glassPanel(padding: 0)
    }

    // MARK: - Hole notes

    private var holeNotesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HOLE NOTES")
                .font(.system(size: 10, weight: .semibold))
                .tracking(3)
                .foregroundStyle(Theme.accent)
            TextEditor(text: $hole.notes)
                .font(.system(size: 13))
                .foregroundStyle(Theme.primaryText)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 70)
                .padding(8)
                .glassPanel(padding: 0)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Theme.hairline).frame(height: 1)
            HStack(spacing: 10) {
                Button(action: syncFromShots) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 10, weight: .bold))
                        Text("SYNC SCORE")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(2)
                    }
                    .foregroundStyle(Theme.dim)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .overlay(RoundedRectangle(cornerRadius: 3)
                        .stroke(Theme.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .help("Set score = shot count, putts = putter count")
                .disabled(hole.shots.isEmpty)

                Spacer()

                Button(action: addShot) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("ADD SHOT")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(2.5)
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 3).fill(Theme.accent))
                }
                .buttonStyle(.plain)

                Button { dismiss() } label: {
                    Text("DONE")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(Theme.primaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .overlay(RoundedRectangle(cornerRadius: 3)
                            .stroke(Theme.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Actions

    private func addShot() {
        let nextNumber = (hole.shots.map(\.number).max() ?? 0) + 1

        let startingLie: Lie = nextNumber == 1 ? .tee : .fairway
        let startingClub: Club = nextNumber == 1 ? .driver : .iron7

        let shot = Shot(number: nextNumber,
                        club: startingClub,
                        distance: 0,
                        lie: startingLie,
                        result: .onTarget)
        shot.hole = hole
        hole.shots.append(shot)
        modelContext.insert(shot)
        try? modelContext.save()

        let courseLabel = hole.round?.courseName ?? "round"
        AuditService.shared.log(
            entityType: "Shot",
            entityID: shot.idempotencyKey,
            entityLabel: "\(courseLabel) · Hole \(hole.number)",
            action: "insert",
            summary: "Logged shot #\(nextNumber) on hole \(hole.number)"
        )
    }

    private func deleteShot(_ shot: Shot) {
        let shotKey = shot.idempotencyKey
        let shotNumber = shot.number
        let courseLabel = hole.round?.courseName ?? "round"

        if let idx = hole.shots.firstIndex(where: { $0.id == shot.id }) {
            hole.shots.remove(at: idx)
        }
        modelContext.delete(shot)
        for (i, s) in hole.sortedShots.enumerated() {
            s.number = i + 1
        }
        try? modelContext.save()

        AuditService.shared.log(
            entityType: "Shot",
            entityID: shotKey,
            entityLabel: "\(courseLabel) · Hole \(hole.number)",
            action: "delete",
            summary: "Deleted shot #\(shotNumber) on hole \(hole.number)"
        )
    }

    private func syncFromShots() {
        hole.score = hole.shots.count
        hole.putts = hole.shots.filter { $0.club == .putter }.count
        hole.greenInRegulation = {
            // GIR = on green in (par - 2) strokes
            let shotsToReachGreen = hole.shots.prefix(hole.par - 2).count
            let reachedGreen = hole.shots.enumerated().first { idx, s in
                s.lie == .green && idx + 1 <= hole.par - 2
            } != nil
            return shotsToReachGreen >= (hole.par - 2) && reachedGreen
        }()
        try? modelContext.save()
    }
}

// MARK: - Shot edit row

struct ShotEditRow: View {
    @Bindable var shot: Shot
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Text("\(shot.number)")
                .frame(width: 28, alignment: .center)
                .font(.system(size: 12, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(Theme.accent)

            clubMenu
                .frame(width: 90)

            TextField("", value: $shot.distance, format: .number)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(Theme.primaryText)
                .frame(width: 58, alignment: .trailing)
                .padding(.trailing, 6)
            Text("YD")
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Theme.dim)
                .padding(.trailing, 10)

            lieMenu.frame(width: 110, alignment: .leading)

            resultMenu.frame(width: 130, alignment: .leading)

            TextField("", text: $shot.notes, prompt: Text("shot notes").foregroundStyle(Theme.dimmer))
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(Theme.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 8)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.red.opacity(0.7))
                    .frame(width: 30, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Delete shot")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }

    // MARK: - Pickers

    private var clubMenu: some View {
        Menu {
            ForEach(Club.grouped, id: \.0) { group, clubs in
                Section(group) {
                    ForEach(clubs) { c in
                        Button {
                            shot.club = c
                        } label: {
                            HStack {
                                Text(c.fullName)
                                Spacer()
                                Text(c.shortName)
                                    .foregroundStyle(Theme.dim)
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(shot.club.shortName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Theme.dim)
            }
            .frame(width: 74, height: 28)
            .overlay(RoundedRectangle(cornerRadius: 3)
                .stroke(Theme.hairline, lineWidth: 1))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }

    private var lieMenu: some View {
        Menu {
            ForEach(Lie.allCases) { l in
                Button(l.displayName) { shot.lie = l }
            }
        } label: {
            HStack(spacing: 4) {
                Text(shot.lie.displayName.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(Theme.primaryText)
                Spacer(minLength: 4)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Theme.dim)
            }
            .padding(.horizontal, 8)
            .frame(height: 28)
            .overlay(RoundedRectangle(cornerRadius: 3)
                .stroke(Theme.hairline, lineWidth: 1))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }

    private var resultMenu: some View {
        Menu {
            ForEach(ShotResult.allCases) { r in
                Button(r.displayName) { shot.result = r }
            }
        } label: {
            HStack(spacing: 4) {
                Circle()
                    .fill(resultColor)
                    .frame(width: 6, height: 6)
                Text(shot.result.displayName.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(Theme.primaryText)
                Spacer(minLength: 4)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Theme.dim)
            }
            .padding(.horizontal, 8)
            .frame(height: 28)
            .overlay(RoundedRectangle(cornerRadius: 3)
                .stroke(Theme.hairline, lineWidth: 1))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }

    private var resultColor: Color {
        switch shot.result {
        case .onTarget, .draw, .fade: return Theme.accent
        case .left, .right, .short, .long: return .yellow.opacity(0.8)
        case .mishit, .penalty: return .red.opacity(0.7)
        }
    }
}
