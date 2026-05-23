import SwiftUI

/// Tap-to-plot tee-shot landing diagram. Bands run left→right —
/// rough / fringe / fairway / fringe / rough — and depth runs near→far
/// (short ↔ long). Tapping (or dragging) records the marker as the hole's
/// normalized driveX/driveY and updates fairwayHit on par-4/5 holes.
struct DriveLanding: View {
    @Bindable var hole: Hole
    var height: CGFloat = 260

    private let roughColor   = Color(red: 0.15, green: 0.33, blue: 0.17)
    private let fringeColor  = Color(red: 0.24, green: 0.47, blue: 0.24)
    private let fairwayColor = Color(red: 0.33, green: 0.62, blue: 0.30)

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .topLeading) {
                bands(w: w)
                guides(w: w, h: h)
                if hole.hasDrive {
                    marker.position(x: hole.driveX * w, y: (1 - hole.driveY) * h)
                }
            }
            .frame(width: w, height: h)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.hairline, lineWidth: 1))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in plot(at: v.location, w: w, h: h) }
            )
        }
        .frame(height: height)
    }

    private func bands(w: CGFloat) -> some View {
        HStack(spacing: 0) {
            roughColor.frame(width: w * 0.18)
            fringeColor.frame(width: w * 0.12)
            fairwayColor.frame(width: w * 0.40)
            fringeColor.frame(width: w * 0.12)
            roughColor.frame(width: w * 0.18)
        }
    }

    private func guides(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            Rectangle().fill(.white.opacity(0.16))
                .frame(width: w, height: 1)
                .position(x: w / 2, y: h * 0.5)
            VStack {
                Text("LONG").font(.system(size: 8, weight: .semibold)).tracking(2)
                    .foregroundStyle(.white.opacity(0.5)).padding(.top, 5)
                Spacer()
                Text("SHORT").font(.system(size: 8, weight: .semibold)).tracking(2)
                    .foregroundStyle(.white.opacity(0.5)).padding(.bottom, 5)
            }
            .frame(width: w, height: h)
        }
        .frame(width: w, height: h)
    }

    private var marker: some View {
        ZStack {
            Circle().fill(Theme.accent).frame(width: 15, height: 15)
            Circle().stroke(.white, lineWidth: 1.5).frame(width: 15, height: 15)
        }
        .shadow(color: .black.opacity(0.4), radius: 2)
    }

    private func plot(at p: CGPoint, w: CGFloat, h: CGFloat) {
        guard w > 0, h > 0 else { return }
        hole.driveX = min(1, max(0, p.x / w))
        hole.driveY = min(1, max(0, 1 - p.y / h))
        hole.hasDrive = true
        if hole.par >= 4 { hole.fairwayHit = hole.driveInFairway }
    }
}

/// Compact, read-only drive indicator for the scorecard column.
struct DriveGlyph: View {
    let hole: Hole

    var body: some View {
        if hole.hasDrive {
            Text(hole.driveZoneLabel)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        } else {
            Text("—")
                .font(.system(size: 11))
                .foregroundStyle(Theme.dimmer)
        }
    }

    private var color: Color {
        if hole.driveInFairway { return Color(red: 0.55, green: 0.88, blue: 0.60) }  // green
        if hole.driveInRough   { return Color(red: 0.92, green: 0.35, blue: 0.32) }  // red
        return Color(red: 0.95, green: 0.88, blue: 0.40)                             // fringe → yellow
    }
}
