import Foundation
import CoreLocation

class SharedObservableData: ObservableObject {
    
    // Location Manager
    @Published var homeLocation: CLLocation?
    @Published var tripDurationString: String = ""
    @Published var GPS_updateRate: Double = 0.0
    @Published var totalDistance: CLLocationDistance = 0.0
    @Published var distanceFromHome: CLLocationDistance = 0.0

    // Accelerometer
    @Published var accState: String = "???"
    @Published var acX: Double = 0.0
    @Published var acY: Double = 0.0
    @Published var acZ: Double = 0.0
    
    @Published var maxAcX: Double = 0.0
    @Published var maxAcY: Double = 0.0
    @Published var maxAcZ: Double = 0.0
    @Published var maxAc: Double = 0.0
    
    @Published var maxDiffAcX: Double = 0.0
    @Published var maxDiffAcY: Double = 0.0
    @Published var maxDiffAcZ: Double = 0.0
    @Published var maxDiffTotal: Double = 0.0

    // Firebase
    @Published var firestoreError: String = ""

    func clearAcceleratorData() {
        acX = 0
        acY = 0
        acZ = 0
        maxAcX = 0
        maxAcY = 0
        maxAcZ = 0
        maxAc = 0
        maxDiffAcX = 0
        maxDiffAcY = 0
        maxDiffAcZ = 0
        maxDiffTotal = 0
    }
    
    
}
