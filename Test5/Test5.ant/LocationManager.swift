import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var totalDistance: CLLocationDistance = 0.0
    @Published var distanceFromHome: CLLocationDistance = 0.0
    @Published var durationString: String = ""
    @Published var course: Double = 0.0
    @Published var courseDiff: Double = 0.0
    @Published var maxCourseDiff: Double = 0.0
    @Published var speed: Double = 0.0
    @Published var speedCalc: Double = 0.0
    @Published var speedAvg: Double = 0.0
    @Published var isHome: Bool = true
    @Published var horAccuracy: Double = 0.0
    @Published var missedCourseCount: Int = 0
    @Published var totalCount: Int = 0

    private var tooFarAlertSent: Bool = false
    
    private var currentLocation: CLLocation = CLLocation()
    private var homeLocation: CLLocation?
    private var lastLocation: CLLocation?
    private var lastLocationForSpeedCalc: CLLocation?
    private let locationManager = CLLocationManager()
    
    private var locationBuffer: [CLLocation] = []
    private let bufferSize = 10 // Number of previous locations to consider for the moving average
    private let departureProximity: CLLocationDistance = 10.0
    private let arrivalProximity: CLLocationDistance = 10.0
    private let maxAllowedDistance: Double = 1000
    private var lastLocationTs: Date = Date()
    private var lastCourse: Double = -1.0
    private var leftHomeTs: Date = Date()
    
    private let speedCalcUpdateIntervalSec: Double = 2
    private var speedCalcCount: Int = 0
    private let logUpdateInterval: Double = 10
    
    // For GPS rate calculation
    private let gpsLogUpdateInterval: Double = 600
    private var lastTs: TimeInterval = 0
    private var count: Int = 0
    @Published var updateRate: Double = 0.0
    private var lastRefreshUpdateTs: TimeInterval = 0
    // End of GPS rate calc
    
    // Debug update interval
    private var lastDebugUpdateTs: TimeInterval = 0
    
    private var fs: FireStoreManager
    
    init (fs: FireStoreManager) {
        self.fs = fs
        super.init()
        locationManager.delegate = self
    }

    func clearAll()  {
        totalDistance = 0.0
        distanceFromHome = 0.0
        durationString = ""
        course = 0.0
        courseDiff = 0.0
        maxCourseDiff = 0.0
        speed = 0.0
        speedCalc = 0.0
        speedAvg = 0.0
        isHome = true
        horAccuracy = 0.0
        missedCourseCount = 0
        totalCount = 0
        tooFarAlertSent = false
        // currentLocation: CLLocation = CLLocation()
        lastLocation = nil
        lastLocationForSpeedCalc = nil
        locationBuffer = []
        lastLocationTs = Date()
        lastCourse = -1.0
        leftHomeTs = Date()
        lastTs = 0
        count = 0
        updateRate = 0.0
        lastRefreshUpdateTs = 0
        lastDebugUpdateTs = 0
        speedCalcCount = 0
    }
    
    
    func startUpdatingLocation() {
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        // locationManager.distanceFilter = 10
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func setHome() {
        homeLocation = currentLocation
        let msg = String(format: "Home: %.5f, %.5f", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude)
        fs.sendDebug(msg: msg)
        durationString = durationToString(durationInSeconds: 0)
        clearAll()
    }
    
    func logGPSUpdateRate() {
        count += 1
        let timeDiff = Date().timeIntervalSince1970 - lastTs
        if (timeDiff >= gpsLogUpdateInterval) {
            updateRate = Double(count) / Double(timeDiff)
            count = 0
            lastTs = Date().timeIntervalSince1970
            if ((lastTs - lastRefreshUpdateTs) > 600) {
                let msg = "GPS update rate: " + String(format: "%.2f", updateRate)
                fs.sendDebug(msg: msg)
                lastRefreshUpdateTs = lastTs
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {

            currentLocation = location
            if (homeLocation == nil) {
                setHome()
            }

            logGPSUpdateRate()
            
            var distance = 0.0

            totalCount += 1

            if let lastLocation = lastLocation {
                if (location.course >= 0.00001) {
                    course = location.course
                    distance = location.distance(from: lastLocation)
                    totalDistance += distance
                    if (lastCourse >= 0.00001) {
                        courseDiff = abs(location.course - lastCourse)
                        if (courseDiff > maxCourseDiff) {
                            maxCourseDiff = courseDiff
                        }
                    }
                }
                else {
                    missedCourseCount += 1
                }
            }
            
            distanceFromHome = homeLocation!.distance(from: location)
            let loc = String(format: "%.5f, %.5f", location.coordinate.latitude, location.coordinate.longitude)
            
            if (distanceFromHome > maxAllowedDistance && !tooFarAlertSent) {
                var msg = "Too far: " + String(distanceFromHome)
                msg += ", coords: " + loc;
                fs.sendAlertNotification(msg: msg, type: "tooFar")
                tooFarAlertSent = true
            }

            if (isHome) {
                durationString = durationToString(durationInSeconds: 0)
            } else {
                speed = location.speed
                let timeDiff = Date().timeIntervalSince(leftHomeTs)
                durationString = durationToString(durationInSeconds: timeDiff)
                if (timeDiff > 0.0001) {
                    speedAvg = totalDistance / timeDiff
                }
                
                if (lastLocationForSpeedCalc != nil) && (distance > 0.0001) {
                    
                    let calendar = Calendar.current
                    let components = calendar.dateComponents([.nanosecond], from: lastLocationForSpeedCalc!.timestamp, to: location.timestamp)
                    let microseconds = components.nanosecond! / 1000
                    if (microseconds != 0) {
                        speedCalc = distance / Double(microseconds) * 1000000.0
                    }
                }
            }

            if (Date().timeIntervalSince1970 - lastDebugUpdateTs >= logUpdateInterval) {
                
                let fromHomeString = String(format: "Distance from home: %.2f", distanceFromHome)
                let totalDistanceString = String(format: "Total distance: %.2f", totalDistance)
                let courseString = String(format: "Course: %.2f", course)
                let courseDiffString = String(format: "CourseDiff: %.2f", courseDiff)
                let maxCourseDiffString = String(format: "MaxCourseDiff: %.2f", maxCourseDiff)

                horAccuracy = location.horizontalAccuracy
                let accuracyString = String (format: "HorAccuracy: %.2f", location.horizontalAccuracy)
                
                var msg = fromHomeString + ", " + totalDistanceString + ", Trip duration: " + durationString + ", loc: " + loc
                fs.sendDebug(msg: msg)
                
                msg = courseString + ", " + courseDiffString + ", " + maxCourseDiffString + ", " + accuracyString
                fs.sendDebug(msg: msg)

                let speedString = String(format: "Speed: %.2f", speed)
                let speedCalcString = String(format: "Speed calc: %.2f", speedCalc)
                let speedAvgString = String(format: "Speed avg: %.2f", speedAvg)
                msg = speedString + ", " + speedCalcString + ", " + speedAvgString
                
                lastDebugUpdateTs = Date().timeIntervalSince1970
            }
            
            if (isHome && distanceFromHome > departureProximity) {
                leftHomeTs = Date()
                isHome = false
                let tmpDistanceFromHome = distanceFromHome
                clearAll()
                totalDistance = tmpDistanceFromHome
                fs.sendAlertNotification(msg: "Departure", type: "departure")
                fs.sendDebug(msg: "Departure")
            }
            else if (!isHome && distanceFromHome < arrivalProximity) {
                isHome = true
                let duration = Date().timeIntervalSince(leftHomeTs)
                let msg = "Arrival. Duration:" + durationToString(durationInSeconds: duration)
                fs.sendAlertNotification(msg: msg, type: "arrival")
                fs.sendDebug(msg: msg)
            }
            
            lastLocation = currentLocation
            lastLocationTs = Date()
            if (currentLocation.course >= 0.00001) {
                lastCourse = currentLocation.course
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

