import CoreLocation
import Domain

/// `LocationProviding` backed by CoreLocation — a one-shot current-location request that
/// asks for When-In-Use permission on first use. Used by the ＋ flow to claim at the
/// user's real position instead of a fixed place.
@MainActor
public final class LocationProvider: NSObject, LocationProviding {
    public enum LocationError: Error { case denied, unavailable }

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<Coordinate, Error>?
    private var timeoutTask: Task<Void, Never>?
    private let timeout: TimeInterval

    /// - Parameter timeout: hard cap on how long `current()` waits for a CoreLocation callback
    ///   before giving up. Guards against the callback never arriving (e.g. a simulator with no
    ///   location set), which would otherwise suspend the caller forever.
    public init(timeout: TimeInterval = 8) {
        self.timeout = timeout
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    public func current() async throws -> Coordinate {
        try await withCheckedThrowingContinuation { cont in
            guard continuation == nil else {
                cont.resume(throwing: LocationError.unavailable)
                return
            }
            continuation = cont
            // CoreLocation can deliver NEITHER a fix nor an error (notably a simulator with no
            // location configured), which would leave this continuation suspended forever and
            // hang every caller (Home feed, Map, the ＋ claim flow). A timeout guarantees the
            // continuation always resumes so callers hit their fallback / error path instead.
            timeoutTask = Task { @MainActor [weak self] in
                let ns = UInt64((self?.timeout ?? 8) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: ns)
                guard !Task.isCancelled else { return }
                self?.finish(.failure(LocationError.unavailable))
            }
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .notDetermined:
                manager.requestWhenInUseAuthorization()  // requestLocation fires once granted
            case .denied, .restricted:
                finish(.failure(LocationError.denied))
            @unknown default:
                finish(.failure(LocationError.unavailable))
            }
        }
    }

    private func finish(_ result: Result<Coordinate, Error>) {
        timeoutTask?.cancel()
        timeoutTask = nil
        guard let cont = continuation else { return }
        continuation = nil
        cont.resume(with: result)
    }
}

extension LocationProvider: CLLocationManagerDelegate {
    public nonisolated func locationManager(_ manager: CLLocationManager,
                                            didUpdateLocations locations: [CLLocation]) {
        guard let c = locations.last?.coordinate else {
            Task { @MainActor in finish(.failure(LocationError.unavailable)) }
            return
        }
        let (lat, lng) = (c.latitude, c.longitude)
        Task { @MainActor in finish(.success(Coordinate(latitude: lat, longitude: lng))) }
    }

    public nonisolated func locationManager(_ manager: CLLocationManager,
                                            didFailWithError error: Error) {
        Task { @MainActor in finish(.failure(error)) }
    }

    public nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                if continuation != nil { self.manager.requestLocation() }
            case .denied, .restricted:
                finish(.failure(LocationError.denied))
            default:
                break
            }
        }
    }
}
