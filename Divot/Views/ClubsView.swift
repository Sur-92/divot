import SwiftUI
import SwiftData

struct ClubsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\BagClub.addedAt)]) private var clubs: [BagClub]

    private var sortedClubs: [BagClub] {
        clubs.sorted { a, b in
            if a.bagOrder != b.bagOrder {
                return a.bagOrder < b.bagOrder
            }
            // Tie-break for unassigned: category then addedAt.
            if a.category.sortOrder != b.category.sortOrder {
                return a.category.sortOrder < b.category.sortOrder
            }
            return a.addedAt < b.addedAt
        }
    }

    private func backfillBagOrderIfNeeded() {
        // If every club has bagOrder 0, they're unassigned — number them 1-N
        // using the current category + addedAt order as the baseline.
        guard !clubs.isEmpty, clubs.allSatisfy({ $0.bagOrder == 0 }) else { return }
        let ordered = clubs.sorted { a, b in
            if a.category.sortOrder != b.category.sortOrder {
                return a.category.sortOrder < b.category.sortOrder
            }
            return a.addedAt < b.addedAt
        }
        for (index, club) in ordered.enumerated() {
            club.bagOrder = index + 1
        }
        try? modelContext.save()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                if clubs.isEmpty {
                    emptyState
                } else {
                    summaryRow
                    clubsTable
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .onAppear { backfillBagOrderIfNeeded() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                Text("THE BAG")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(4)
                    .foregroundStyle(Theme.accent)
                Text("Fourteen slots. These are yours.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.dim)
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: 28, height: 1.5)
                    .padding(.top, 2)
            }
            Spacer()
            Button(action: addClub) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("ADD CLUB")
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

    // MARK: - Summary

    private var summaryRow: some View {
        HStack(spacing: 12) {
            summaryChip(label: "CLUBS", value: "\(clubs.count)")
            ForEach(ClubCategory.allCases) { cat in
                let count = clubs.filter { $0.category == cat }.count
                if count > 0 {
                    summaryChip(label: cat.shortName, value: "\(count)")
                }
            }
            Spacer()
        }
    }

    private func summaryChip(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .tracking(1.8)
                .foregroundStyle(Theme.dim)
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Theme.primaryText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassPanel(cornerRadius: 3, padding: 0)
        .padding(.horizontal, 0)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bag.fill")
                .font(.system(size: 38, weight: .ultraLight))
                .foregroundStyle(Theme.accent.opacity(0.6))
            Text("BAG IS EMPTY")
                .font(.system(size: 12, weight: .semibold))
                .tracking(3)
                .foregroundStyle(Theme.primaryText)
            Text("Tap ADD CLUB to rack the first one.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.dim)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .glassPanel(padding: 32)
    }

    // MARK: - Clubs table

    private var clubsTable: some View {
        let clubs = sortedClubs
        return VStack(spacing: 0) {
            columnHeader
            Rectangle().fill(Theme.hairline).frame(height: 1)
            ForEach(Array(clubs.enumerated()), id: \.element.id) { index, club in
                ClubEditRow(
                    club: club,
                    onDelete: { deleteClub(club) },
                    onMoveUp: index > 0 ? { move(club, direction: -1) } : nil,
                    onMoveDown: index < clubs.count - 1 ? { move(club, direction: 1) } : nil,
                    isAlternate: index.isMultiple(of: 2)
                )
            }
        }
        .glassPanel(padding: 0)
    }

    private var columnHeader: some View {
        HStack(spacing: 0) {
            Text("TYPE")      .frame(width: 80,  alignment: .leading).padding(.leading, 16)
            Text("#")         .frame(width: 50,  alignment: .center)
            Text("MAKE")      .frame(width: 100, alignment: .leading)
            Text("MODEL")     .frame(width: 140, alignment: .leading)
            Text("LOFT")      .frame(width: 62,  alignment: .trailing)
            Text("SHAFT")     .frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 12)
            Text("GRIP")      .frame(width: 150, alignment: .leading).padding(.leading, 8)
            Text("YEAR")      .frame(width: 58,  alignment: .trailing)
            Text("ORDER")     .frame(width: 56,  alignment: .center)
            Color.clear.frame(width: 34)
        }
        .font(.system(size: 9, weight: .semibold))
        .tracking(2)
        .foregroundStyle(Theme.accent)
        .padding(.vertical, 10)
    }

    // MARK: - Actions

    private func addClub() {
        // New club goes to the end of the bag.
        let maxOrder = clubs.map(\.bagOrder).max() ?? 0
        let club = BagClub(
            manufacturer: "",
            modelName: "",
            year: 0,
            category: .iron(defaultIfMissing: clubs),
            loft: "",
            shaft: "",
            notes: "",
            bagOrder: maxOrder + 1
        )
        modelContext.insert(club)
        try? modelContext.save()

        AuditService.shared.log(
            entityType: "BagClub",
            entityID: club.idempotencyKey,
            entityLabel: "New bag slot",
            action: "insert",
            summary: "Added a new club slot to the bag"
        )
    }

    private func deleteClub(_ club: BagClub) {
        let label = club.displayTitle
        let id = club.idempotencyKey
        modelContext.delete(club)
        try? modelContext.save()

        AuditService.shared.log(
            entityType: "BagClub",
            entityID: id,
            entityLabel: label,
            action: "delete",
            summary: "Removed \(label) from the bag"
        )
    }

    /// Swap the club with its neighbour. direction: -1 = up, +1 = down.
    private func move(_ club: BagClub, direction: Int) {
        let ordered = sortedClubs
        guard let idx = ordered.firstIndex(where: { $0.id == club.id }) else { return }
        let neighbourIdx = idx + direction
        guard ordered.indices.contains(neighbourIdx) else { return }
        let neighbour = ordered[neighbourIdx]
        let tmp = club.bagOrder
        club.bagOrder = neighbour.bagOrder
        neighbour.bagOrder = tmp
        try? modelContext.save()
    }
}

// MARK: - Category default helper

private extension ClubCategory {
    /// Picks a sensible default for a new empty slot:
    /// Driver if bag has none, then fairway, then irons, etc.
    static func iron(defaultIfMissing clubs: [BagClub]) -> ClubCategory {
        if !clubs.contains(where: { $0.category == .driver })   { return .driver }
        if !clubs.contains(where: { $0.category == .fairway })  { return .fairway }
        if !clubs.contains(where: { $0.category == .ironSet })  { return .ironSet }
        if !clubs.contains(where: { $0.category == .wedge })    { return .wedge }
        if !clubs.contains(where: { $0.category == .putter })   { return .putter }
        return .hybrid
    }
}

// MARK: - Inline edit row

struct ClubEditRow: View {
    @Bindable var club: BagClub
    var onDelete: () -> Void
    var onMoveUp: (() -> Void)? = nil
    var onMoveDown: (() -> Void)? = nil
    var isAlternate: Bool = false

    @State private var showDeleteConfirm = false

    var body: some View {
        HStack(spacing: 0) {
            categoryMenu
                .frame(width: 80, alignment: .leading)
                .padding(.leading, 16)

            TextField("", text: $club.clubNumber, prompt: Text("—"))
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.accent)
                .frame(width: 50, alignment: .center)

            TextField("", text: $club.manufacturer, prompt: Text("Make"))
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.primaryText)
                .frame(width: 100, alignment: .leading)

            TextField("", text: $club.modelName, prompt: Text("Model"))
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(Theme.primaryText)
                .frame(width: 140, alignment: .leading)

            TextField("", text: $club.loft, prompt: Text("—"))
                .textFieldStyle(.plain)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Theme.primaryText)
                .frame(width: 62, alignment: .trailing)

            TextField("", text: $club.shaft, prompt: Text("Shaft (e.g. Ventus 6 S)"))
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(Theme.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 12)

            TextField("", text: $club.grip, prompt: Text("Grip"))
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(Theme.primaryText)
                .frame(width: 150, alignment: .leading)
                .padding(.leading, 8)

            TextField("", value: $club.year,
                      format: .number.grouping(.never))
                .textFieldStyle(.plain)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(club.year > 0 ? Theme.primaryText : Theme.dim)
                .frame(width: 58, alignment: .trailing)

            // Reorder buttons
            VStack(spacing: 2) {
                orderButton(icon: "chevron.up", action: onMoveUp, help: "Move up")
                orderButton(icon: "chevron.down", action: onMoveDown, help: "Move down")
            }
            .frame(width: 56)

            // Delete with confirmation
            Button { showDeleteConfirm = true } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.red.opacity(0.7))
                    .frame(width: 34, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Remove from bag")
        }
        .padding(.vertical, 10)
        .background(isAlternate ? Color.white.opacity(0.04) : Color.clear)
        .alert("Remove this club from your bag?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) { onDelete() }
        } message: {
            Text("\(club.displayTitle) will be removed. This can't be undone.")
        }
    }

    private func orderButton(icon: String, action: (() -> Void)?, help: String) -> some View {
        Button {
            action?()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(action == nil ? Theme.dimmer : Theme.accent)
                .frame(width: 22, height: 16)
                .contentShape(Rectangle())
                .overlay(RoundedRectangle(cornerRadius: 2)
                    .stroke(action == nil ? Theme.hairline : Theme.accent.opacity(0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
        .help(help)
    }

    private var categoryMenu: some View {
        Menu {
            ForEach(ClubCategory.allCases) { cat in
                Button(cat.displayName) { club.category = cat }
            }
        } label: {
            HStack(spacing: 6) {
                Text(club.category.shortName)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.8)
                    .foregroundStyle(Theme.accent)
                Image(systemName: "chevron.down")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(Theme.dim)
            }
            .padding(.horizontal, 8)
            .frame(height: 26)
            .overlay(RoundedRectangle(cornerRadius: 3)
                .stroke(Theme.accent.opacity(0.4), lineWidth: 1))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }
}
