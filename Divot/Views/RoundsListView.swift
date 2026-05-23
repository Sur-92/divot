import SwiftUI
import SwiftData

struct RoundsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Round.date, order: .reverse) private var allRounds: [Round]
    @State private var selectedRound: Round?
    @State private var showingStartSheet = false
    @State private var showArchived = false

    private var visibleRounds: [Round] {
        allRounds.filter { $0.isArchived == showArchived }
    }

    private var archivedCount: Int {
        allRounds.filter(\.isArchived).count
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                header

                Group {
                    if visibleRounds.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(visibleRounds) { round in
                                    Button {
                                        selectedRound = round
                                    } label: {
                                        RoundRow(round: round)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button("Open") { selectedRound = round }
                                        if round.isArchived {
                                            Button("Restore") { restore(round) }
                                        } else {
                                            Button("Archive") { archive(round) }
                                        }
                                        Divider()
                                        Button("Delete Forever", role: .destructive) { delete(round) }
                                    }
                                    Rectangle()
                                        .fill(Theme.hairline)
                                        .frame(height: 1)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                quoteFooter
            }
            .navigationDestination(item: $selectedRound) { round in
                RoundDetailView(round: round)
            }
            .sheet(isPresented: $showingStartSheet) {
                StartRoundSheet { newRound in
                    selectedRound = newRound
                }
            }
        }
    }

    // MARK: - Quote footer

    private var quoteFooter: some View {
        let quote = GolfQuotes.today
        return HStack(alignment: .center, spacing: 18) {
            Image(systemName: "quote.opening")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.accent.opacity(0.8))

            Text(quote.text)
                .font(.system(size: 16, design: .serif))
                .italic()
                .foregroundStyle(Theme.primaryText.opacity(0.9))
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 12)

            HStack(spacing: 8) {
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: 18, height: 1.5)
                Text(quote.author.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2.5)
                    .foregroundStyle(Theme.accent)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.42))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 1)
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                Text(showArchived ? "ARCHIVED ROUNDS" : "ROUNDS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(4)
                    .foregroundStyle(Theme.accent)
                Text(showArchived
                     ? "Out of sight, not lost."
                     : "Every shot. Every number.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.dim)
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: 28, height: 1.5)
                    .padding(.top, 2)
            }
            Spacer()

            // Archive toggle
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

            Button {
                showingStartSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("NEW ROUND")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2)
                }
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Theme.accent, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 18)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: showArchived ? "archivebox" : "flag.fill")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(Theme.accent.opacity(0.7))
            Text(showArchived ? "NO ARCHIVED ROUNDS" : "NO ROUNDS LOGGED")
                .font(.system(size: 12, weight: .semibold))
                .tracking(3)
                .foregroundStyle(Theme.primaryText)
            Text(showArchived
                 ? "Archived rounds will show up here."
                 : "Tap NEW ROUND to start your card.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.dim)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func delete(_ round: Round) {
        modelContext.delete(round)
        try? modelContext.save()
    }

    private func archive(_ round: Round) {
        round.isArchived = true
        try? modelContext.save()
    }

    private func restore(_ round: Round) {
        round.isArchived = false
        try? modelContext.save()
    }
}

// MARK: - Round row

struct RoundRow: View {
    let round: Round

    private var sign: String { round.scoreToPar >= 0 ? "+" : "" }
    private var scoreColor: Color {
        if round.totalScore == 0 { return Theme.dim }
        return round.scoreToPar <= 0 ? Theme.accent : Theme.primaryText
    }

    private var archivedBadge: some View {
        Text("ARCHIVED")
            .font(.system(size: 8, weight: .bold))
            .tracking(2)
            .foregroundStyle(Theme.dim)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .overlay(RoundedRectangle(cornerRadius: 2)
                .stroke(Theme.hairline, lineWidth: 1))
    }

    @ViewBuilder
    private var roundTypeBadge: some View {
        if round.roundType != .full18 {
            Text(round.roundType.shortBadge)
                .font(.system(size: 8, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(.black)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 2).fill(Theme.accent))
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            // Date column
            VStack(alignment: .leading, spacing: 4) {
                Text(round.date.formatted(.dateTime.month(.abbreviated).day()).uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Theme.accent)
                Text(round.date.formatted(.dateTime.year()))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Theme.dimmer)
            }
            .frame(width: 64, alignment: .leading)

            Rectangle()
                .fill(Theme.hairline)
                .frame(width: 1, height: 32)

            // Course logo
            CourseLogo(assetName: round.course?.logoAssetName, height: 28)

            // Course & tees
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(round.courseName.isEmpty ? "UNTITLED ROUND" : round.courseName.uppercased())
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(1)
                    roundTypeBadge
                    if round.isArchived {
                        archivedBadge
                    }
                }
                HStack(spacing: 6) {
                    if !round.tees.isEmpty {
                        Text(round.tees.uppercased())
                            .font(.system(size: 9, weight: .medium))
                            .tracking(1.5)
                            .foregroundStyle(Theme.dim)
                    }
                    Text(String(format: "· %.1f / %d", round.courseRating, round.slopeRating))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Theme.dimmer)
                    if !round.simulatedCourseName.isEmpty {
                        Text("· SIM: \(round.simulatedCourseName.uppercased())")
                            .font(.system(size: 9, weight: .medium))
                            .tracking(1.5)
                            .foregroundStyle(Theme.accent)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Score block
            if round.totalScore > 0 {
                HStack(spacing: 14) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("TOTAL")
                            .font(.system(size: 8, weight: .semibold))
                            .tracking(1.8)
                            .foregroundStyle(Theme.dim)
                        Text("\(round.totalScore)")
                            .font(.system(size: 26, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(Theme.primaryText)
                    }
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("PAR")
                            .font(.system(size: 8, weight: .semibold))
                            .tracking(1.8)
                            .foregroundStyle(Theme.dim)
                        Text("\(sign)\(round.scoreToPar)")
                            .font(.system(size: 26, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(scoreColor)
                    }
                }
            } else {
                Text("IN PROGRESS")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Theme.accent.opacity(0.7))
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.dimmer)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .opacity(round.isArchived ? 0.55 : 1)
    }
}
