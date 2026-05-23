import SwiftUI
import SwiftData
import MapKit
import CoreLocation

/// Per-hole satellite drive plot. Mark the hole's tee (and optional green)
/// once — those persist on the course (`CourseHole`) and frame the hole on
/// every round. In "Plot Drive" mode, tap where the ball finished; the
/// landing is stored on this round's `Hole` and the tee→ball distance is
/// measured live. Imagery is live Apple Maps satellite — no course art.
struct DriveMapView: View {
    @Bindable var hole: Hole
    @Environment(\.modelContext) private var modelContext

    enum Mode: String, CaseIterable {
        case drive = "PLOT DRIVE"
        case tee   = "SET TEE"
        case green = "SET GREEN"
    }

    @State private var mode: Mode = .drive
    @State private var camera: MapCameraPosition = .automatic
    @State private var didFrame = false

    /// The course-level hole — tee/green live here so they're reused every round.
    private var courseHole: CourseHole? {
        guard let course = hole.round?.course else { return nil }
        return course.holes.first { $0.number == hole.number }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            modeBar
            mapPanel
            infoBar
        }
        .onAppear { frameInitial() }
    }

    // MARK: - Mode bar

    private var modeBar: some View {
        HStack(spacing: 8) {
            ForEach(Mode.allCases, id: \.self) { m in
                let enabled = (m == .drive) || (courseHole != nil)
                Button { mode = m } label: {
                    Text(m.rawValue)
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(mode == m ? .black : Theme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(mode == m ? Theme.accent : Color.clear)
                        .overlay(RoundedRectangle(cornerRadius: 3)
                            .stroke(Theme.accent.opacity(0.6), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(!enabled)
                .opacity(enabled ? 1 : 0.35)
            }
            Spacer()
            if hole.hasDrive {
                Button {
                    hole.hasDrive = false
                    hole.driveLat = 0
                    hole.driveLng = 0
                    try? modelContext.save()
                } label: {
                    Text("CLEAR DRIVE")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(Theme.dim)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Theme.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Map

    private var mapPanel: some View {
        MapReader { proxy in
            Map(position: $camera) {
                if let ch = courseHole, ch.hasTee {
                    Annotation("Tee", coordinate: ch.teeCoordinate, anchor: .bottom) {
                        pin(symbol: "flag.fill", color: .white, label: "TEE")
                    }
                }
                if let ch = courseHole, ch.hasGreen {
                    Annotation("Green", coordinate: ch.greenCoordinate, anchor: .bottom) {
                        pin(symbol: "circle.circle.fill",
                            color: Color(red: 0.40, green: 0.85, blue: 0.45), label: "GREEN")
                    }
                }
                if let d = hole.driveCoordinate {
                    Annotation("Drive", coordinate: d, anchor: .bottom) {
                        pin(symbol: "smallcircle.filled.circle", color: Theme.accent, label: "BALL")
                    }
                }
                if let ch = courseHole, ch.hasTee, let d = hole.driveCoordinate {
                    MapPolyline(coordinates: [ch.teeCoordinate, d])
                        .stroke(Theme.accent, lineWidth: 3)
                }
            }
            .mapStyle(.imagery(elevation: .realistic))
            .contentShape(Rectangle())
            .simultaneousGesture(
                SpatialTapGesture(count: 1, coordinateSpace: .local)
                    .onEnded { value in
                        if let coord = proxy.convert(value.location, from: .local) {
                            place(coord)
                        }
                    }
            )
        }
        .frame(height: 320)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.hairline, lineWidth: 1))
    }

    private func pin(symbol: String, color: Color, label: String) -> some View {
        VStack(spacing: 1) {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(color)
                    .shadow(color: .black.opacity(0.6), radius: 2)
                Text(label)
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 2).fill(.black.opacity(0.7)))
            }
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(color)
        }
    }

    // MARK: - Info bar

    private var infoBar: some View {
        HStack(spacing: 18) {
            metric("DRIVE", driveYards.map { "\($0) yd" } ?? "—")
            metric("TO GREEN", toGreenYards.map { "\($0) yd" } ?? "—")
            Spacer()
            Text(hint)
                .font(.system(size: 9))
                .foregroundStyle(Theme.dim)
                .lineLimit(1)
        }
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .tracking(1.8)
                .foregroundStyle(Theme.dim)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.primaryText)
        }
    }

    private var hint: String {
        if courseHole == nil { return "Link this round to a course to mark the tee & green." }
        switch mode {
        case .tee:   return "Tap the tee box to set it (saved to the course)."
        case .green: return "Tap the green to set it (saved to the course)."
        case .drive: return courseHole?.hasTee == true
            ? "Tap where your drive finished."
            : "Set the tee first to measure drive distance."
        }
    }

    // MARK: - Actions

    private func place(_ coord: CLLocationCoordinate2D) {
        switch mode {
        case .drive:
            hole.driveLat = coord.latitude
            hole.driveLng = coord.longitude
            hole.hasDrive = true
        case .tee:
            courseHole?.teeLatitude = coord.latitude
            courseHole?.teeLongitude = coord.longitude
            mode = .drive
        case .green:
            courseHole?.greenLatitude = coord.latitude
            courseHole?.greenLongitude = coord.longitude
            mode = .drive
        }
        try? modelContext.save()
    }

    // MARK: - Distances

    private var driveYards: Int? {
        guard hole.hasDrive, let ch = courseHole, ch.hasTee else { return nil }
        let a = CLLocation(latitude: ch.teeLatitude, longitude: ch.teeLongitude)
        let b = CLLocation(latitude: hole.driveLat, longitude: hole.driveLng)
        return Int((a.distance(from: b) * 1.0936133).rounded())
    }

    private var toGreenYards: Int? {
        guard hole.hasDrive, let ch = courseHole, ch.hasGreen else { return nil }
        let a = CLLocation(latitude: hole.driveLat, longitude: hole.driveLng)
        let b = CLLocation(latitude: ch.greenLatitude, longitude: ch.greenLongitude)
        return Int((a.distance(from: b) * 1.0936133).rounded())
    }

    // MARK: - Camera framing

    private func frameInitial() {
        guard !didFrame else { return }
        didFrame = true

        if let ch = courseHole, ch.hasTee {
            let tee = ch.teeCoordinate
            if ch.hasGreen {
                let green = ch.greenCoordinate
                let center = CLLocationCoordinate2D(
                    latitude: (tee.latitude + green.latitude) / 2,
                    longitude: (tee.longitude + green.longitude) / 2)
                let pad = 1.6
                let span = MKCoordinateSpan(
                    latitudeDelta: max(abs(tee.latitude - green.latitude) * pad, 0.003),
                    longitudeDelta: max(abs(tee.longitude - green.longitude) * pad, 0.003))
                camera = .region(MKCoordinateRegion(center: center, span: span))
            } else {
                camera = .region(MKCoordinateRegion(center: tee,
                    span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)))
            }
            return
        }

        guard let course = hole.round?.course else { return }
        if let c = course.coordinate {
            camera = .region(MKCoordinateRegion(center: c,
                span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)))
        } else if !course.address.isEmpty {
            geocode(course)
        }
    }

    private func geocode(_ course: Course) {
        Task { @MainActor in
            let geocoder = CLGeocoder()
            guard let loc = (try? await geocoder.geocodeAddressString(course.address))?
                .first?.location else { return }
            course.latitude = loc.coordinate.latitude
            course.longitude = loc.coordinate.longitude
            try? modelContext.save()
            withAnimation(.easeInOut(duration: 0.4)) {
                camera = .region(MKCoordinateRegion(center: loc.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)))
            }
        }
    }
}

/// Compact, read-only drive indicator for the scorecard column — shows the
/// measured drive distance when the hole's tee is set, else a pin/dash.
struct DriveGlyph: View {
    let hole: Hole

    var body: some View {
        if let y = yards {
            Text("\(y)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.accent)
        } else if hole.hasDrive {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 11))
                .foregroundStyle(Theme.accent)
        } else {
            Text("—")
                .font(.system(size: 11))
                .foregroundStyle(Theme.dimmer)
        }
    }

    private var courseHole: CourseHole? {
        hole.round?.course?.holes.first { $0.number == hole.number }
    }

    private var yards: Int? {
        guard hole.hasDrive, let ch = courseHole, ch.hasTee else { return nil }
        let a = CLLocation(latitude: ch.teeLatitude, longitude: ch.teeLongitude)
        let b = CLLocation(latitude: hole.driveLat, longitude: hole.driveLng)
        return Int((a.distance(from: b) * 1.0936133).rounded())
    }
}
