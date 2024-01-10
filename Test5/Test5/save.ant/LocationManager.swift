import CoreLocation
import HealthKit
import UIKit

struct TripPoint {
    var latitude: Double
    var longitude: Double
    var speed: Double
    var speedAvg: Double
    var duration: String
    var distance: Double
}

class SpeedAverage {
    private var windowSize: Int
    private var values: [Double] = []
    
    var average: Double {
        return values.reduce(0, +) / Double(values.count)
    }
    
    init(windowSize: Int) {
        self.windowSize = windowSize
    }
    
    func isFull() -> Bool {
        return values.count == windowSize
    }
    
    func addValue(_ value: Double) {
        values.append(value)
        
        if values.count > windowSize {
            values.removeFirst()
        }
    }
    
    func reset() {
        values.removeAll()
    }
}

class GoodPointAverage {
    private var windowSize: Int
    private var values: [Int] = []
    
    var average: Double {
        return Double(values.reduce(0, +)) / Double(values.count)
    }
    
    init(windowSize: Int) {
        self.windowSize = windowSize
    }
    
    func isFull() -> Bool {
        return values.count == windowSize
    }
    
    func addValue(_ value: Int) {
        values.append(value)
        
        if values.count > windowSize {
            values.removeFirst()
        }
    }
    
    func reset() {
        values.removeAll()
    }
}


class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var status: String = ""
    @Published var totalDistance: CLLocationDistance = 0.0
    @Published var durationString: String = ""
    private var speed: Double = 0.0   //  m/s
    @Published var speedString = ""
    private var speedAvg: Double = 0.0 // m/s
    @Published var speedAvgString = ""
    @Published var stepCountString: String = ""
    private var stepCount: Int = 0
    
    @Published var isHome: Bool = true
    private var tooFarAlertSent: Bool = false
    private var speedSum: Double = 0.0
    private var totalCount: Int = 0
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
    
    private let isMph = false
    private var locationString: String = ""
    private var homeLocation: CLLocation
    private var lastLocation: CLLocation?
    private let locationManager = CLLocationManager()
    
    private let departureProximity: CLLocationDistance = 7.0
    private let arrivalProximity: CLLocationDistance =  5.0
    private let maxAllowedDistance: Double = 1500
    private var lastCourse: Int = -1
    private var leftHomeTs: Date = Date()
    
    private let tripLogUpdateInterval: TimeInterval = 10
    private var lastTripLogUpdateTs: TimeInterval = 0
    
    private var lastHeartbeatTs: TimeInterval = 0
    private var heartbeatUpdateInterval: TimeInterval = 3600
    
    private let mphMultiplier = 2.23693629
    private let kmhMultiplier = 3.6
    
    private let stationaryAlarmThresholdSec = 60
    private var lastTimeMotionDetected: Date = Date()
    private var stationaryAlertSent: Bool = false
    
    private var fs: FireStoreManager
    private var timer: Timer?
    private var dailyTimer: Timer?
    
    private let stepSize: Double = 0.6
    //private let stepSize: Double = 0.78
    
    private var sleepMode: Bool = true
    private var warmupCount: Int = 0
    
    private var speedMovingAvg: SpeedAverage = SpeedAverage(windowSize: 100)
    private var currentTripId: String = ""
    
    init (fs: FireStoreManager) {
        self.fs = fs
        self.homeLocation = forumLoc
        super.init()
        locationManager.delegate = self
    }
    
    func initLocationManager() {
        fs.sendDebug(msg: "Startup: initializing locationManager, starting sleep timer")
        let msg = String(format: "Home: %.8f, %.8f", homeLocation.coordinate.latitude, homeLocation.coordinate.longitude)
        fs.sendDebug(msg: msg)
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        //enterReducedPowerMode()
        //startTimer()
        //scheduleDailyTimer(hour: 9, fullpower: true)
        //scheduleDailyTimer(hour: 10, fullpower: false)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        fs.sendDebug(msg: "locationManagerDidChangeAuthorization fired")
        if (locationManager.authorizationStatus == .notDetermined) {
            fs.sendDebug(msg: "first time authorization: request when in use")
            locationManager.requestWhenInUseAuthorization()
        }
        else if (locationManager.authorizationStatus == .authorizedWhenInUse) {
            fs.sendDebug(msg: "location services: request always")
            locationManager.requestAlwaysAuthorization()
        }
        else if (locationManager.authorizationStatus == .authorizedAlways) {
            fs.sendDebug(msg: "location services: status=authorizedAlways, starting location service")
            enterFullPowerMode()
        }
        else {
            fs.sendDebug(msg: "location service: current auth status: " + String(locationManager.authorizationStatus.rawValue))
        }
    }
    
    func scheduleDailyTimer(hour: Int, fullpower: Bool) {
        fs.sendDebug(msg: "Scheduling timer at \(hour)")
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour], from: Date())
        let timeInterval: TimeInterval
        
        if hour <= components.hour!  {
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
            let targetDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: tomorrow)!
            timeInterval = targetDate.timeIntervalSinceNow
            fs.sendDebug(msg: "Scheduling for tomorrow in \(timeInterval/60) min")
        } else {
            let targetDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now)!
            timeInterval = targetDate.timeIntervalSinceNow
            fs.sendDebug(msg: "Scheduling for today in \(timeInterval/60) min")
        }
        
        dailyTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in
            if fullpower {
                self.enterFullPowerMode()
            } else {
                self.enterReducedPowerMode()
            }
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
            else if (components.hour == 12) {
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
        isHome = true
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
        locationString = ""
        totalDistance = 0.0
        distanceFromHome = 0.0
        durationString = durationToString(durationInSeconds: 0)
        course = -1
        courseDiff = 0
        maxCourseDiff = 0
        speed = 0.0
        speedString = ""
        speedSum = 0.0
        speedAvg = 0.0
        speedAvgString = ""
        totalCount = 0
        tooFarAlertSent = false
        lastCourse = -1
        leftHomeTs = Date()
        lastHeartbeatTs = 0
        lastTripLogUpdateTs = 0
        lastTimeMotionDetected = Date()
        stationaryAlertSent = false
        stepCount = 0
        stepCountString = ""
        validCourse = false
        invalidCourseCount = 0
        speedMovingAvg.reset()
        currentTripId = ""
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            
            if (!sleepMode && (warmupCount > 10))
            {
                update(location: location)
                if (isHome) {
                    checkDeparture(location: location)
                } else {
                    checkTooFar()
                    checkMotion()
                    checkArrival()
                }
            }
            else {
                warmupCount += 1
                if (sleepMode) {
                    heartbeat()
                }
            }
        }
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
            
            let msg = "heartbeat: battery: level=" + String(Int(batteryLevel*100.0)) + "%, state: " + batteryState
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
            
            speedString = speedToString(speed)
            speedAvgString = speedToString(speedAvg)
            fs.sendDebug(msg: "speed: " + speedString + ", avg: " + speedAvgString + ", m/s: " + String(format: "%.6f", speed))
            fs.sendDebug(msg: "validCourse: " + String(validCourse) + ", invalidCoureCount: " + String(invalidCourseCount))
            fs.sendDebug(msg: "stepCount: " + String(stepCount))
            fs.sendDebug(msg: "stepCount: " + String(stepCount))
            fs.sendLocation(loc: locationString)
            let tp = TripPoint(
                latitude: lastLocation!.coordinate.latitude,
                longitude: lastLocation!.coordinate.longitude,
                speed: speed,
                speedAvg: speedAvg,
                duration: durationString,
                distance: totalDistance)
            fs.addPointToTrip(tripId: currentTripId, seq: totalCount, point: tp)
            lastTripLogUpdateTs = Date().timeIntervalSince1970
        }
    }
    
    func calcCourse(location: CLLocation) {
        
        let tmpCourse = Int(location.course)
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
        
    }
    
    func update(location: CLLocation) {
        
        calcCourse(location: location)
        var currentSpeed = 0.0
        var distance = 0.0
        
        if (!isHome) {
            if (location.speed > 0.04 && lastLocation != nil) {
                distance = location.distance(from: lastLocation!)
                currentSpeed = location.speed
                locationString = String(format: "%.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude)
                lastLocation = location
                tripLog()
            }
            totalCount += 1
            speed = currentSpeed
            speedSum += speed
            speedMovingAvg.addValue(speed)
            speedAvg = speedSum / Double(totalCount)
            totalDistance += distance
            let duration = Date().timeIntervalSince(leftHomeTs)
            //speedAvg = totalDistance / duration * speedMultiplier
            durationString = durationToString(durationInSeconds: duration)
        }
        
        distanceFromHome = homeLocation.distance(from: location)
    }
    
    func checkDeparture(location: CLLocation) {
        let _distanceFromHome = homeLocation.distance(from: location)
        if (_distanceFromHome > departureProximity) {
            leftHomeTs = Date()
            isHome = false
            clearAll()
            distanceFromHome = _distanceFromHome
            lastLocation = location
            fs.sendAlertNotification(msg: "Departure", type: "departure")
            fs.sendDebug(msg: "Departure")
            currentTripId = generateTimeStamp()
            fs.addTrip(tripId: currentTripId)
            
        }
    }
    
    
    func checkArrival() {
        if (distanceFromHome < arrivalProximity) {
            isHome = true
            let duration = Date().timeIntervalSince(leftHomeTs)
            speedAvg = totalDistance / duration
            stepCount = Int(totalDistance / stepSize)
            stepCountString = String(format: "%5d", stepCount)
            speed = 0
            let distanceString = String(format: "%.1f", totalDistance)
            let speedAvgString = speedToString(speedAvg)
            let msg = "Arrival. Duration:" + durationString + ", Total distance: " + distanceString + ", Avg speed: " + speedAvgString
            fs.sendAlertNotification(msg: msg, type: "arrival")
            fs.sendDebug(msg: msg)
            fs.updateTrip(tripId: currentTripId, distance: totalDistance, speedAvg: speedAvg, duration: durationString)
        }
    }
    
    func speedToString(_ speed: Double) -> String {
        return isMph ?
            String(format: "%6.1f mph", speed*mphMultiplier) :
            String(format: "%6.1f km/h", speed*kmhMultiplier)
    }
    
    func checkMotion() {
        if (speed > 0.05) {
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
            }
        }
        
        let timeDiff = Date().timeIntervalSince(leftHomeTs)
        if (timeDiff > 120 && speedAvg < 0.55) {
            let msg = "Speed too slow"
            fs.sendAlertNotification(msg: msg, type: "stationary")
            fs.sendDebug(msg: msg)
            stationaryAlertSent = false
        }
        
    }
    
    func checkTooFar() {
        if (distanceFromHome > maxAllowedDistance && !tooFarAlertSent) {
            var msg = "Too far: " + String(distanceFromHome)
            msg += ", coords: " + locationString;
            fs.sendAlertNotification(msg: msg, type: "tooFar")
            fs.sendDebug(msg: msg)
            tooFarAlertSent = true
        }
    }
    
    func generateTimeStamp() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDateTime = Date()
        return dateFormatter.string(from: currentDateTime)
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

