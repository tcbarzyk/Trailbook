//
//  LocationManager.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/14/25.
//

import CoreLocation

class LocationManager: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    @Published var userLocation: CLLocation?
    @Published var lastKnownPlacemark: CLPlacemark?
    @Published var hasLocationAccess: Bool = false
    // static let shared = LocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        // manager.startUpdatingLocation()
    }

    func requestLocationAccess() {
        manager.requestWhenInUseAuthorization()
    }

    func startFetchingCurrentLocation() {
        manager.startUpdatingLocation()
    }
    func stopFetchingCurrentLocation() {
        manager.stopUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            hasLocationAccess = false
            print("DEBUG: Not determined")
        case .restricted:
            hasLocationAccess = false
            print("DEBUG: Restricted")
        case .denied:
            hasLocationAccess = false
            print("DEBUG: Denied")
        case .authorizedAlways:
            hasLocationAccess = true
            print("DEBUG: Auth Always")
        case .authorizedWhenInUse:
            hasLocationAccess = true
            print("DEBUG: Auth when in use")
        case .authorized:
            hasLocationAccess = true
            print("DEBUG: Auth")
        @unknown default:
            hasLocationAccess = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first, error == nil {
                self.lastKnownPlacemark = placemark
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}
