import Foundation
import CoreLocation
import Combine

/// Lightweight wrapper around CLLocationManager. Publishes the latest
/// fix and authorization state so SwiftUI views can observe and pin
/// markers on demand. Uses `kCLLocationAccuracyBest` because shot
/// distances need every meter we can get; on macOS this is Wi-Fi /
/// IP-assisted positioning (10-50m typical), not phone-grade GNSS.
@MainActor
final class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()

    @Published private(set) var authorization: CLAuthorizationStatus
    @Published private(set) var lastLocation: CLLocation?
    @Published private(set) var lastError: String?

    private let manager = CLLocationManager()

    override init() {
        self.authorization = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 1  // meters — every move matters for shot measure
    }

    /// Prompt for permission if we haven't asked, otherwise just start.
    func start() {
        switch authorization {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            lastError = "Location access denied — enable it in System Settings → Privacy & Security → Location Services."
        default:
            manager.startUpdatingLocation()
        }
    }

    func stop() {
        manager.stopUpdatingLocation()
    }

    /// Single one-shot fix request — fires .startUpdating briefly, then stops
    /// after the next sample comes in.
    func requestOneShot() {
        start()
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorization = status
            switch status {
            case .authorizedAlways, .authorized:
                manager.startUpdatingLocation()
            case .denied, .restricted:
                self.lastError = "Location access denied — enable it in System Settings → Privacy & Security → Location Services."
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            self.lastLocation = loc
            self.lastError = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {
        let msg = error.localizedDescription
        Task { @MainActor in
            self.lastError = msg
        }
    }
}
