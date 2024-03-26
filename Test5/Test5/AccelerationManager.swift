import Foundation
import CoreMotion

class AccelerationManager: ObservableObject {
    
    private let motionManager = CMMotionManager()
    @Published var accState: String = "???"
    @Published var acX: Double = 0.0
    @Published var acY: Double = 0.0
    @Published var acZ: Double = 0.0
    
    private var lastAcX: Double = 0.0
    private var lastAcY: Double = 0.0
    private var lastAcZ: Double = 0.0

    @Published var maxAcX: Double = 0.0
    @Published var maxAcY: Double = 0.0
    @Published var maxAcZ: Double = 0.0

    private var lastAc: Double = 0.0
    @Published var maxAc: Double = 0.0
    
    @Published var maxDiffAcX: Double = 0.0
    @Published var maxDiffAcY: Double = 0.0
    @Published var maxDiffAcZ: Double = 0.0
    @Published var maxDiffTotal: Double = 0.0
    
    private let updateRateHz: Double = 10.0

    func clearAll() {
        acX = 0
        acY = 0
        acZ = 0
        lastAcX = 0
        lastAcY = 0
        lastAcZ = 0
        maxAcX = 0
        maxAcY = 0
        maxAcZ = 0
        lastAc = 0
        maxAc = 0
        maxDiffAcX = 0
        maxDiffAcY = 0
        maxDiffAcZ = 0
        maxDiffTotal = 0
    }
    
    func startAccelerometer() {
        clearAll()
 
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 1.0 / updateRateHz
            accState = "initialized"
            motionManager.startAccelerometerUpdates(to: .main) { (data, error) in
                if let acceleration = data?.acceleration {
                    // Calculate the magnitude of the acceleration vector
                    let accelerationMagnitude = sqrt(pow(acceleration.x, 2) + pow(acceleration.y, 2) + pow(acceleration.z, 2))
                    
                    self.acX = acceleration.x
                    self.acY = acceleration.y
                    self.acZ = acceleration.z
                    
                    // Define a threshold to determine motion
                    let motionThreshold: Double = 1.1
                    
                    // Check if the acceleration magnitude exceeds the threshold
                    if (accelerationMagnitude > motionThreshold) {
                        self.accState = "moving"
                    }
                    else {
                        self.accState = "stationary"
                    }
                    
                    if (abs(self.acX) > abs(self.maxAcX)) {
                        self.maxAcX = self.acX
                        //FireStoreManager.shared.sendAccelerationNotification(what: "maxX", val: String(acceleration.x))
                    }
                    
                    if (abs(self.acY) > abs(self.maxAcY)) {
                        self.maxAcY = self.acY
                        //FireStoreManager.shared.sendAccelerationNotification(what: "maxY", val: String(acceleration.y))
                    }
                    
                    if (abs(self.acZ) > abs(self.maxAcZ)) {
                        self.maxAcZ = self.acZ
                        //FireStoreManager.shared.sendAccelerationNotification(what: "maxZ", val: String(acceleration.z))
                    }
                    
                    if (accelerationMagnitude > self.maxAc) {
                        self.maxAc = accelerationMagnitude
                        //FireStoreManager.shared.sendAccelerationNotification(what: "maxMag", val: String(accelerationMagnitude))
                    }
                    
                    let diffX = abs(self.lastAcX - self.acX)
                    if (diffX > self.maxDiffAcX) {
                        self.maxDiffAcX = diffX
                        //FireStoreManager.shared.sendAccelerationNotification(what: "maxDiffX", val: String(diffX))
                    }
                    let diffY = abs(self.lastAcY - self.acY)
                    if (diffY > self.maxDiffAcY) {
                        self.maxDiffAcY = diffY
                        //FireStoreManager.shared.sendAccelerationNotification(what: "maxDiffY", val: String(diffY))
                    }
                    let diffZ = abs(self.lastAcZ - self.acZ)
                    if (diffZ > self.maxDiffAcZ) {
                        self.maxDiffAcZ = diffZ
                        //FireStoreManager.shared.sendAccelerationNotification(what: "maxDiffZ", val: String(diffZ))
                    }

                    let diffTotal = self.lastAc - accelerationMagnitude
                    if (diffTotal > self.maxDiffTotal) {
                        self.maxDiffTotal = diffTotal
                        //FireStoreManager.shared.sendAccelerationNotification(what: "maxDiffTotal", val: String(diffTotal))
                    }

                    self.lastAcX = acceleration.x
                    self.lastAcY = acceleration.y
                    self.lastAcZ = acceleration.z
                    self.lastAc = accelerationMagnitude
                 
                }
            }
        }
        else {
            accState = "not available"
        }
    }
}
