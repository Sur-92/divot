import SwiftUI
import SwiftData

struct AuditLogView: View {
    // Entries are fetched via AuditService's dedicated ModelContext rather
    // than a @Query on the main context. The main context has been
    // observed to fail a swift_dynamicCast when binding AuditEntry rows
    // (SwiftData migration/cache quirk for a late-added @Model). Pulling
    // through the service's own context sidesteps that entirely.
    @State private var entries: [AuditEntry] = []

    @State private var verifyResult: AuditService.VerifyResult?
    @State private var isVerifying = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                if let result = verifyResult {
                    verifyResultBanner(result)
                }

                if entries.isEmpty {
                    emptyState
                } else {
                    summaryChips
                    entriesSection
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .onAppear(perform: reload)
    }

    private func reload() {
        entries = AuditService.shared.fetchAllDescending()
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                Text("AUDIT LOG")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(4)
                    .foregroundStyle(Theme.accent)
                Text("Append-only · hash-chained · tamper-evident.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.dim)
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: 28, height: 1.5)
                    .padding(.top, 2)
            }
            Spacer()

            Button(action: verify) {
                HStack(spacing: 8) {
                    Image(systemName: isVerifying
                          ? "arrow.triangle.2.circlepath"
                          : "checkmark.shield")
                        .font(.system(size: 11, weight: .bold))
                        .rotationEffect(.degrees(isVerifying ? 360 : 0))
                        .animation(isVerifying
                                   ? .linear(duration: 1).repeatForever(autoreverses: false)
                                   : .default, value: isVerifying)
                    Text("VERIFY CHAIN")
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
            .disabled(isVerifying)
        }
    }

    // MARK: - Verify result banner

    @ViewBuilder
    private func verifyResultBanner(_ r: AuditService.VerifyResult) -> some View {
        let color: Color = r.isValid ? .green : .red
        HStack(spacing: 12) {
            Image(systemName: r.isValid ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 18))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(r.isValid ? "CHAIN VERIFIED" : "CHAIN BROKEN")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2.5)
                    .foregroundStyle(color)
                Text(r.isValid
                     ? "All \(r.entryCount) entries hash-verify correctly."
                     : "First break at entry #\(r.firstBreakAt ?? 0). Someone or something modified the log.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.primaryText)
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(color.opacity(0.6), lineWidth: 1))
        .glassPanel(padding: 0)
    }

    // MARK: - Summary chips

    private var summaryChips: some View {
        let byType = Dictionary(grouping: entries, by: \.entityType)
            .mapValues(\.count)

        return HStack(spacing: 12) {
            chip(label: "ENTRIES", value: "\(entries.count)")
            ForEach(Array(byType.keys.sorted()), id: \.self) { type in
                chip(label: type.uppercased(), value: "\(byType[type] ?? 0)")
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

    // MARK: - Entries list

    private var entriesSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                AuditRow(entry: entry, isAlternate: index.isMultiple(of: 2))
                if index < entries.count - 1 {
                    Rectangle().fill(Theme.hairline.opacity(0.5)).frame(height: 1)
                }
            }
        }
        .glassPanel(padding: 0)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundStyle(Theme.accent.opacity(0.6))
            Text("NO AUDIT EVENTS YET")
                .font(.system(size: 12, weight: .semibold))
                .tracking(3)
                .foregroundStyle(Theme.primaryText)
            Text("Create a round, log a shot, or edit a course and it'll appear here.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.dim)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .glassPanel(padding: 32)
    }

    // MARK: - Actions

    private func verify() {
        isVerifying = true
        Task { @MainActor in
            // Slight pause so the animation is visible on fast chains.
            try? await Task.sleep(nanoseconds: 400_000_000)
            reload()                                  // refresh in case new events landed
            verifyResult = AuditService.shared.verify()
            isVerifying = false
        }
    }
}

// MARK: - Audit row

struct AuditRow: View {
    let entry: AuditEntry
    var isAlternate: Bool = false

    private var actionColor: Color {
        switch entry.action {
        case "insert":  return .green
        case "delete":  return .red
        case "archive": return Color(white: 0.7)
        case "restore": return Theme.accent
        default:        return Theme.accent
        }
    }

    private var entityIcon: String {
        switch entry.entityType {
        case "Round":           return "flag.fill"
        case "Shot":            return "figure.golf"
        case "Course":          return "map.fill"
        case "BagClub":         return "bag.fill"
        case "PracticeSession": return "figure.golf"
        default:                return "doc.fill"
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Action pill on the left
            Text(entry.action.uppercased())
                .font(.system(size: 8, weight: .bold))
                .tracking(1.8)
                .foregroundStyle(actionColor)
                .frame(width: 64)
                .padding(.vertical, 4)
                .overlay(RoundedRectangle(cornerRadius: 2)
                    .stroke(actionColor.opacity(0.5), lineWidth: 1))

            Image(systemName: entityIcon)
                .font(.system(size: 13))
                .foregroundStyle(Theme.accent)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.summary)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.primaryText)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text("#\(entry.sequence)")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(Theme.accent)
                    Text("·")
                        .foregroundStyle(Theme.dim)
                    Text(entry.entityType.uppercased())
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(Theme.dim)
                    if !entry.entityLabel.isEmpty {
                        Text("·")
                            .foregroundStyle(Theme.dim)
                        Text(entry.entityLabel)
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.dim)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.timestamp.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.primaryText)
                Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.dim)
                Text(entry.entryHash.prefix(10))
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(Theme.dimmer)
                    .padding(.top, 2)
                    .help("SHA-256: \(entry.entryHash)")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isAlternate ? Color.white.opacity(0.04) : Color.clear)
    }
}
