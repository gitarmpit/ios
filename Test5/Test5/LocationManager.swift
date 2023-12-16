import CoreLocation
import HealthKit
import UIKit

struct TripPoint {
    var latitude: Double
    var longitude: Double
    var speed: Double
    var speedAvg: Double
    var duration: Int
    var distance: Double
}


class SpeedAverage {
    private var windowSize: Int
    private var values: [Double] = []
    
    var average: Double {
        return values.reduce(0, +) / Double(values.count)
    }
    
    var isFull: Bool {
        return values.count == windowSize
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

class DistanceBuffer {
    private var windowSize: Int
    private var values: [Double] = []
    
    var sum: Double {
        return values.reduce(0, +)
    }

    var average: Double {
        return values.reduce(0, +) / Double(values.count)
    }

    var isFull: Bool {
        return values.count == windowSize
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

class LocationBuffer {
    private var windowSize: Int
    private var values: [CLLocation] = []
    
    var isFull: Bool {
        return values.count == windowSize
    }
    
    var distance: Double {
        return values.count > 0 ? values[0].distance(from: values[values.count-1]) : 0
    }
    
    init(windowSize: Int) {
        self.windowSize = windowSize
    }
    
    func addValue(_ value: CLLocation) {
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
    @Published var status: String = ""
    private var totalDistance: CLLocationDistance = 0.0
    @Published var durationString: String = ""
    private var duration: Double = 0.0
    private var speed: Double = 0.0   //  m/s
    @Published var speedString = ""
    private var speedAvg: Double = 0.0 // m/s
    @Published var speedAvgString = ""
    @Published var stepCount: Int = 0
    @Published var paceAvgString: String = ""
    @Published var distanceString: String = ""
    
    private var speedSum: Double = 0.0
    private var totalCount: Int = 0
    private var badPointsCount: Int = 0
    private var currentLocation: CLLocation?
    private var locationString: String = ""
    private var lastLocation: CLLocation?
    private let locationManager = CLLocationManager()
    
    private var leftHomeTs: Date = Date()
    
    private let mphMultiplier = 2.23693629
    private let kmhMultiplier = 3.6
    
    private var fs: FireStoreManager = FireStoreManager()
    
    //private let stepSize: Double = 0.6
    private let stepSize: Double = 0.78
    
    private let tripLogUpdateInterval: TimeInterval = 10
    private var lastTripLogUpdateTs: TimeInterval = 0
    
    private let speedMovingAvg: SpeedAverage = SpeedAverage(windowSize: 10)
    private let distanceBuffer: DistanceBuffer = DistanceBuffer(windowSize: 10)
    private let locationBuffer: LocationBuffer = LocationBuffer(windowSize: 10)
    //private let isMph = false
    private var currentTripId: String = ""
    private var warmupCount: Int = 0
    
    override init () {
        super.init()
        locationManager.delegate = self
        fs.sendDebug(msg: "Startup: initializing locationManager, starting sleep timer")
        let isMph = UserDefaults.standard.bool(forKey: "isMph")
        fs.sendDebug(msg: "isMph: \(isMph)")
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        isRunning = false
        setButtonAction()
        clearAll()
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.startUpdatingLocation()
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
            fs.sendDebug(msg: "location services: status=authorizedAlways")
        }
        else {
            fs.sendDebug(msg: "location service: current auth status: " + String(locationManager.authorizationStatus.rawValue))
        }
    }
    
    func start() {
        clearAll()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.startUpdatingLocation()
        self.fs.sendDebug(msg: "Start updating location")
    }
    
    func stop() {
        locationManager.stopUpdatingLocation()
    }
    
    func setButtonAction() {
        buttonAction = isRunning ? "Stop" : "Start"
    }
    
    func startStopTrip() {
        if (isRunning) {
            isRunning = false
            speedAvg = totalDistance / duration
            if (speedAvg > 0.1) {
                let pace = duration / totalDistance
                paceAvgString = durationToString(durationInSeconds: pace)
            }
            
            self.fs.sendDebug(msg: "Arrival")
            
            let speedAvgString = speedToString(speedAvg)
            let msg = "Arrival. Duration:" + durationString + ", Total distance: " + distanceString + ", Avg speed: " + speedAvgString
            fs.sendDebug(msg: msg)
            fs.sendDebug(msg: "Total points: \(totalCount), bad points: \(badPointsCount)")
            fs.updateTrip(tripId: currentTripId, distance: totalDistance, speedAvg: speedAvg, duration: Int(duration))
            stop()
        }
        else {
            isRunning = true
            start()
            self.fs.sendDebug(msg: "Departure")
            currentTripId = generateTimeStamp()
            fs.addTrip(tripId: currentTripId,
                       lat: currentLocation!.coordinate.latitude,
                       long: currentLocation!.coordinate.longitude)
        }
        setButtonAction()
    }
    
    func clearAll()  {
        locationString = ""
        totalDistance = 0.0
        durationString = durationToString(durationInSeconds: 0)
        speed = 0.0
        speedString = ""
        speedSum = 0.0
        speedAvg = 0.0
        speedAvgString = ""
        totalCount = 0
        leftHomeTs = Date()
        lastTripLogUpdateTs = 0
        stepCount = 0
        speedMovingAvg.reset()
        distanceBuffer.reset()
        locationBuffer.reset()
        currentTripId = ""
        badPointsCount = 0
        warmupCount = 0
        paceAvgString = ""
        distanceString = ""
        lastLocation = nil
        duration = 0.0
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            if (warmupCount > 2) {
                if (isRunning) {
                    update(location: location)
                }
            }
            else {
                warmupCount += 1
            }
            currentLocation = location
        }
    }
    
    
    func tripLog(location: CLLocation) {
        if (tripLogUpdateInterval == 1 || ((Date().timeIntervalSince1970 - lastTripLogUpdateTs) >= tripLogUpdateInterval)) {
            
            let totalDistanceString = String(format: "Total distance: %.2f", totalDistance)
            
            let msg = totalDistanceString + ", Trip duration: " + durationString + ", loc: " + locationString
            fs.sendDebug(msg: msg)
            fs.sendDebug(msg: "speed: " + speedString + ", avg: " + speedAvgString + ", m/s: " + String(format: "%.6f", speed))
            fs.sendDebug(msg: "stepCount: " + String(stepCount))
            fs.sendDebug(msg: "totalCount: \(totalCount), bad count: \(badPointsCount)")
            
            let tp = TripPoint(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                speed: speed,
                speedAvg: speedAvg,
                duration: Int(duration),
                distance: totalDistance)
            fs.addPointToTrip(tripId: currentTripId, seq: totalCount, point: tp)
            
            lastTripLogUpdateTs = Date().timeIntervalSince1970
        }
    }

    func update(location: CLLocation) {
        
        locationString = String(format: "%.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude)
        if (lastLocation == nil) {
            lastLocation = location
            return
        }
        
        var goodPoint = true
        
        var currentSpeed = location.speed
        var distance = 0.0
        if currentSpeed < 0.04 {
            //fs.sendDebug(msg: "speed<0.04")
            goodPoint = false
        }

        distance = location.distance(from: lastLocation!)
        if (distanceBuffer.isFull && distance > distanceBuffer.average*10) {
            //fs.sendDebug(msg: "Jumped too far: \(distance)")
            //goodPoint = false
        }
        
        if totalCount > 0 && locationBuffer.distance < 4 {
            //fs.sendDebug(msg: "locationBuffer: distance traveled < 4 ")
            goodPoint = false
        }

        duration = Date().timeIntervalSince(leftHomeTs)
        durationString = durationToString(durationInSeconds: duration)

        /*
        if duration > 30 && speedAvg < 0.2 {
            fs.sendDebug(msg: "speedAvg < 0.2")
            goodPoint = false
        }
        if speedMovingAvg.isFull && speedMovingAvg.average < 0.2 {
            fs.sendDebug(msg: "moving average < 0.2")
            goodPoint = false
        }
        */
        
        if !goodPoint {
            badPointsCount += 1
            currentSpeed = 0
            distance = 0
        }
        
        totalCount += 1
        speed = currentSpeed
        speedSum += speed
        if (duration < 60) {
            speedAvg = speedSum / Double(totalCount)
        }
        else {
            speedAvg = totalDistance / duration
        }
        speedString = speedToString(speed)
        speedAvgString = speedToString(speedAvg)
        speedMovingAvg.addValue(speed)
        distanceBuffer.addValue(distance)
        totalDistance += distance
        let isMph = UserDefaults.standard.bool(forKey: "isMph")
        if (isMph) {
            distanceString = String(format: "%6.3f mi", totalDistance*0.000621371)
        } else {
            distanceString = String(format: "%6.3f km", totalDistance*0.001)
        }
        stepCount = Int(totalDistance / stepSize)
        locationBuffer.addValue(location)
        if (totalDistance > 0) {
            let pace = duration / (totalDistance*0.000621371)
            paceAvgString = durationToString(durationInSeconds: pace)
        }

        if (goodPoint) {
            tripLog(location: location)
            lastLocation = location
        }
        
    }
    
    func speedToString(_ speed: Double) -> String {
        let isMph = UserDefaults.standard.bool(forKey: "isMph")
        return isMph ?
        String(format: "%6.1f mph", speed*mphMultiplier) :
        String(format: "%6.1f km/h", speed*kmhMultiplier)
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
    
    func generateTimeStamp() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDateTime = Date()
        return dateFormatter.string(from: currentDateTime)
    }
    
}

