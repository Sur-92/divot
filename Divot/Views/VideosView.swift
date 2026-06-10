import SwiftUI
import SwiftData
import AppKit

/// Saved YouTube (or any) video links — coaching clips, swing thoughts,
/// course-management lessons, etc. Stored locally; clicking PLAY hands
/// the URL off to the system browser via NSWorkspace.
struct VideosView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\VideoBookmark.addedAt)]) private var bookmarks: [VideoBookmark]

    @State private var editing: VideoBookmark?

    private var sortedBookmarks: [VideoBookmark] {
        bookmarks.sorted { a, b in
            if a.sortOrder != b.sortOrder { return a.sortOrder < b.sortOrder }
            return a.addedAt > b.addedAt
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                if bookmarks.isEmpty {
                    emptyState
                } else {
                    videoTable
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .onAppear { backfillSortOrderIfNeeded() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                Text("VIDEOS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(4)
                    .foregroundStyle(Theme.accent)
                Text("Coaching clips and swing thoughts. Tap PLAY to open in your browser.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.dim)
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: 28, height: 1.5)
                    .padding(.top, 2)
            }
            Spacer()
            Button(action: addVideo) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("ADD VIDEO")
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

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "play.rectangle")
                .font(.system(size: 38, weight: .ultraLight))
                .foregroundStyle(Theme.accent.opacity(0.6))
            Text("NO VIDEOS SAVED")
                .font(.system(size: 12, weight: .semibold))
                .tracking(3)
                .foregroundStyle(Theme.primaryText)
            Text("Tap ADD VIDEO to bookmark a YouTube clip.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.dim)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .glassPanel(padding: 32)
    }

    // MARK: - Table

    private var videoTable: some View {
        let list = sortedBookmarks
        return VStack(spacing: 0) {
            ForEach(Array(list.enumerated()), id: \.element.id) { index, video in
                VideoRow(
                    video: video,
                    isAlternate: index.isMultiple(of: 2),
                    onPlay:  { open(video) },
                    onEdit:  { editing = video },
                    onMoveUp:   index > 0 ? { move(video, direction: -1) } : nil,
                    onMoveDown: index < list.count - 1 ? { move(video, direction: 1) } : nil,
                    onDelete: { delete(video) }
                )
                if index < list.count - 1 {
                    Rectangle().fill(Theme.hairline.opacity(0.5)).frame(height: 1)
                }
            }
        }
        .glassPanel(padding: 0)
        .sheet(item: $editing) { video in
            VideoEditSheet(video: video) {
                modelContext.saveOrReport()
            }
        }
    }

    // MARK: - Actions

    private func addVideo() {
        let maxOrder = bookmarks.map(\.sortOrder).max() ?? 0
        let video = VideoBookmark(sortOrder: maxOrder + 1)
        modelContext.insert(video)
        modelContext.saveOrReport()

        AuditService.shared.log(
            entityType: "VideoBookmark",
            entityID: video.idempotencyKey,
            entityLabel: "New video",
            action: "insert",
            summary: "Added a new video bookmark"
        )
        editing = video
    }

    private func open(_ video: VideoBookmark) {
        guard let url = URL(string: video.url) else { return }
        NSWorkspace.shared.open(url)
    }

    private func delete(_ video: VideoBookmark) {
        let label = video.displayTitle
        let id = video.idempotencyKey
        modelContext.delete(video)
        modelContext.saveOrReport()

        AuditService.shared.log(
            entityType: "VideoBookmark",
            entityID: id,
            entityLabel: label,
            action: "delete",
            summary: "Deleted video \(label)"
        )
    }

    private func move(_ video: VideoBookmark, direction: Int) {
        let ordered = sortedBookmarks
        guard let idx = ordered.firstIndex(where: { $0.id == video.id }) else { return }
        let neighbourIdx = idx + direction
        guard ordered.indices.contains(neighbourIdx) else { return }
        let neighbour = ordered[neighbourIdx]
        let tmp = video.sortOrder
        video.sortOrder = neighbour.sortOrder
        neighbour.sortOrder = tmp
        modelContext.saveOrReport()
    }

    /// If every bookmark has sortOrder 0, number them by addedAt newest-first.
    private func backfillSortOrderIfNeeded() {
        guard !bookmarks.isEmpty,
              bookmarks.allSatisfy({ $0.sortOrder == 0 }) else { return }
        let ordered = bookmarks.sorted { $0.addedAt > $1.addedAt }
        for (index, v) in ordered.enumerated() {
            v.sortOrder = index + 1
        }
        modelContext.saveOrReport()
    }
}

// MARK: - Row

struct VideoRow: View {
    let video: VideoBookmark
    var isAlternate: Bool = false
    var onPlay: () -> Void
    var onEdit: () -> Void
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?
    var onDelete: () -> Void

    @State private var showDeleteConfirm = false
    @State private var hovering = false

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // YouTube/play badge
            playBadge

            // Title + URL + notes
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(video.displayTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(1)
                    if !video.tag.isEmpty {
                        tagChip(video.tag)
                    }
                }
                Text(video.url.isEmpty ? "no url set" : video.url)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(video.url.isEmpty ? Theme.dimmer : Theme.dim)
                    .lineLimit(1)
                if !video.notes.isEmpty {
                    Text(video.notes)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.dim)
                        .lineLimit(2)
                }
            }
            Spacer()

            // Reorder buttons
            VStack(spacing: 2) {
                orderButton(icon: "chevron.up", action: onMoveUp, help: "Move up")
                orderButton(icon: "chevron.down", action: onMoveDown, help: "Move down")
            }

            // Play
            Button(action: onPlay) {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 9, weight: .bold))
                    Text("PLAY")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.5)
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 3).fill(Theme.accent))
            }
            .buttonStyle(.plain)
            .disabled(URL(string: video.url) == nil || video.url.isEmpty)
            .opacity(video.url.isEmpty ? 0.4 : 1)
            .help(video.url)

            // Edit
            Button(action: onEdit) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 30, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Edit details")

            // Delete with confirm
            Button { showDeleteConfirm = true } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.red.opacity(0.7))
                    .frame(width: 30, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Delete")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isAlternate ? Color.white.opacity(0.04) : Color.clear)
        .onHover { hovering = $0 }
        .alert("Delete this video bookmark?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("\"\(video.displayTitle)\" will be removed.")
        }
    }

    /// Small play/YouTube indicator. Shows "YT" when the URL parses as a
    /// YouTube link, otherwise a generic play icon.
    private var playBadge: some View {
        Group {
            if let id = video.youtubeID {
                VStack(spacing: 1) {
                    Text("YT")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(.white)
                    Text(id.prefix(6))
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .frame(width: 44, height: 30)
                .background(RoundedRectangle(cornerRadius: 3)
                    .fill(Color(red: 0.78, green: 0.10, blue: 0.10)))
            } else {
                Image(systemName: "play.rectangle")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 44, height: 30)
                    .background(RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.06)))
            }
        }
    }

    private func tagChip(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 8, weight: .semibold))
            .tracking(1.5)
            .foregroundStyle(Theme.accent.opacity(0.9))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .overlay(RoundedRectangle(cornerRadius: 2)
                .stroke(Theme.accent.opacity(0.45), lineWidth: 1))
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
}

// MARK: - Edit sheet

struct VideoEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var video: VideoBookmark
    var onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("VIDEO BOOKMARK")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(3)
                        .foregroundStyle(Theme.accent)
                    Text("Save a clip you want kept handy.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.dim)
                }
                Spacer()
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

            Rectangle().fill(Theme.accent).frame(width: 28, height: 1.5)

            field(label: "TITLE", text: $video.title,
                  prompt: "e.g. Adam Scott driver swing breakdown")
            field(label: "URL", text: $video.url,
                  prompt: "https://youtube.com/watch?v=…",
                  monospaced: true)
            field(label: "TAG", text: $video.tag,
                  prompt: "e.g. Driving, Putting, Course management")

            VStack(alignment: .leading, spacing: 6) {
                Text("NOTES")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Theme.dim)
                TextEditor(text: $video.notes)
                    .font(.system(size: 12))
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(Theme.primaryText)
                    .frame(minHeight: 90)
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
                        .background(RoundedRectangle(cornerRadius: 3).fill(Theme.accent))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(28)
        .frame(minWidth: 480, idealWidth: 540)
        .background(
            ZStack {
                Color.black.opacity(0.92)
                LinearGradient(
                    colors: [.black.opacity(0.7), .black.opacity(0.95)],
                    startPoint: .top, endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        )
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
    }
}
