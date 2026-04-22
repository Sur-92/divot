import SwiftUI

enum Theme {
    /// Warm amber — primary accent, like circuit-board glow.
    static let accent = Color(red: 0.95, green: 0.58, blue: 0.18)
    static let accentDim = Color(red: 0.95, green: 0.58, blue: 0.18).opacity(0.35)

    /// Hairline borders and dividers.
    static let hairline = Color.white.opacity(0.12)
    static let hairlineStrong = Color.white.opacity(0.22)

    /// Muted text tiers on a dark background.
    static let primaryText = Color.white
    static let dim = Color.white.opacity(0.6)
    static let dimmer = Color.white.opacity(0.38)
}

// MARK: - Branded section header (uppercase + amber underline)

struct SectionLabel: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .tracking(3.5)
                .foregroundStyle(Theme.accent)
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.dim)
            }
            Rectangle()
                .fill(Theme.accent)
                .frame(width: 28, height: 1.5)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Glass panel modifier

struct GlassPanel: ViewModifier {
    var cornerRadius: CGFloat = 4
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.black.opacity(0.14))
                    .background(.ultraThinMaterial.opacity(0.50),
                                in: RoundedRectangle(cornerRadius: cornerRadius))
            }
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
    }
}

extension View {
    func glassPanel(cornerRadius: CGFloat = 4, padding: CGFloat = 16) -> some View {
        modifier(GlassPanel(cornerRadius: cornerRadius, padding: padding))
    }
}

// MARK: - Big-number stat card

struct StatCard: View {
    let label: String
    let value: String
    let sublabel: String?

    init(label: String, value: String, sublabel: String? = nil) {
        self.label = label
        self.value = value
        self.sublabel = sublabel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(2.5)
                .foregroundStyle(Theme.dim)

            Text(value)
                .font(.system(size: 44, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Theme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            HStack(spacing: 8) {
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: 20, height: 1.5)
                if let sublabel, !sublabel.isEmpty {
                    Text(sublabel.uppercased())
                        .font(.system(size: 9, weight: .medium))
                        .tracking(1.5)
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(padding: 18)
    }
}

// MARK: - Uppercase tracked label

struct TrackedLabel: View {
    let text: String
    var size: CGFloat = 11
    var tracking: CGFloat = 2.5
    var color: Color = Theme.dim

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: size, weight: .semibold))
            .tracking(tracking)
            .foregroundStyle(color)
    }
}
