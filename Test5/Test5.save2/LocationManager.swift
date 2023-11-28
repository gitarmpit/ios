import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()

    private var currentLocation: CLLocation?
    private var lastLocation: CLLocation?

    private let departureProximity: CLLocationDistance = 50.0
    private let arrivalProximity: CLLocationDistance = 20.0

    private var isHome: Bool = true
    private var leftHomeTs: TimeInterval = 0
    private var sessionStartTs: TimeInterval = 0

    private let maxAllowedDistance: Double = 2000
    
    private var lastTs: TimeInterval = 0
    private var count: Int = 0

    private var lastRefreshUpdateTs: TimeInterval = 0
    
    private var fs: FireStoreManager
    private let sharedData: SharedObservableData
    
    init(fs: FireStoreManager, sharedData: SharedObservableData) {
        self.sharedData = sharedData
        self.fs = fs
        super.init()
        locationManager.delegate = self
    }
    
    func startUpdatingLocation() {
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        // locationManager.distanceFilter = 10
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startUpdatingLocation()
        count = 0
        lastTs = Date().timeIntervalSince1970
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func setHome() {
        if let _currentLocation = currentLocation {
            sharedData.homeLocation = _currentLocation
            sharedData.totalDistance = 0
            sharedData.distanceFromHome = 0
            let loc = String(format: "%.2f %.2f", _currentLocation.coordinate.latitude, _currentLocation.coordinate.longitude)
            //FireStoreManager.shared.sendHomeLocationSetNotification(loc: loc)
            fs.sendHomeLocationSetNotification(loc: loc)
            sharedData.tripDurationString = ""
            sessionStartTs = Date().timeIntervalSince1970
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {

            currentLocation = location
            if (sharedData.homeLocation == nil) {
                // setHome()
            }
            
            self.count += 1
            let timeDiff = Date().timeIntervalSince1970 - self.lastTs
            if (timeDiff >= 10) {
                self.sharedData.GPS_updateRate = Double(self.count) / Double(timeDiff)
                self.count = 0
                self.lastTs = Date().timeIntervalSince1970
                if (self.lastTs - lastRefreshUpdateTs > 10) {
                    //fs!.sendRefreshUpdateStat(msg: String(self.updateRate))
                }
            }

            if let lastLocation = lastLocation {
                let distance = location.distance(from: lastLocation)
                sharedData.totalDistance += distance
            }
            
            
            lastLocation = currentLocation
            if let _homeLocation = sharedData.homeLocation {
                sharedData.distanceFromHome = _homeLocation.distance(from: location)
                if (sharedData.distanceFromHome > maxAllowedDistance) {
                    var msg = "Too far: " + String(sharedData.distanceFromHome)
                    let loc = String(format: "%.2f %.2f", location.coordinate.latitude, location.coordinate.longitude)
                    msg += ", coords: " + loc;
                    //FireStoreManager.shared.sendAlertNotification(msg: msg)
                    //fs!.sendAlertNotification(msg: msg)
                }
                
                //FireStoreManager.shared.sendDistanceFromHomeNotification(distanceFromHome: String(distanceFromHome), totalDistance: String(totalDistance))
                //fs!.sendDistanceFromHomeNotification(distanceFromHome: String(distanceFromHome), totalDistance: String(totalDistance))

                if (isHome && sharedData.distanceFromHome > departureProximity) {
                    leftHomeTs = Date().timeIntervalSince1970
                    isHome = false
                    sharedData.totalDistance = sharedData.distanceFromHome
                    //FireStoreManager.shared.sendDepartureNotification()
                    //fs!.sendDepartureNotification()
                }
                else if (!isHome && sharedData.distanceFromHome < arrivalProximity) {
                    let gotBackTs = Date().timeIntervalSince1970
                    isHome = true
                    let duration = gotBackTs - leftHomeTs
                    //FireStoreManager.shared.sendArrivalNotification(duration: String(duration))
                    
                    //FireStoreManager.shared.sendArrivalNotification(duration: durationToString(durationInSeconds: duration))
                    //fs!.sendArrivalNotification(duration: durationToString(durationInSeconds: duration))
                }
                sharedData.tripDurationString = durationToString(durationInSeconds: (Date().timeIntervalSince1970 - sessionStartTs))
            }
        }
    }

    func durationToString(durationInSeconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        
        if let durationString = formatter.string(from: durationInSeconds) {
            return durationString
        } else {
            return ""
        }
    }

}

