import Foundation
import SwiftData

/// A saved video link the user wants kept handy — typically YouTube
/// instructional content (driving, putting, course management, etc.),
/// but any URL is accepted. Stored locally; nothing is fetched from
/// the network at save time.
@Model
final class VideoBookmark {
    var title: String
    var url: String
    var notes: String
    /// Freeform category tag — e.g. "Driving", "Putting", "Short Game".
    var tag: String
    var addedAt: Date

    /// User-controlled display order. 0 means "unassigned" (gets backfilled
    /// on first VideosView load). Lower = higher in list.
    var sortOrder: Int = 0

    /// Stable identity for this row — generated on insert, never changes.
    var idempotencyKey: String = ""

    init(title: String = "",
         url: String = "",
         notes: String = "",
         tag: String = "",
         addedAt: Date = .now,
         sortOrder: Int = 0) {
        self.title = title
        self.url = url
        self.notes = notes
        self.tag = tag
        self.addedAt = addedAt
        self.sortOrder = sortOrder
        self.idempotencyKey = UUID().uuidString
    }

    /// Best display name — falls back to URL host if no title set yet.
    var displayTitle: String {
        if !title.isEmpty { return title }
        if let host = URL(string: url)?.host { return host }
        return "Untitled video"
    }

    /// Returns a YouTube video ID if the URL is a recognizable YouTube link
    /// (youtube.com/watch?v=…, youtu.be/…, youtube.com/shorts/…).
    /// Used purely for showing a small "YT · ID" badge — no network calls.
    var youtubeID: String? {
        guard let parsed = URL(string: url),
              let host = parsed.host?.lowercased() else { return nil }

        if host.contains("youtu.be") {
            // https://youtu.be/<id>
            let id = parsed.lastPathComponent
            return id.isEmpty ? nil : id
        }
        if host.contains("youtube.com") {
            // /watch?v=<id>
            if let comps = URLComponents(url: parsed, resolvingAgainstBaseURL: false),
               let v = comps.queryItems?.first(where: { $0.name == "v" })?.value,
               !v.isEmpty {
                return v
            }
            // /shorts/<id> or /embed/<id>
            let parts = parsed.path.split(separator: "/")
            if parts.count >= 2,
               (parts[0] == "shorts" || parts[0] == "embed") {
                return String(parts[1])
            }
        }
        return nil
    }
}
