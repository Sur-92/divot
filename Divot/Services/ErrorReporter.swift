import SwiftUI
import SwiftData

/// App-wide error surfacing. Failures that used to be swallowed by
/// `modelContext.saveOrReport()` now post here: the message is logged to the
/// system console (diagnosable in Console.app) AND shown to the user as a
/// transient banner at the app root, so a failed save is never invisible.
@Observable
@MainActor
final class ErrorReporter {
    static let shared = ErrorReporter()
    private init() {}

    private(set) var message: String?
    private var dismissTask: Task<Void, Never>?

    func report(_ message: String) {
        self.message = message
        dismissTask?.cancel()
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(7))
            if !Task.isCancelled { self?.message = nil }
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        message = nil
    }
}

extension ModelContext {
    /// Save, surfacing any failure instead of silently discarding it like
    /// `try? save()` did. Always logs to the console; also raises a user
    /// banner. Safe to call from any context — the banner update hops to
    /// the main actor.
    func saveOrReport(_ context: @autoclosure () -> String = "") {
        let hadChanges = hasChanges
        do {
            try save()
            // A real persisted change means this session is worth backing up
            // when the app quits.
            if hadChanges { BackupTrigger.dataChangedThisSession = true }
        } catch {
            let ctx = context()
            NSLog("Divot save failed [\(ctx)]: \(error)")
            let detail = ctx.isEmpty ? "" : " while \(ctx)"
            Task { @MainActor in
                ErrorReporter.shared.report("Couldn't save\(detail). Your last change may not be kept.")
            }
        }
    }
}

/// Transient banner shown at the app root when `ErrorReporter` has a message.
/// Amber-bordered, tap to dismiss, auto-clears after a few seconds.
struct ErrorBanner: View {
    @State private var reporter = ErrorReporter.shared

    var body: some View {
        ZStack {
            if let message = reporter.message {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                    Text(message)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Button {
                        reporter.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.dim)
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.9))
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.accent.opacity(0.7), lineWidth: 1))
                )
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .frame(maxWidth: 560)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.25), value: reporter.message)
    }
}
