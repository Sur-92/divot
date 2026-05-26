import SwiftUI
import AppKit

/// Curated reading page — golf teachers and pros with actionable
/// "key teachings" pulled from their books and coaching legacies.
/// Read-only content; all data lives in Services/Advisors.swift.
struct AdvisorsView: View {
    private var advisors: [Advisor] {
        Advisors.order.compactMap { Advisors.byName[$0] }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            ScrollView {
                LazyVStack(spacing: 28) {
                    ForEach(Array(advisors.enumerated()), id: \.element.name) { _, advisor in
                        AdvisorCard(advisor: advisor)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                Text("ADVISORS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(4)
                    .foregroundStyle(Theme.accent)
                Text("Wisdom from the people who taught the game.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.dim)
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: 28, height: 1.5)
                    .padding(.top, 2)
            }
            Spacer()
            Text("\(advisors.count) ADVISORS")
                .font(.system(size: 9, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Theme.dim)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 14)
    }
}

// MARK: - Advisor card

struct AdvisorCard: View {
    let advisor: Advisor

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            headerRow
            Rectangle().fill(Theme.hairline).frame(height: 1)
            bioBlock
            teachingsBlock
            if !advisor.books.isEmpty {
                Rectangle().fill(Theme.hairline).frame(height: 1)
                booksBlock
            }
        }
        .padding(20)
        .background(
            ZStack {
                Color.black.opacity(0.42)
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.03),
                        Color.black.opacity(0.10)
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Theme.hairline, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    // MARK: - Header row (photo + name + tagline)

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 18) {
            GolferPhoto(name: advisor.name,
                        asset: advisor.photoAssetName,
                        size: 84)

            VStack(alignment: .leading, spacing: 6) {
                Text(advisor.name)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Theme.primaryText)

                Text(advisor.era)
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(Theme.dim)

                Text(advisor.tagline)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)

                HStack(spacing: 6) {
                    specialtyChip(advisor.specialty)
                    if let str = advisor.wikipediaURL, let url = URL(string: str) {
                        Link(destination: url) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.right.square")
                                    .font(.system(size: 9, weight: .semibold))
                                Text("WIKIPEDIA")
                                    .font(.system(size: 9, weight: .semibold))
                                    .tracking(1.5)
                            }
                            .foregroundStyle(Theme.dim)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 4)
            }
            Spacer()
        }
    }

    private func specialtyChip(_ specialty: Specialty) -> some View {
        Text(specialty.rawValue.uppercased())
            .font(.system(size: 9, weight: .bold))
            .tracking(1.8)
            .foregroundStyle(.black)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.accent)
            )
    }

    // MARK: - Bio block

    private var bioBlock: some View {
        Text(advisor.bio)
            .font(.system(size: 13))
            .foregroundStyle(Theme.primaryText.opacity(0.92))
            .fixedSize(horizontal: false, vertical: true)
            .lineSpacing(2)
    }

    // MARK: - Teachings block

    private var teachingsBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                Text("KEY TEACHINGS")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2.5)
                    .foregroundStyle(Theme.accent)
            }

            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(advisor.teachings.enumerated()), id: \.offset) { idx, teaching in
                    teachingRow(index: idx + 1, teaching: teaching)
                }
            }
        }
    }

    private func teachingRow(index: Int, teaching: Teaching) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Number badge
            Text(String(format: "%02d", index))
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.accent.opacity(0.85))
                .frame(width: 26, alignment: .leading)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 5) {
                Text(teaching.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.primaryText)
                Text(teaching.summary)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.primaryText.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
            }
        }
    }

    // MARK: - Books block

    private var booksBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.dim)
                Text("NOTABLE WORKS")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2.5)
                    .foregroundStyle(Theme.dim)
            }
            VStack(alignment: .leading, spacing: 3) {
                ForEach(advisor.books, id: \.self) { book in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("·")
                            .foregroundStyle(Theme.dim)
                        Text(book)
                            .font(.system(size: 12))
                            .italic()
                            .foregroundStyle(Theme.primaryText.opacity(0.78))
                    }
                }
            }
        }
    }
}

#Preview {
    AdvisorsView()
        .frame(width: 900, height: 700)
        .background(Color.black)
}
