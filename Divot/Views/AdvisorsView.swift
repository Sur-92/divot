import SwiftUI
import AppKit

/// The player's personal playbook — ONLY the teachings they've adopted
/// (see `Advisors.playbook`). A lean format: advisor name + their selected
/// lessons, no bios / books / eras. The full roster still lives in
/// Services/Advisors.swift, so selections can be revised any time.
struct AdvisorsView: View {
    private var advisors: [Advisor] { Advisors.playbookAdvisors }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(advisors, id: \.name) { advisor in
                        PlaybookCard(advisor: advisor,
                                     teachings: Advisors.selectedTeachings(for: advisor))
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
                Text("Your playbook — the teachings you've taken to heart.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.dim)
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: 28, height: 1.5)
                    .padding(.top, 2)
            }
            Spacer()
            Text("\(Advisors.playbookCount) TEACHINGS · \(advisors.count) VOICES")
                .font(.system(size: 9, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Theme.dim)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 14)
    }
}

// MARK: - Playbook card (one advisor, only their selected teachings)

private struct PlaybookCard: View {
    let advisor: Advisor
    let teachings: [Teaching]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Slim advisor header — photo + name + specialty only.
            HStack(spacing: 12) {
                GolferPhoto(name: advisor.name,
                            asset: advisor.photoAssetName,
                            size: 44)
                VStack(alignment: .leading, spacing: 3) {
                    Text(advisor.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.primaryText)
                    Text(advisor.specialty.rawValue.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.8)
                        .foregroundStyle(Theme.accent)
                }
                Spacer()
            }

            Rectangle().fill(Theme.hairline).frame(height: 1)

            // Selected teachings.
            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(teachings.enumerated()), id: \.offset) { _, t in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.accent)
                            .padding(.top, 1)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(t.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.primaryText)
                            Text(t.summary)
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.primaryText.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(3)
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(
            ZStack {
                Color.black.opacity(0.42)
                LinearGradient(
                    colors: [Color.white.opacity(0.03), Color.black.opacity(0.10)],
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
}

#Preview {
    AdvisorsView()
        .frame(width: 900, height: 700)
        .background(Color.black)
}
