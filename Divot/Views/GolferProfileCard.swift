import SwiftUI
import AppKit

/// Hover popover that introduces the person quoted at the bottom of the
/// Rounds screen — a respectful one-pager with photo, headline, and bio.
struct GolferProfileCard: View {
    let profile: GolferProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                GolferPhoto(name: profile.name, asset: profile.photoAssetName, size: 84)
                VStack(alignment: .leading, spacing: 5) {
                    Text(profile.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Theme.primaryText)
                    Text(profile.tagline)
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.6)
                        .foregroundStyle(Theme.accent)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Rectangle().fill(Theme.hairline).frame(height: 1)
            Text(profile.bio)
                .font(.system(size: 13))
                .foregroundStyle(Theme.primaryText.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
            if let str = profile.wikipediaURL, let url = URL(string: str) {
                Link(destination: url) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right.square")
                        Text("WIKIPEDIA")
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(width: 360)
    }
}

/// Circular photo. Tries the asset catalog first, then a drop-in file at
/// <container>/Documents/GolferPhotos/<asset>.{jpg,jpeg,png}, finally falling
/// back to an initials placeholder. Keeps photos out of the public repo.
struct GolferPhoto: View {
    let name: String
    let asset: String
    var size: CGFloat = 80

    private var image: NSImage? {
        if let img = NSImage(named: asset) { return img }
        if let docs = try? FileManager.default.url(for: .documentDirectory,
                                                   in: .userDomainMask,
                                                   appropriateFor: nil,
                                                   create: false) {
            for ext in ["jpg", "jpeg", "png"] {
                let url = docs.appendingPathComponent("GolferPhotos/\(asset).\(ext)")
                if let img = NSImage(contentsOf: url) { return img }
            }
        }
        return nil
    }

    private var initials: String {
        name.split(separator: " ")
            .compactMap { $0.first.map(String.init) }
            .prefix(2)
            .joined()
    }

    var body: some View {
        Group {
            if let img = image {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        Text(initials)
                            .font(.system(size: size * 0.36, weight: .bold))
                            .foregroundStyle(Theme.accent)
                    )
                    .frame(width: size, height: size)
            }
        }
        .overlay(Circle().stroke(Theme.hairline, lineWidth: 1))
    }
}

/// Quote-byline author chip with a hover popover that shows the person's
/// profile. Closes when the user clicks elsewhere.
struct AuthorChip: View {
    let author: String

    @State private var hovering = false
    @State private var showProfile = false

    private var profile: GolferProfile? { GolferProfiles.byName[author] }

    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Theme.accent)
                .frame(width: 18, height: 1.5)
            Text(author.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(2.5)
                .foregroundStyle(Theme.accent)
                .underline(hovering && profile != nil, color: Theme.accent)
        }
        .contentShape(Rectangle())
        .onHover { h in
            hovering = h
            if h, profile != nil { showProfile = true }
        }
        .popover(isPresented: $showProfile, arrowEdge: .top) {
            if let profile { GolferProfileCard(profile: profile) }
        }
        .help(profile == nil ? "" : "Hover for biography")
    }
}
