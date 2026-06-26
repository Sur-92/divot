import SwiftUI
import SwiftData

/// Sidebar "Backup Data" button. The app is sandboxed and can't run git, so
/// tapping flushes pending edits and drops a `.backup-trigger` file in the
/// container's Documents. A user LaunchAgent watches that file, snapshots the
/// live DB into the private `app-data` repo, pushes, and writes back
/// `.backup-status` — which this view reads to show the result.
struct BackupButton: View {
    @Environment(\.modelContext) private var modelContext

    @State private var working = false
    @State private var message = ""
    @State private var isError = false
    @State private var pollTask: Task<Void, Never>?

    private var docs: URL? {
        try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
                                     appropriateFor: nil, create: false)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: backup) {
                HStack(spacing: 10) {
                    Image(systemName: working ? "arrow.triangle.2.circlepath" : "arrow.up.doc.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                    Text(working ? "BACKING UP…" : "BACKUP DATA")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(Theme.primaryText)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .contentShape(Rectangle())
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.05)))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.accent.opacity(0.4), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(working)
            .padding(.horizontal, 12)

            if !message.isEmpty {
                Text(message)
                    .font(.system(size: 9))
                    .foregroundStyle(isError ? Color(red: 0.92, green: 0.45, blue: 0.42) : Theme.dim)
                    .lineLimit(1)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 4)
        .onAppear { if let s = readStatus() { message = s.msg; isError = !s.ok } }
    }

    private func backup() {
        modelContext.saveOrReport()
        guard docs != nil else { message = "Backup unavailable"; isError = true; return }
        BackupTrigger.fire()

        working = true
        message = "Backing up…"
        isError = false
        let started = Date().timeIntervalSince1970 - 2  // small tolerance

        pollTask?.cancel()
        pollTask = Task {
            for _ in 0..<24 {                        // ~24 × 0.8s ≈ 19s
                try? await Task.sleep(nanoseconds: 800_000_000)
                if let s = readStatus(), s.epoch >= started {
                    await MainActor.run {
                        message = s.msg; isError = !s.ok; working = false
                    }
                    return
                }
            }
            await MainActor.run {
                working = false
                if message == "Backing up…" { message = "Still working — check back in a moment" }
            }
        }
    }

    private func readStatus() -> (epoch: Double, ok: Bool, msg: String)? {
        guard let docs else { return nil }
        let url = docs.appendingPathComponent(".backup-status")
        guard let raw = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let parts = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\t", maxSplits: 2, omittingEmptySubsequences: false)
            .map(String.init)
        guard parts.count >= 2, let epoch = Double(parts[0]) else { return nil }
        return (epoch, parts[1] == "ok", parts.count >= 3 ? parts[2] : "")
    }
}
