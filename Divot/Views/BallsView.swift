import SwiftUI

/// Comparison matrix of golf balls — top section is a tight,
/// scannable head-to-head; bottom section expands each ball into a
/// detail card with the longer take. Read-only static content;
/// data lives in Services/Balls.swift.
struct BallsView: View {
    private var balls: [Ball] { Balls.all }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    matrixSection
                    Rectangle().fill(Theme.hairline).frame(height: 1)
                    detailsSection
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
                Text("BALLS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(4)
                    .foregroundStyle(Theme.accent)
                Text("Comparison matrix · matched to this player's profile.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.dim)
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: 28, height: 1.5)
                    .padding(.top, 2)
            }
            Spacer()
            Text("\(balls.count) BALLS")
                .font(.system(size: 9, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Theme.dim)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 14)
    }

    // MARK: - Matrix

    private var matrixSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel("Matrix", subtitle: "Head-to-head on price, build, and feel")

            VStack(spacing: 0) {
                matrixHeaderRow
                Rectangle().fill(Theme.hairline.opacity(0.6)).frame(height: 1)
                ForEach(Array(balls.enumerated()), id: \.offset) { idx, ball in
                    matrixRow(ball: ball, isAlternate: idx.isMultiple(of: 2))
                    if idx < balls.count - 1 {
                        Rectangle().fill(Theme.hairline.opacity(0.4)).frame(height: 1)
                    }
                }
            }
            .background(Color.black.opacity(0.35))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.hairline, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }

    // Column widths balance an 1100px window. Ball-name column flexes.
    private let widthPrice: CGFloat = 56
    private let widthPieces: CGFloat = 50
    private let widthCover: CGFloat = 80
    private let widthComp: CGFloat = 60
    private let widthSpin: CGFloat = 60
    private let widthFeel: CGFloat = 64
    private let widthFit: CGFloat = 90

    private var matrixHeaderRow: some View {
        HStack(spacing: 8) {
            Text("BALL")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("$/DZ")
                .frame(width: widthPrice, alignment: .trailing)
            Text("BUILD")
                .frame(width: widthPieces, alignment: .center)
            Text("COVER")
                .frame(width: widthCover, alignment: .leading)
            Text("COMP")
                .frame(width: widthComp, alignment: .center)
            Text("DRIVER")
                .frame(width: widthSpin, alignment: .center)
            Text("GREEN")
                .frame(width: widthSpin, alignment: .center)
            Text("FEEL")
                .frame(width: widthFeel, alignment: .center)
            Text("FIT")
                .frame(width: widthFit, alignment: .center)
        }
        .font(.system(size: 9, weight: .bold))
        .tracking(1.8)
        .foregroundStyle(Theme.accent)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func matrixRow(ball: Ball, isAlternate: Bool) -> some View {
        HStack(spacing: 8) {
            // Ball name (brand + model) — flex column
            VStack(alignment: .leading, spacing: 1) {
                Text(ball.brand.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(Theme.dim)
                Text(ball.model)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.primaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Price
            Text("$\(ball.pricePerDozen)")
                .font(.system(size: 13, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Theme.primaryText)
                .frame(width: widthPrice, alignment: .trailing)

            // Build / pieces
            Text("\(ball.pieces)pc")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.dim)
                .frame(width: widthPieces, alignment: .center)

            // Cover
            Text(ball.cover.rawValue)
                .font(.system(size: 11))
                .foregroundStyle(Theme.dim)
                .frame(width: widthCover, alignment: .leading)

            // Compression
            Text("\(ball.compression)")
                .font(.system(size: 12, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(Theme.primaryText)
                .frame(width: widthComp, alignment: .center)

            // Driver spin tier
            spinChip(ball.driverSpin)
                .frame(width: widthSpin)

            // Greenside spin tier
            spinChip(ball.greensideSpin)
                .frame(width: widthSpin)

            // Feel
            feelChip(ball.feel)
                .frame(width: widthFeel)

            // Fit status
            fitBadge(ball.fit)
                .frame(width: widthFit)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(isAlternate ? Color.white.opacity(0.02) : Color.clear)
    }

    private func spinChip(_ tier: SpinTier) -> some View {
        Text(tier.rawValue.uppercased())
            .font(.system(size: 9, weight: .bold))
            .tracking(1.5)
            .foregroundStyle(spinColor(tier))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .overlay(RoundedRectangle(cornerRadius: 2)
                .stroke(spinColor(tier).opacity(0.5), lineWidth: 1))
    }

    private func spinColor(_ tier: SpinTier) -> Color {
        switch tier {
        case .low:  return Theme.dim
        case .mid:  return Theme.primaryText
        case .high: return Theme.accent
        }
    }

    private func feelChip(_ feel: FeelTier) -> some View {
        Text(feel.rawValue.uppercased())
            .font(.system(size: 9, weight: .bold))
            .tracking(1.5)
            .foregroundStyle(Theme.primaryText)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .overlay(RoundedRectangle(cornerRadius: 2)
                .stroke(Theme.hairline, lineWidth: 1))
    }

    @ViewBuilder
    private func fitBadge(_ fit: FitStatus) -> some View {
        switch fit {
        case .gamer:
            Text(fit.rawValue)
                .font(.system(size: 9, weight: .bold))
                .tracking(1.8)
                .foregroundStyle(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 2).fill(Theme.accent))
        case .benchmark:
            Text(fit.rawValue)
                .font(.system(size: 9, weight: .bold))
                .tracking(1.8)
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(Theme.accent, lineWidth: 1))
        case .alt:
            Text(fit.rawValue)
                .font(.system(size: 9, weight: .bold))
                .tracking(1.8)
                .foregroundStyle(Theme.dim)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(Theme.hairline, lineWidth: 1))
        case .sleeper:
            Text(fit.rawValue)
                .font(.system(size: 9, weight: .bold))
                .tracking(1.8)
                .foregroundStyle(Theme.dim)
                .italic()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(Theme.dim.opacity(0.5), lineWidth: 1))
        case .avoid:
            Text(fit.rawValue)
                .font(.system(size: 9, weight: .bold))
                .tracking(1.8)
                .foregroundStyle(Color.red.opacity(0.75))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.red.opacity(0.5), lineWidth: 1))
        }
    }

    // MARK: - Details

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel("Detail", subtitle: "Why each ball lands where it does")
            VStack(spacing: 14) {
                ForEach(Array(balls.enumerated()), id: \.offset) { _, ball in
                    detailCard(ball: ball)
                }
            }
        }
    }

    private func detailCard(ball: Ball) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(ball.brand.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Theme.dim)
                Text(ball.model)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                fitBadge(ball.fit)
            }

            HStack(spacing: 6) {
                Image(systemName: "person.fill")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.accent.opacity(0.8))
                Text("BEST FOR")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.8)
                    .foregroundStyle(Theme.accent.opacity(0.8))
                Text(ball.bestFor)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.primaryText.opacity(0.85))
            }

            Text(ball.take)
                .font(.system(size: 13))
                .foregroundStyle(Theme.primaryText.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
        .padding(16)
        .background(Color.black.opacity(0.35))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.hairline, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

#Preview {
    BallsView()
        .frame(width: 1100, height: 700)
        .background(Color.black)
}
