import SwiftUI
import SwiftData

// MARK: - Per-category color

extension ClubCategory {
    /// Color used to tint the category label in the bag table. Each
    /// category has its own hue so the bag reads at a glance.
    var color: Color {
        switch self {
        case .driver:   return Color(red: 1.00, green: 0.70, blue: 0.20)   // gold
        case .fairway:  return Color(red: 0.55, green: 0.80, blue: 0.98)   // light blue
        case .hybrid:   return Color(red: 0.40, green: 0.85, blue: 0.85)   // teal
        case .ironSet:  return Color(red: 0.90, green: 0.92, blue: 0.96)   // silver-white
        case .wedge:    return Color(red: 0.55, green: 0.88, blue: 0.60)   // light green
        case .putter:   return Color(red: 0.78, green: 0.62, blue: 0.96)   // violet
        }
    }
}

struct ClubsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\BagClub.addedAt)]) private var clubs: [BagClub]

    /// Whether the Retired section is expanded.
    @State private var showRetired: Bool = false

    private var activeClubs: [BagClub]   { clubs.filter { !$0.isRetired } }
    private var retiredClubs: [BagClub]  { clubs.filter { $0.isRetired } }

    private var sortedClubs: [BagClub] {
        activeClubs.sorted { a, b in
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

    /// Retired clubs sorted newest-retired first.
    private var sortedRetired: [BagClub] {
        retiredClubs.sorted {
            ($0.retiredAt ?? .distantPast) > ($1.retiredAt ?? .distantPast)
        }
    }

    private func backfillBagOrderIfNeeded() {
        // If every active club has bagOrder 0, they're unassigned —
        // number them 1-N using category + addedAt order as the baseline.
        guard !activeClubs.isEmpty,
              activeClubs.allSatisfy({ $0.bagOrder == 0 }) else { return }
        let ordered = activeClubs.sorted { a, b in
            if a.category.sortOrder != b.category.sortOrder {
                return a.category.sortOrder < b.category.sortOrder
            }
            return a.addedAt < b.addedAt
        }
        for (index, club) in ordered.enumerated() {
            club.bagOrder = index + 1
        }
        modelContext.saveOrReport()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                if activeClubs.isEmpty && retiredClubs.isEmpty {
                    emptyState
                } else if activeClubs.isEmpty {
                    bagEmptyButHasRetired
                    retiredSection
                } else {
                    summaryRow
                    clubsTable
                    if !retiredClubs.isEmpty {
                        retiredSection
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .onAppear { backfillBagOrderIfNeeded() }
    }

    // MARK: - Retired section

    private var bagEmptyButHasRetired: some View {
        VStack(spacing: 12) {
            Image(systemName: "bag")
                .font(.system(size: 38, weight: .ultraLight))
                .foregroundStyle(Theme.dim)
            Text("BAG IS EMPTY")
                .font(.system(size: 12, weight: .semibold))
                .tracking(3)
                .foregroundStyle(Theme.primaryText)
            Text("All clubs are retired. Restore one or add a new club.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.dim)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
        .glassPanel(padding: 28)
    }

    private var retiredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    showRetired.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: showRetired ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.accent)
                    Text("RETIRED")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(3)
                        .foregroundStyle(Theme.accent)
                    Text("\(retiredClubs.count)")
                        .font(.system(size: 10, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.dim)
                    Rectangle()
                        .fill(Theme.hairline)
                        .frame(height: 1)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showRetired {
                VStack(spacing: 0) {
                    ForEach(Array(sortedRetired.enumerated()), id: \.element.id) { index, club in
                        RetiredClubRow(
                            club: club,
                            isAlternate: index.isMultiple(of: 2),
                            onRestore: { restoreClub(club) },
                            onDelete:  { deleteClub(club) }
                        )
                    }
                }
                .glassPanel(padding: 0)
            }
        }
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
            summaryChip(label: "CLUBS", value: "\(activeClubs.count)", color: nil)
            ForEach(ClubCategory.allCases) { cat in
                let count = activeClubs.filter { $0.category == cat }.count
                if count > 0 {
                    summaryChip(label: cat.shortName,
                                value: "\(count)",
                                color: cat.color)
                }
            }
            Spacer()
        }
    }

    private func summaryChip(label: String,
                             value: String,
                             color: Color?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .tracking(1.8)
                .foregroundStyle(color ?? Theme.dim)
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
                    onRetire: { retireClub(club) },
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
        modelContext.saveOrReport()

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
        modelContext.saveOrReport()

        AuditService.shared.log(
            entityType: "BagClub",
            entityID: id,
            entityLabel: label,
            action: "delete",
            summary: "Removed \(label) from the bag"
        )
    }

    /// Soft-retires a club — flips `isRetired`, stamps `retiredAt`, and
    /// leaves the row in place so it can be restored later.
    private func retireClub(_ club: BagClub) {
        club.isRetired = true
        club.retiredAt = .now
        modelContext.saveOrReport()

        AuditService.shared.log(
            entityType: "BagClub",
            entityID: club.idempotencyKey,
            entityLabel: club.displayTitle,
            action: "retire",
            summary: "Retired \(club.displayTitle)"
        )
    }

    /// Brings a retired club back into the active bag at the end of the line.
    private func restoreClub(_ club: BagClub) {
        let maxOrder = activeClubs.map(\.bagOrder).max() ?? 0
        club.isRetired = false
        club.retiredAt = nil
        club.bagOrder = maxOrder + 1
        modelContext.saveOrReport()

        AuditService.shared.log(
            entityType: "BagClub",
            entityID: club.idempotencyKey,
            entityLabel: club.displayTitle,
            action: "restore",
            summary: "Restored \(club.displayTitle) to the bag"
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
        modelContext.saveOrReport()
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
    var onRetire: () -> Void
    var onDelete: () -> Void
    var onMoveUp: (() -> Void)? = nil
    var onMoveDown: (() -> Void)? = nil
    var isAlternate: Bool = false

    @State private var showDeleteConfirm = false

    var body: some View {
        HStack(spacing: 0) {
            // Solid category-color stripe down the left edge — fast read
            // for which class of club this row is.
            Rectangle()
                .fill(club.category.color)
                .frame(width: 3)

            categoryMenu
                .frame(width: 80, alignment: .leading)
                .padding(.leading, 13)

            TextField("", text: $club.clubNumber, prompt: Text("—"))
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(club.category.color)
                .frame(width: 50, alignment: .center)

            TextField("", text: $club.manufacturer, prompt: Text("Make"))
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(club.category.color)
                .frame(width: 100, alignment: .leading)

            TextField("", text: $club.modelName, prompt: Text("Model"))
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(club.category.color)
                .frame(width: 140, alignment: .leading)

            TextField("", text: $club.loft, prompt: Text("—"))
                .textFieldStyle(.plain)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(club.category.color)
                .frame(width: 62, alignment: .trailing)

            TextField("", text: $club.shaft, prompt: Text("Shaft (e.g. Ventus 6 S)"))
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(club.category.color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 12)

            TextField("", text: $club.grip, prompt: Text("Grip"))
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(club.category.color)
                .frame(width: 150, alignment: .leading)
                .padding(.leading, 8)

            TextField("", value: $club.year,
                      format: .number.grouping(.never))
                .textFieldStyle(.plain)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(club.year > 0
                                 ? club.category.color
                                 : club.category.color.opacity(0.45))
                .frame(width: 58, alignment: .trailing)

            // Reorder buttons
            VStack(spacing: 2) {
                orderButton(icon: "chevron.up", action: onMoveUp, help: "Move up")
                orderButton(icon: "chevron.down", action: onMoveDown, help: "Move down")
            }
            .frame(width: 56)

            // Retire (soft) and Delete (hard) — split into a small menu
            // so the trash button can't be hit by accident.
            Menu {
                Button {
                    onRetire()
                } label: {
                    Label("Retire", systemImage: "archivebox")
                }
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete permanently", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.dim)
                    .frame(width: 34, height: 28)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Retire or delete")
        }
        .padding(.vertical, 10)
        .background(
            ZStack {
                // Per-row tint in the category color so the whole row
                // reads as that club type at a glance.
                club.category.color.opacity(0.12)
                if isAlternate {
                    Color.white.opacity(0.04)
                }
            }
        )
        .alert("Delete this club permanently?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("\(club.displayTitle) will be removed for good. " +
                 "Use Retire instead if you might want it back.")
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
                    .foregroundStyle(club.category.color)
                Image(systemName: "chevron.down")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(Theme.dim)
            }
            .padding(.horizontal, 8)
            .frame(height: 26)
            .overlay(RoundedRectangle(cornerRadius: 3)
                .stroke(club.category.color.opacity(0.5), lineWidth: 1))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }
}

// MARK: - Retired club row (compact, restore + delete)

struct RetiredClubRow: View {
    let club: BagClub
    var isAlternate: Bool = false
    var onRestore: () -> Void
    var onDelete: () -> Void

    @State private var showDeleteConfirm = false

    private var retiredDateText: String {
        guard let d = club.retiredAt else { return "—" }
        return d.formatted(date: .abbreviated, time: .omitted)
    }

    var body: some View {
        HStack(spacing: 14) {
            // Left-edge stripe in the (dimmed) category color so retired
            // rows still read as the right club class at a glance.
            Rectangle()
                .fill(club.category.color.opacity(0.6))
                .frame(width: 3)

            // Category badge — colored but slightly dimmed because retired
            Text(club.category.shortName)
                .font(.system(size: 10, weight: .bold))
                .tracking(1.8)
                .foregroundStyle(club.category.color.opacity(0.6))
                .frame(width: 80, alignment: .leading)
                .padding(.leading, 13)

            Text(club.clubNumber.isEmpty ? "—" : club.clubNumber)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.dim)
                .frame(width: 50, alignment: .center)

            Text(club.displayTitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.dim)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 1) {
                Text("RETIRED")
                    .font(.system(size: 8, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(Theme.dimmer)
                Text(retiredDateText)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.dim)
            }
            .frame(width: 110, alignment: .trailing)

            // Restore
            Button(action: onRestore) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 9, weight: .bold))
                    Text("RESTORE")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.5)
                }
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .overlay(RoundedRectangle(cornerRadius: 3)
                    .stroke(Theme.accent.opacity(0.7), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help("Move \(club.displayTitle) back into the active bag")

            // Hard delete
            Button { showDeleteConfirm = true } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.red.opacity(0.7))
                    .frame(width: 34, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Delete permanently")
        }
        .padding(.vertical, 10)
        .padding(.trailing, 12)
        .background(
            ZStack {
                club.category.color.opacity(0.06)
                if isAlternate {
                    Color.white.opacity(0.04)
                }
            }
        )
        .alert("Delete this retired club permanently?",
               isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("\(club.displayTitle) will be removed for good. This can't be undone.")
        }
    }
}
