import CoreLocation
import HealthKit
import UIKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var status: String = ""
    @Published var totalDistance: CLLocationDistance = 0.0
    @Published var durationString: String = ""
    @Published var speed: Double = 0.0
    @Published var speedAvg: Double = 0.0
    @Published var stepCountString: String = ""
    private var stepCount: Int = 0
    
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
    
    // Home
    //39.983344275471424, -86.05587089869636
    private var forumLoc:  CLLocation = CLLocation(latitude: 39.983344275471424, longitude: -86.05587089869636)
    
    //Grosbeak
    //39.98023367094937, -86.05629468772058
    private var grosbeakLoc:  CLLocation = CLLocation(latitude: 39.98023367094937, longitude: -86.05629468772058)
    
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
    
    private let tripLogUpdateInterval: TimeInterval = 2
    private var lastTripLogUpdateTs: TimeInterval = 0
    
    private var lastHeartbeatTs: TimeInterval = 0
    private var heartbeatUpdateInterval: TimeInterval = 3600
    
    private let mphMultiplier = 2.23693629
    private let kmhMultiplier = 3.6
    
    private let stationaryAlarmThresholdSec = 60
    private var lastTimeMotionDetected: Date = Date()
    private var stationaryAlertSent: Bool = false
    
    private let speedMultiplier: Double
    private var fs: FireStoreManager
    private var timer: Timer?
    private var dailyTimer: Timer?
    
    //private let stepSize: Double = 0.6
    private let stepSize: Double = 0.78
    
    private var sleepMode: Bool = true
    private var warmupCount: Int = 0
    
    init (fs: FireStoreManager) {
        self.fs = fs
        //self.speedMultiplier = kmhMultiplier
        self.speedMultiplier = mphMultiplier
        super.init()
        locationManager.delegate = self
        homeLocation = forumLoc
    }
    
    func initLocationManager() {
        fs.sendDebug(msg: "Startup: initializing locationManager, starting sleep timer")
        let msg = String(format: "Home: %.8f, %.8f", homeLocation!.coordinate.latitude, homeLocation!.coordinate.longitude)
        fs.sendDebug(msg: msg)
        locationManager.requestWhenInUseAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        //enterFullPowerMode()
        enterReducedPowerMode()
        startTimer()
        scheduleDailyTimer(hour: 7, fullpower: true)
        scheduleDailyTimer(hour: 10, fullpower: false)
    }
    
    func scheduleDailyTimer(hour: Int, fullpower: Bool) {
        fs.sendDebug(msg: "scheduling timer at " + String(hour))
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour], from: Date())
        let timeInterval: TimeInterval
        if (components.hour! < hour) {
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
            let targetDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: tomorrow)!
            timeInterval = targetDate.timeIntervalSinceNow
            fs.sendDebug(msg: "scheduling for tomorrow in: " + String(timeInterval) + " seconds")
        }
        else {
            let targetDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now)!
            timeInterval = targetDate.timeIntervalSinceNow
            fs.sendDebug(msg: "scheduling for today in: " + String(timeInterval) + " seconds")
        }
        
        dailyTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in
            if (fullpower) {
                self.enterFullPowerMode()
            }
            else {
                self.enterReducedPowerMode()
            }
            self.scheduleDailyTimer(hour: hour, fullpower: fullpower)
        }
        
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { timer in
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour], from: Date())
            self.fs.sendDebug(msg: "timer")
            self.heartbeat()
            if (components.hour == 9) {
                self.enterFullPowerMode()
            }
            else if (components.hour == 15) {
                self.enterReducedPowerMode()
            }
        }
        //RunLoop.current.add(timer, forMode: .common)
    }
    
    func enterReducedPowerMode() {
        sleepMode = true
        isHome = true
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced
        self.locationManager.startUpdatingLocation()
        self.fs.sendDebug(msg: "Entering reduced power mode")
    }
    
    func enterFullPowerMode() {
        clearAll()
        sleepMode = false
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        warmupCount = 0
        locationManager.startUpdatingLocation()
        self.fs.sendDebug(msg: "Entering full power mode")
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didVisit visit: CLVisit) {
        self.fs.sendDebug(msg: "visit:" + visit.description)
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
        lastHeartbeatTs = 0
        lastTripLogUpdateTs = 0
        lastTimeMotionDetected = Date()
        stationaryAlertSent = false
        alertMsg = ""
        stepCount = 0
        stepCountString = ""
        validCourse = false
        invalidCourseCount = 0
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            
            if (!sleepMode && (warmupCount > 10))
            {
                update(location: location)
                if (isHome) {
                    checkDeparture()
                } else {
                    tripLog()
                    checkTooFar()
                    checkMotion()
                    checkArrival()
                }
                
                lastLocation = currentLocation
            }
            else {
                warmupCount += 1
            }
            
            heartbeat()
        }
    }
    
    func setHome() {
        homeLocation = currentLocation
        let msg = String(format: "Home: %.6f, %.6f", homeLocation!.coordinate.latitude, homeLocation!.coordinate.longitude)
        fs.sendDebug(msg: msg)
        clearAll()
    }
    
    func heartbeat() {
        let timeDiff = Date().timeIntervalSince1970 - lastHeartbeatTs
        if timeDiff >= heartbeatUpdateInterval {
            lastHeartbeatTs = Date().timeIntervalSince1970
            let batteryLevel = UIDevice.current.batteryLevel
            var batteryState = "???"
            if (UIDevice.current.batteryState == .unplugged) {
                batteryState = "unplugged"
            }
            else if (UIDevice.current.batteryState == .charging) {
                batteryState = "charging"
            }
            else if (UIDevice.current.batteryState == .full) {
                batteryState = "full"
            }
            
            var msg = "heartbeat: battery: level=" + String(batteryLevel*100.0) + "%, state: " + batteryState
            
            if (sleepMode) {
                msg += ", sleep mode"
            }
            else {
                msg += ", loc: " + locationString
            }
            fs.sendDebug(msg: msg)
        }
    }
    
    func tripLog() {
        if (Date().timeIntervalSince1970 - lastTripLogUpdateTs >= tripLogUpdateInterval) {
            
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
            fs.sendDebug(msg: "stepCount: " + String(stepCount))
            fs.sendLocation(loc: locationString)
            lastTripLogUpdateTs = Date().timeIntervalSince1970
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
        locationString = String(format: "%.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude)
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
            let duration = Date().timeIntervalSince(leftHomeTs)
            speedAvg = totalDistance / duration * speedMultiplier
            stepCount = Int(totalDistance / stepSize)
            stepCountString = String(format: "%5d", stepCount)
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

