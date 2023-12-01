import CoreLocation
import HealthKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var status: String = ""
    @Published var totalDistance: CLLocationDistance = 0.0
    @Published var durationString: String = ""
    @Published var speed: Double = 0.0
    @Published var speedAvg: Double = 0.0
    @Published var stepCount: Int = 0
    
    @Published var isHome: Bool = true
    private var tooFarAlertSent: Bool = false
    private var speedSum: Double = 0.0
    private var totalCount: Int = 0
    private var alertMsg: String = ""
    private var validCourse: Bool = false
    
    private    var course: Int = -1
    private    var courseDiff: Int = 0
    private    var maxCourseDiff: Int = 0
    private    var invalidCourseCount: Int = 0
    private var distanceFromHome: CLLocationDistance = 0.0
    
    private var currentLocation: CLLocation?
    private var locationString: String = ""
    private var homeLocation: CLLocation?
    private var lastLocation: CLLocation?
    private let locationManager = CLLocationManager()
    
    private let departureProximity: CLLocationDistance = 40.0
    private let arrivalProximity: CLLocationDistance = 25.0
    private let maxAllowedDistance: Double = 1500
    private var lastCourse: Int = -1
    private var leftHomeTs: Date = Date()
    
    private let logUpdateInterval: Double = 10
    
    // For ping and GPS rate calculation
    private let pingUpdateInterval: Double = 60
    private var lastPingTs: TimeInterval = 0
    private var gpsUpdateCnt: Int = 0
    // End of GPS rate calc
    
    // Debug update interval
    private var lastDebugUpdateTs: TimeInterval = 0
    
    private let mphMultiplier = 2.23693629
    private let kmhMultiplier = 3.6
    
    private let stationaryAlarmThresholdSec = 60
    private var lastTimeMotionDetected: Date = Date()
    private var stationaryAlertSent: Bool = false
    
    private let speedMultiplier: Double
    private var fs: FireStoreManager
    private var timer: Timer?
    private var GPS_Running: Bool = false
    
    init (fs: FireStoreManager) {
        self.fs = fs
        self.speedMultiplier = kmhMultiplier
        super.init()
        locationManager.delegate = self
    }
    
    func initLocationManager() {
        //startUpdatingLocation()
    }
    
    func clearAll()  {
        currentLocation = nil
        locationString = ""
        totalDistance = 0.0
        distanceFromHome = 0.0
        durationString = durationToString(durationInSeconds: 0)
        course = -1
        courseDiff = 0
        maxCourseDiff = 0
        speed = 0.0
        speedSum = 0.0
        speedAvg = 0.0
        totalCount = 0
        tooFarAlertSent = false
        lastLocation = nil
        lastCourse = -1
        leftHomeTs = Date()
        lastPingTs = 0
        gpsUpdateCnt = 0
        lastDebugUpdateTs = 0
        lastTimeMotionDetected = Date()
        stationaryAlertSent = false
        alertMsg = ""
        stepCount = 0
        validCourse = false
        invalidCourseCount = 0
    }
    
    func startUpdatingLocation() {
        GPS_Running = true
        clearAll()
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        //locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        //locationManager.distanceFilter = 10
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        GPS_Running = false
        locationManager.stopUpdatingLocation()
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            
            if (homeLocation == nil) {
                currentLocation = location
                setHome()
            }
            
            ping()
            update(location: location)
            
            if (isHome) {
                checkDeparture()
            } else {
                log()
                checkTooFar()
                checkMotion()
                checkArrival()
            }
            
            lastLocation = currentLocation
        }
    }
    
    func setHome() {
        homeLocation = currentLocation
        let msg = String(format: "Home: %.5f, %.5f", homeLocation!.coordinate.latitude, homeLocation!.coordinate.longitude)
        fs.sendDebug(msg: msg)
        clearAll()
    }
    
    func ping() {
        gpsUpdateCnt += 1
        let timeDiff = Date().timeIntervalSince1970 - lastPingTs
        if timeDiff >= pingUpdateInterval {
            let gpsUpdateRate = Double(gpsUpdateCnt) / Double(timeDiff)
            fs.sendDebug(msg: String(format: "GPS update rate: %.2f", gpsUpdateRate))
            lastPingTs = Date().timeIntervalSince1970
            gpsUpdateCnt = 0
        }
    }
    
    func log() {
        if (Date().timeIntervalSince1970 - lastDebugUpdateTs >= logUpdateInterval) {
            
            let fromHomeString = String(format: "Distance from home: %.2f", distanceFromHome)
            let totalDistanceString = String(format: "Total distance: %.2f", totalDistance)
            let courseString = String(format: "Course: %d", course)
            let courseDiffString = String(format: "CourseDiff: %d", courseDiff)
            let maxCourseDiffString = String(format: "MaxCourseDiff: %d", maxCourseDiff)
            
            var msg = fromHomeString + ", " + totalDistanceString + ", Trip duration: " + durationString + ", loc: " + locationString
            fs.sendDebug(msg: msg)
            
            msg = courseString + ", " + courseDiffString + ", " + maxCourseDiffString
            fs.sendDebug(msg: msg)
            
            let speedString = String(format: "Speed: %.2f", speed)
            let speedAvgString = String(format: "Speed avg: %.2f", speedAvg)
            msg = speedString + ", " + speedAvgString
            fs.sendDebug(msg: msg)
            fs.sendDebug(msg: "validCourse: " + String(validCourse) + ", invalidCoureCount: " + String(invalidCourseCount))
            fs.sendLocation(loc: locationString)
            lastDebugUpdateTs = Date().timeIntervalSince1970
        }
    }
    
    func update(location: CLLocation) {
        
        validCourse = false
        
        let tmpCourse = Int(location.course)
        // Course
        if (tmpCourse >= 0) {
            course = tmpCourse
            if (lastCourse >= 0) {
                courseDiff = abs(tmpCourse - lastCourse)
                if (courseDiff > maxCourseDiff) {
                    maxCourseDiff = courseDiff
                }
                validCourse = true
            }
            lastCourse = course
        }
        else {
            course = -1
            lastCourse = -1
        }
        
        if (!validCourse) {
            invalidCourseCount += 1
        }
        
        var currentSpeed = 0.0
        var distance = 0.0
        
        //if (validCourse) {
        locationString = String(format: "%.5f, %.5f", location.coordinate.latitude, location.coordinate.longitude)
        currentLocation = location
        if (!isHome && lastLocation != nil) {
            if (location.speed > 0.14) {
                distance = location.distance(from: lastLocation!)
                currentSpeed = location.speed * speedMultiplier
                //if (distance < 0.3) {
                //    distance = 0
                //}
                //else {
                //    currentSpeed = location.speed * speedMultiplier
                //}
            }
        }
        //}
        
        if (!isHome) {
            totalCount += 1
            speed = currentSpeed
            speedSum += speed
            speedAvg = speedSum / Double(totalCount)
            totalDistance += distance
            let duration = Date().timeIntervalSince(leftHomeTs)
            //speedAvg = totalDistance / duration * speedMultiplier
            durationString = durationToString(durationInSeconds: duration)
        }
        distanceFromHome = homeLocation!.distance(from: location)
    }
    
    func checkDeparture() {
        if (homeLocation != nil && currentLocation != nil) {
            let _distanceFromHome = homeLocation!.distance(from: currentLocation!)
            if (_distanceFromHome > departureProximity) {
                leftHomeTs = Date()
                isHome = false
                clearAll()
                distanceFromHome = _distanceFromHome
                //totalDistance = _distanceFromHome
                fs.sendAlertNotification(msg: "Departure", type: "departure")
                fs.sendDebug(msg: "Departure")
            }
        }
    }
    
    func checkArrival() {
        if (distanceFromHome < arrivalProximity) {
            isHome = true
            speed = 0
            let msg = "Arrival. Duration:" + durationString
            fs.sendAlertNotification(msg: msg, type: "arrival")
            fs.sendDebug(msg: msg)
        }
    }
    
    func checkMotion() {
        if (speed > 0.2) {
            lastTimeMotionDetected = Date()
            stationaryAlertSent = false
        }
        else {
            let timeDiff = Date().timeIntervalSince(lastTimeMotionDetected)
            if (timeDiff >= Double(stationaryAlarmThresholdSec) && !stationaryAlertSent) {
                let msg = "Not moving. Location: " + locationString
                fs.sendAlertNotification(msg: msg, type: "stationary")
                fs.sendDebug(msg: msg)
                stationaryAlertSent = true
                alertMsg = "NOT MOVING"
            }
        }
        
    }
    
    func checkTooFar() {
        if (distanceFromHome > maxAllowedDistance && !tooFarAlertSent) {
            var msg = "Too far: " + String(distanceFromHome)
            msg += ", coords: " + locationString;
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

