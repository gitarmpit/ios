import CoreLocation
import HealthKit
import UIKit


class SpeedAverage {
    private var windowSize: Int
    private var values: [Double] = []
    
    var average: Double {
        return values.reduce(0, +) / Double(values.count)
    }
    
    init(windowSize: Int) {
        self.windowSize = windowSize
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

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var isRunning: Bool = false
    @Published var buttonAction: String = ""
    @Published var totalDistance: CLLocationDistance = 0.0
    @Published var durationString: String = ""
    @Published var speed: Double = 0.0
    @Published var speedAvg: Double = 0.0
    @Published var stepCount: Int = 0
    
    private var speedSum: Double = 0.0
    private var totalCount: Int = 0
    
    private var currentLocation: CLLocation?
    private var locationString: String = ""
    private var lastLocation: CLLocation?
    private let locationManager = CLLocationManager()
    
    private var leftHomeTs: Date = Date()
    
    private let mphMultiplier = 2.23693629
    private let kmhMultiplier = 3.6
    
    private let speedMultiplier: Double
    private var fs: FireStoreManager
    
    //private let stepSize: Double = 0.6
    private let stepSize: Double = 0.78
    
    private let tripLogUpdateInterval: TimeInterval = 1
    private var lastTripLogUpdateTs: TimeInterval = 0
    
    private let speedMovingAvg: SpeedAverage = SpeedAverage(windowSize: 5)
    
    init (fs: FireStoreManager) {
        self.fs = fs
        self.speedMultiplier = kmhMultiplier
        super.init()
        locationManager.delegate = self
        fs.sendDebug(msg: "Startup: initializing locationManager, starting sleep timer")
        locationManager.requestWhenInUseAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        isRunning = false
        setButtonAction()
        clearAll()
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.startUpdatingLocation()
    }
    
    func setButtonAction() {
        buttonAction = isRunning ? "Stop" : "Start"
    }
    
    func startStopTrip() {
        if (isRunning) {
            isRunning = false
            let duration = Date().timeIntervalSince(leftHomeTs)
            speedAvg = totalDistance / duration * speedMultiplier
            self.fs.sendDebug(msg: "Arrival")
        }
        else {
            isRunning = true
            clearAll()
            self.fs.sendDebug(msg: "Departure")
        }
        setButtonAction()
    }
    
    func stop() {
        
        // locationManager.stopUpdatingLocation()
    }
    
    func clearAll()  {
        currentLocation = nil
        locationString = ""
        totalDistance = 0.0
        durationString = durationToString(durationInSeconds: 0)
        speed = 0.0
        speedSum = 0.0
        speedAvg = 0.0
        totalCount = 0
        lastLocation = nil
        leftHomeTs = Date()
        stepCount = 0
        speedMovingAvg.reset()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            
            if (isRunning) {
                update(location: location)
                lastLocation = currentLocation
            }
        }
    }
    
    
    func tripLog() {
        if (Date().timeIntervalSince1970 - lastTripLogUpdateTs >= tripLogUpdateInterval) {
            
            let totalDistanceString = String(format: "Total distance: %.2f", totalDistance)
            
            var msg = totalDistanceString + ", Trip duration: " + durationString + ", loc: " + locationString
            fs.sendDebug(msg: msg)
            
            let speedString = String(format: "Speed: %.2f", speed)
            let speedAvgString = String(format: "Speed avg: %.2f", speedAvg)
            msg = speedString + ", " + speedAvgString
            fs.sendDebug(msg: msg)
            fs.sendDebug(msg: "stepCount: " + String(stepCount))
            fs.sendLocation(loc: locationString)
            lastTripLogUpdateTs = Date().timeIntervalSince1970
        }
    }

    func update(location: CLLocation) {
        
        var currentSpeed = 0.0
        var distance = 0.0

        locationString = String(format: "%.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude)
        currentLocation = location

        var doLog = false
        if (lastLocation != nil) && (location.speed > 0.15) {
            distance = location.distance(from: lastLocation!)
            currentSpeed = location.speed * speedMultiplier
            doLog = true
        }
        
        totalCount += 1
        speed = currentSpeed
        speedSum += speed
        speedAvg = speedSum / Double(totalCount)
        totalDistance += distance
        let duration = Date().timeIntervalSince(leftHomeTs)
        //speedAvg = totalDistance / duration * speedMultiplier
        durationString = durationToString(durationInSeconds: duration)
        stepCount = Int(totalDistance / stepSize)

        if (doLog) {
            tripLog()
        }
    }

    
  
    func update2(location: CLLocation) {
        
        var distance = 0.0

        var tmpSpeed = location.speed
        if (tmpSpeed < 0.2) {
            tmpSpeed = 0
        }
        speedMovingAvg.addValue(tmpSpeed)
        tmpSpeed = speedMovingAvg.average
        
        locationString = String(format: "%.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude)
        currentLocation = location
        if (lastLocation != nil) && (tmpSpeed > 0.2) {
            distance = location.distance(from: lastLocation!)
        }
        
        totalCount += 1
        speed = tmpSpeed * speedMultiplier
        speedSum += speed
        speedAvg = speedSum / Double(totalCount)
        totalDistance += distance
        let duration = Date().timeIntervalSince(leftHomeTs)
        //speedAvg = totalDistance / duration * speedMultiplier
        durationString = durationToString(durationInSeconds: duration)
        stepCount = Int(totalDistance / stepSize)
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

