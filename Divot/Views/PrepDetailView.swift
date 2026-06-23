import SwiftUI

/// Shows a generated pre-round prep: the three advisories, with the context
/// brief tucked behind a disclosure for transparency.
struct PrepDetailView: View {
    let prep: PrepPlan
    @State private var showBrief = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                VStack(spacing: 14) {
                    ForEach(Array(prep.advisories.enumerated()), id: \.offset) { i, a in
                        advisoryCard(index: i + 1, advisory: a)
                    }
                }

                if prep.advisories.isEmpty {
                    Text("No advisories were saved for this prep.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.dim)
                }

                briefDisclosure
            }
            .padding(24)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PRE-ROUND PREP")
                .font(.system(size: 11, weight: .semibold))
                .tracking(4)
                .foregroundStyle(Theme.accent)
            Text(prep.courseName)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Theme.primaryText)
            HStack(spacing: 8) {
                Text(prep.date.formatted(.dateTime.month(.wide).day().year()))
                if !prep.modelUsed.isEmpty {
                    Text("·").foregroundStyle(Theme.dimmer)
                    Text(prep.modelUsed)
                }
            }
            .font(.system(size: 12))
            .foregroundStyle(Theme.dim)
            Rectangle().fill(Theme.accent).frame(width: 28, height: 1.5).padding(.top, 2)
        }
    }

    // MARK: - Advisory card

    private func advisoryCard(index: Int, advisory: PrepAdvisory) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(index)")
                .font(.system(size: 16, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(.black)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Theme.accent))

            VStack(alignment: .leading, spacing: 6) {
                Text(advisory.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.primaryText)
                Text(advisory.detail)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.primaryText.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.30))
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.hairline, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    // MARK: - Brief disclosure

    private var briefDisclosure: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeOut(duration: 0.15)) { showBrief.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: showBrief ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                    Text("DATA USED FOR THIS PREP")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(2)
                }
                .foregroundStyle(Theme.dim)
            }
            .buttonStyle(.plain)

            if showBrief {
                Text(prep.brief)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Theme.dim)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.25))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.hairline, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(.top, 8)
    }
}
