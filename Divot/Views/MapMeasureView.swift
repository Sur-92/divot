import SwiftUI
import SwiftData
import MapKit
import CoreLocation

/// Two-point distance measurement on a satellite map. Drop point A
/// (the tee), drop point B (the ball), get the geodesic distance in
/// yards via `CLLocation.distance(from:)`. Points can come from your
/// current GPS fix ("MARK HERE") or by tapping the map. A course picker
/// in the toolbar flies the camera to any saved course with coordinates.
struct MapMeasureView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var location = LocationService.shared

    // `@Query` in a NavigationSplitView detail pane has been observed to
    // resolve against an empty context — the dropdown came up with zero
    // courses even though the Courses screen sees them all. Fetching
    // manually with a FetchDescriptor on appear sidesteps that.
    @State private var courses: [Course] = []

    @State private var pointA: CLLocationCoordinate2D?
    @State private var pointB: CLLocationCoordinate2D?
    @State private var selectedCourse: Course?
    @State private var showingCoursePicker: Bool = false

    /// Courses with usable lat/lon, sorted alphabetically. (Kept for the
    /// header count badge — the picker itself now shows every course so
    /// the dropdown is never empty.)
    private var coursesWithCoords: [Course] {
        courses.filter { $0.coordinate != nil }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Every course, sorted alphabetically. Used by the picker so the
    /// dropdown is never empty — rows without coords show a subtle
    /// "no coords" hint and don't move the camera when tapped.
    private var allCoursesSorted: [Course] {
        courses.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    /// Camera state. Defaults to a wide US-Eastern view; recenters once
    /// we have an authorization-granted location fix.
    @State private var camera: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.27, longitude: -76.70),
            span: MKCoordinateSpan(latitudeDelta: 0.6, longitudeDelta: 0.6)
        )
    )

    /// Last interacted point — controls which slot the next "MARK HERE"
    /// fills (alternates A → B → A …) so the user can chain measurements.
    @State private var nextSlotIsB: Bool = false

    /// Selection target when tapping the map: which slot gets the new pin.
    @State private var tapTarget: TapTarget = .a
    enum TapTarget { case a, b }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            courseBar
            controlBar
            mapPanel
            footer
        }
        .onAppear {
            location.start()
            reloadCourses()
        }
        .onChange(of: showingCoursePicker) { _, opening in
            if opening { reloadCourses() }
        }
        // Auto-recenter on the user's GPS fix is intentionally disabled —
        // it kept yanking the camera back to the user while they were
        // panning around to measure shots. GPS still runs (for "MARK
        // HERE" pin-drop) but the map no longer moves on its own.
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MAP · MEASURE")
                .font(.system(size: 11, weight: .semibold))
                .tracking(4)
                .foregroundStyle(Theme.accent)
            Text("Drop two pins. Distance is geodesic, in yards.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.dim)
            Rectangle()
                .fill(Theme.accent)
                .frame(width: 28, height: 1.5)
                .padding(.top, 2)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 12)
    }

    // MARK: - Course bar

    private var courseBar: some View {
        HStack(spacing: 12) {
            Text("FLY TO")
                .font(.system(size: 9, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Theme.dim)

            // Themed dropdown — opens a styled popover with the full
            // list of courses. Replaces the native macOS Menu so the
            // typography and color match the rest of the app.
            Button {
                showingCoursePicker.toggle()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text(selectedCourse?.name ?? "Pick a course")
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Image(systemName: showingCoursePicker
                          ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .frame(width: 320, alignment: .leading)
                .overlay(RoundedRectangle(cornerRadius: 3)
                    .stroke(Theme.accent.opacity(0.6), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showingCoursePicker, arrowEdge: .bottom) {
                coursePickerPopover
            }


            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 10)
    }

    // MARK: - Course picker popover

    private var coursePickerPopover: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("FLY TO COURSE")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2.5)
                    .foregroundStyle(Theme.accent)
                Spacer()
                Text("\(coursesWithCoords.count)")
                    .font(.system(size: 10, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.dim)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Rectangle()
                .fill(LinearGradient(
                    colors: [Theme.accent.opacity(0.5), Theme.hairline, .clear],
                    startPoint: .leading, endPoint: .trailing
                ))
                .frame(height: 1)

            if allCoursesSorted.isEmpty {
                Text("No saved courses yet.")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.dim)
                    .padding(14)
                    .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(allCoursesSorted.enumerated()), id: \.element.id) { index, course in
                            coursePickerRow(course,
                                            isAlternate: index.isMultiple(of: 2))
                            if index < allCoursesSorted.count - 1 {
                                Rectangle()
                                    .fill(Theme.hairline.opacity(0.6))
                                    .frame(height: 1)
                            }
                        }
                    }
                }
                .frame(maxHeight: 360)
            }
        }
        .frame(width: 360)
        .background(
            ZStack {
                Color.black.opacity(0.92)
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.14, blue: 0.30).opacity(0.55),
                        Color(red: 0.04, green: 0.10, blue: 0.22).opacity(0.65)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            }
        )
    }

    private func coursePickerRow(_ course: Course, isAlternate: Bool) -> some View {
        let isSelected = selectedCourse?.id == course.id
        return Button {
            flyTo(course)
            showingCoursePicker = false
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Rectangle()
                    .fill(isSelected ? Theme.accent : .clear)
                    .frame(width: 2, height: 36)
                CourseLogo(assetName: course.logoAssetName, height: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(course.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(1)
                    if !course.address.isEmpty {
                        Text(course.address)
                            .font(.system(size: 9))
                            .foregroundStyle(Theme.dim)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.accent)
                        .padding(.trailing, 14)
                }
            }
            .padding(.vertical, 8)
            .background(isAlternate
                        ? Color.white.opacity(0.04)
                        : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Pin label rendered as a translucent name + address card so the
    /// course is clearly identified at the centered zoom level.
    private func courseLabel(for course: Course) -> some View {
        VStack(spacing: 2) {
            Text(course.name.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(.white)
            if !course.address.isEmpty {
                Text(course.address)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
            }
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(Theme.accent)
                .offset(y: 2)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.black.opacity(0.78))
                .overlay(RoundedRectangle(cornerRadius: 4)
                    .stroke(Theme.accent, lineWidth: 1))
        )
        .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
    }

    /// Compact 2- or 3-letter abbreviation for the chip row.
    private func shortLabel(for course: Course) -> String {
        let words = course.name
            .replacingOccurrences(of: "Golf Club", with: "")
            .replacingOccurrences(of: "Golf Course", with: "")
            .replacingOccurrences(of: "Golf Complex", with: "")
            .split(separator: " ")
        let initials = words.compactMap { $0.first }.map(String.init).joined()
        return initials.isEmpty ? course.name.prefix(3).uppercased()
                                : initials.uppercased()
    }

    // MARK: - Control bar

    private var controlBar: some View {
        HStack(spacing: 12) {
            slotChip(label: "A · TEE",
                     coord: pointA,
                     isActiveTap: tapTarget == .a,
                     onTap: { tapTarget = .a },
                     onMarkHere: { markHereFor(.a) },
                     onClear: { pointA = nil })

            slotChip(label: "B · BALL",
                     coord: pointB,
                     isActiveTap: tapTarget == .b,
                     onTap: { tapTarget = .b },
                     onMarkHere: { markHereFor(.b) },
                     onClear: { pointB = nil })

            Spacer()

            if pointA != nil || pointB != nil {
                Button {
                    pointA = nil
                    pointB = nil
                    tapTarget = .a
                } label: {
                    Text("RESET")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .overlay(RoundedRectangle(cornerRadius: 3)
                            .stroke(Theme.accent.opacity(0.6), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }

    private func slotChip(label: String,
                          coord: CLLocationCoordinate2D?,
                          isActiveTap: Bool,
                          onTap: @escaping () -> Void,
                          onMarkHere: @escaping () -> Void,
                          onClear: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.8)
                    .foregroundStyle(isActiveTap ? Theme.accent : Theme.dim)
                if isActiveTap {
                    Text("· tap-to-set")
                        .font(.system(size: 8, weight: .medium))
                        .tracking(1.2)
                        .foregroundStyle(Theme.accent.opacity(0.8))
                }
            }
            if let coord {
                Text(String(format: "%.5f, %.5f", coord.latitude, coord.longitude))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Theme.primaryText)
            } else {
                Text("not set")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.dimmer)
            }
            HStack(spacing: 6) {
                miniButton("MARK HERE",
                           filled: true,
                           enabled: location.lastLocation != nil,
                           action: onMarkHere)
                miniButton(coord == nil ? "TAP-TO-SET" : "RE-AIM",
                           filled: false,
                           enabled: true,
                           action: onTap)
                if coord != nil {
                    miniButton("✕",
                               filled: false,
                               enabled: true,
                               action: onClear)
                }
            }
        }
        .padding(10)
        .frame(width: 240, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 4)
            .fill(Color.black.opacity(0.18)))
        .overlay(RoundedRectangle(cornerRadius: 4)
            .stroke(isActiveTap ? Theme.accent.opacity(0.7) : Theme.hairline,
                    lineWidth: 1))
    }

    private func miniButton(_ text: String,
                            filled: Bool,
                            enabled: Bool,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 8, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(filled ? .black : Theme.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    Group {
                        if filled {
                            RoundedRectangle(cornerRadius: 2).fill(Theme.accent)
                        } else {
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Theme.accent.opacity(0.6), lineWidth: 1)
                        }
                    }
                )
                .opacity(enabled ? 1 : 0.4)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    // MARK: - Map

    private var mapPanel: some View {
        MapReader { proxy in
            Map(position: $camera) {
                // Centered course label — shows when a course is picked
                // from the FLY TO bar. Title is the course name; subtitle
                // is the address. Sits over the clubhouse coordinate.
                if let course = selectedCourse,
                   let coord = course.coordinate {
                    Annotation(course.name,
                               coordinate: coord,
                               anchor: .bottom) {
                        courseLabel(for: course)
                    }
                }

                // Pin A — custom annotation so the marker is unmistakable.
                if let p = pointA {
                    Annotation("A · Tee", coordinate: p, anchor: .bottom) {
                        pinView(letter: "A",
                                color: Theme.accent,
                                trailingLabel: "TEE")
                    }
                }

                // Pin B — red ball marker.
                if let p = pointB {
                    Annotation("B · Ball", coordinate: p, anchor: .bottom) {
                        pinView(letter: "B",
                                color: Color(red: 0.95, green: 0.25, blue: 0.25),
                                trailingLabel: "BALL")
                    }
                }

                // Connecting polyline once both pins are placed.
                if let a = pointA, let b = pointB {
                    MapPolyline(coordinates: [a, b])
                        .stroke(Theme.accent, lineWidth: 4)
                }

                // UserAnnotation() removed — no live "blue dot" on the
                // map. GPS still feeds the "MARK HERE" buttons on demand.
            }
            .mapStyle(.imagery(elevation: .realistic))
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            // macOS Map eats `.onTapGesture` and `.gesture(SpatialTap…)` —
            // the map's own pan recognizer wins exclusivity. `simultaneous`
            // lets our tap handler fire alongside the pan. `contentShape`
            // ensures hit-testing covers the entire frame, including any
            // transparent slivers around tiles.
            .contentShape(Rectangle())
            .simultaneousGesture(
                SpatialTapGesture(count: 1, coordinateSpace: .local)
                    .onEnded { value in
                        if let coord = proxy.convert(value.location, from: .local) {
                            placePin(at: coord)
                        }
                    }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
    }

    /// Annotation pin used for the A and B measurement points.
    /// Big circular badge with the letter and a trailing label so the
    /// marker reads at a glance from any zoom level.
    private func pinView(letter: String,
                         color: Color,
                         trailingLabel: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(color)
                    Circle()
                        .stroke(.white, lineWidth: 2)
                    Text(letter)
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.white)
                }
                .frame(width: 26, height: 26)
                .shadow(color: .black.opacity(0.45), radius: 3, x: 0, y: 1)

                Text(trailingLabel)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 3)
                        .fill(Color.black.opacity(0.7)))
                    .overlay(RoundedRectangle(cornerRadius: 3)
                        .stroke(color, lineWidth: 1))
            }

            // Pointer triangle pointing down to the actual coordinate.
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(color)
        }
    }

    // MARK: - Footer (distance + status)

    private var footer: some View {
        HStack(spacing: 18) {
            distancePanel
            Spacer()
            statusPanel
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private var distancePanel: some View {
        let yards = distanceYards
        return HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("DISTANCE")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2.5)
                    .foregroundStyle(Theme.dim)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(yards.map { "\($0)" } ?? "—")
                        .font(.system(size: 36, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(yards != nil ? Theme.accent : Theme.dim)
                    Text("YDS")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(Theme.dim)
                }
                if let m = distanceMeters {
                    Text(String(format: "%.1f m", m))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Theme.dimmer)
                }
            }
        }
    }

    private var statusPanel: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text("GPS")
                .font(.system(size: 9, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Theme.dim)
            Text(gpsStatusText)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(gpsStatusColor)
            if let acc = location.lastLocation?.horizontalAccuracy, acc > 0 {
                Text(String(format: "± %.0f m", acc))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Theme.dimmer)
            }
            if let err = location.lastError {
                Text(err)
                    .font(.system(size: 9))
                    .foregroundStyle(Color.red.opacity(0.85))
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 240)
            }
        }
    }

    // MARK: - Computed

    private var distanceMeters: Double? {
        guard let a = pointA, let b = pointB else { return nil }
        let la = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let lb = CLLocation(latitude: b.latitude, longitude: b.longitude)
        return la.distance(from: lb)
    }

    private var distanceYards: Int? {
        distanceMeters.map { Int(($0 * 1.0936133).rounded()) }
    }

    private var gpsStatusText: String {
        switch location.authorization {
        case .notDetermined: return "asking…"
        case .restricted:    return "restricted"
        case .denied:        return "denied"
        case .authorizedAlways, .authorized:
            return location.lastLocation == nil ? "acquiring…" : "live"
        @unknown default:    return "—"
        }
    }

    private var gpsStatusColor: Color {
        switch location.authorization {
        case .denied, .restricted: return Color.red.opacity(0.85)
        case .authorizedAlways, .authorized:
            return location.lastLocation == nil ? Theme.dim : Theme.accent
        default:                   return Theme.dim
        }
    }

    // MARK: - Actions

    /// Drop a pin at the device's current location into slot A or B.
    private func markHereFor(_ slot: TapTarget) {
        guard let here = location.lastLocation?.coordinate else {
            location.start()
            return
        }
        switch slot {
        case .a:
            pointA = here
            tapTarget = .b
        case .b:
            pointB = here
            tapTarget = .a
        }
    }

    /// Manual course fetch. Replaces the previous `@Query` which was
    /// resolving against an empty context inside the NavigationSplitView
    /// detail pane and returning zero rows.
    private func reloadCourses() {
        let descriptor = FetchDescriptor<Course>(
            sortBy: [SortDescriptor(\Course.name)]
        )
        courses = (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Fly the camera to a saved course. Uses the stored lat/lon as a
    /// first frame, then asks CLGeocoder to resolve the actual address —
    /// when the geocoded result lands, the camera nudges to the precise
    /// center and the stored coords get refined for next time. Zoom is
    /// tight enough to read greens and tee boxes clearly.
    private func flyTo(_ course: Course) {
        selectedCourse = course

        // 1. Initial frame from whatever coords we already have.
        if let coord = course.coordinate {
            withAnimation(.easeInOut(duration: 0.45)) {
                camera = .region(.tightCourseFrame(at: coord))
            }
        }

        // 2. Refine asynchronously by geocoding the address. If the
        // address is empty or the geocode fails, we keep the seeded
        // frame from step 1.
        guard !course.address.isEmpty else { return }
        Task { @MainActor in
            let geocoder = CLGeocoder()
            do {
                let placemarks = try await geocoder.geocodeAddressString(course.address)
                guard let loc = placemarks.first?.location else { return }
                // Persist the refined coord so the next fly-to is exact
                // without another network call.
                course.latitude = loc.coordinate.latitude
                course.longitude = loc.coordinate.longitude
                withAnimation(.easeInOut(duration: 0.5)) {
                    camera = .region(.tightCourseFrame(at: loc.coordinate))
                }
            } catch {
                // Silent — keep the seeded frame, no user-facing error
                // for a best-effort refinement.
            }
        }
    }

    /// Drop a pin from a tap on the map into whichever slot is active.
    private func placePin(at coord: CLLocationCoordinate2D) {
        // Tapping the map switches off the centered course label so the
        // measurement work doesn't get shouted over.
        selectedCourse = nil
        switch tapTarget {
        case .a:
            pointA = coord
            tapTarget = .b
        case .b:
            pointB = coord
            tapTarget = .a
        }
    }
}

// MARK: - Region helper

private extension MKCoordinateRegion {
    /// A tight zoom suitable for centering on a course's clubhouse —
    /// roughly a 350m square. Close enough to read greens, fairways,
    /// tee boxes, cart paths.
    static func tightCourseFrame(at coord: CLLocationCoordinate2D) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: coord,
            span: MKCoordinateSpan(latitudeDelta: 0.0035,
                                   longitudeDelta: 0.0035)
        )
    }
}
