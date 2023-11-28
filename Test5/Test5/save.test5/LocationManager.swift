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
    @Published var alertMsg: String = ""
    
    private var tooFarAlertSent: Bool = false
    
    private var currentLocation: CLLocation = CLLocation()
    private var homeLocation: CLLocation?
    private var lastLocation: CLLocation?
    private var lastLocationForSpeedCalc: CLLocation?
    private let locationManager = CLLocationManager()
    
    private var locationBuffer: [CLLocation] = []
    private let bufferSize = 10 // Number of previous locations to consider for the moving average
    private let departureProximity: CLLocationDistance = 30.0
    private let arrivalProximity: CLLocationDistance = 10.0
    private let maxAllowedDistance: Double = 1000
    private var lastCourse: Double = -1.0
    private var leftHomeTs: Date = Date()
    
    private let speedCalcUpdateIntervalSec: Double = 5
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
    
    private let mphMultiplier = 2.23693629
    private let kmhMultiplier = 3.6

    private let stationaryAlarmThresholdSec = 10
    private var lastTimeMotionDetected: Date = Date()
    private var stationaryAlertSent: Bool = false

    private let warmupSeconds = 10

    private let speedMultiplier: Double
    private var fs: FireStoreManager
    
    init (fs: FireStoreManager) {
        self.fs = fs
        self.speedMultiplier = kmhMultiplier
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
        horAccuracy = 0.0
        missedCourseCount = 0
        totalCount = 0
        tooFarAlertSent = false
        // currentLocation: CLLocation = CLLocation()
        lastLocation = nil
        lastLocationForSpeedCalc = nil
        locationBuffer = []
        lastCourse = -1.0
        leftHomeTs = Date()
        lastTs = 0
        count = 0
        updateRate = 0.0
        lastRefreshUpdateTs = 0
        lastDebugUpdateTs = 0
        speedCalcCount = 0
        lastTimeMotionDetected = Date()
        stationaryAlertSent = false
        alertMsg = ""
    }
    
    
    func startUpdatingLocation() {
        clearAll()
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
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
        clearAll()
        durationString = ""
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
    
    func tripUpdate(locString: String) {
        if (Date().timeIntervalSince1970 - lastDebugUpdateTs >= logUpdateInterval) {
            
            let fromHomeString = String(format: "Distance from home: %.2f", distanceFromHome)
            let totalDistanceString = String(format: "Total distance: %.2f", totalDistance)
            let courseString = String(format: "Course: %.2f", course)
            let courseDiffString = String(format: "CourseDiff: %.2f", courseDiff)
            let maxCourseDiffString = String(format: "MaxCourseDiff: %.2f", maxCourseDiff)
            
            var msg = fromHomeString + ", " + totalDistanceString + ", Trip duration: " + durationString + ", loc: " + locString
            fs.sendDebug(msg: msg)
            
            msg = courseString + ", " + courseDiffString + ", " + maxCourseDiffString
            fs.sendDebug(msg: msg)
            
            let speedString = String(format: "Speed: %.2f", speed)
            let speedCalcString = String(format: "Speed calc: %.2f", speedCalc)
            let speedAvgString = String(format: "Speed avg: %.2f", speedAvg)
            msg = speedString + ", " + speedCalcString + ", " + speedAvgString
            fs.sendDebug(msg: msg)
            fs.sendLocation(loc: locString)
            lastDebugUpdateTs = Date().timeIntervalSince1970
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {

            currentLocation = location
            if (homeLocation == nil) {
                setHome()
            }

            logGPSUpdateRate()

            if (isHome) {
                checkDeparture()
            } else {
                
                totalCount += 1
                let locString = String(format: "%.5f, %.5f", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude)
                tripUpdate(locString: locString)
                updateDistance()
                updateSpeed()
                checkTooFar(locString: locString)
                checkMotion(locString: locString)
                checkArrival()
            }

            
            lastLocation = currentLocation

            if (currentLocation.course >= 0.00001) {
                lastCourse = currentLocation.course
            }
            
            if (lastLocationForSpeedCalc == nil) {
                lastLocationForSpeedCalc = lastLocation
            }
        }
    }
    
    func updateDistance() {
        if let lastLocation = lastLocation {
            if (currentLocation.course >= 0.00001) {
                course = currentLocation.course
                let distance = currentLocation.distance(from: lastLocation)
                totalDistance += distance
                if (lastCourse >= 0.00001) {
                    courseDiff = abs(currentLocation.course - lastCourse)
                    if (courseDiff > maxCourseDiff) {
                        maxCourseDiff = courseDiff
                    }
                }
            }
            else {
                missedCourseCount += 1
            }
        }

        distanceFromHome = homeLocation!.distance(from: currentLocation)

    }
    
    
    func updateSpeed() {
        speed = currentLocation.speed * speedMultiplier
        let timeDiff = Date().timeIntervalSince(leftHomeTs)
        durationString = durationToString(durationInSeconds: timeDiff)
        if (timeDiff > 0.0001) {
            speedAvg = totalDistance / timeDiff
            speedAvg *= speedMultiplier
        }
        
        if let _lastLocationForSpeedCalc = lastLocationForSpeedCalc {
            
            let calendar = Calendar.current
            let components = calendar.dateComponents([.nanosecond], from: _lastLocationForSpeedCalc.timestamp, to: currentLocation.timestamp)
            let microseconds = components.nanosecond! / 1000
            if (Double(microseconds)/100000.0 >= Double(speedCalcUpdateIntervalSec)) {
                let lastLocationDistance = currentLocation.distance(from: _lastLocationForSpeedCalc)
                speedCalc = lastLocationDistance / Double(microseconds) * 1000000.0 * speedMultiplier
                lastLocationForSpeedCalc = currentLocation
            }
        }

    }
    
    func checkDeparture() {
        let _distanceFromHome = homeLocation!.distance(from: currentLocation)
        if (_distanceFromHome > departureProximity) {
            leftHomeTs = Date()
            isHome = false
            clearAll()
            distanceFromHome = _distanceFromHome
            fs.sendAlertNotification(msg: "Departure", type: "departure")
            fs.sendDebug(msg: "Departure")
        }
    }
    
    func checkArrival() {
        if (distanceFromHome < arrivalProximity) {
            isHome = true
            let duration = Date().timeIntervalSince(leftHomeTs)
            let msg = "Arrival. Duration:" + durationToString(durationInSeconds: duration)
            fs.sendAlertNotification(msg: msg, type: "arrival")
            fs.sendDebug(msg: msg)
        }
    }
    
    func checkMotion(locString: String) {
        if (currentLocation.speed > 0.2) {
            lastTimeMotionDetected = Date()
            stationaryAlertSent = false
        }
        else {
            let timeDiff = Date().timeIntervalSince(lastTimeMotionDetected)
            if (timeDiff >= Double(stationaryAlarmThresholdSec) && !stationaryAlertSent) {
                let msg = "Not moving. Location: " + locString
                fs.sendAlertNotification(msg: msg, type: "stationary")
                fs.sendDebug(msg: msg)
                stationaryAlertSent = true
                alertMsg = "NOT MOVING"
            }
        }

    }
    
    func checkTooFar(locString: String) {
        if (distanceFromHome > maxAllowedDistance && !tooFarAlertSent) {
            var msg = "Too far: " + String(distanceFromHome)
            msg += ", coords: " + locString;
            fs.sendAlertNotification(msg: msg, type: "tooFar")
            fs.sendDebug(msg: msg)
            tooFarAlertSent = true
            alertMsg = "TOO FAR"
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

