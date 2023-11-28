import Foundation
import CoreMotion

class AccelerationManager: NSObject, ObservableObject {
    
    private let motionManager = CMMotionManager()
    
    private var lastAcX: Double = 0.0
    private var lastAcY: Double = 0.0
    private var lastAcZ: Double = 0.0
    private var lastAc: Double = 0.0
    private let updateRateHz: Double = 10.0
    private let sharedData: SharedObservableData
    
    init(sharedData: SharedObservableData) {
        self.sharedData = sharedData
    }
    
    func clearAll() {
        lastAcX = 0
        lastAcY = 0
        lastAcZ = 0
        lastAc = 0
        sharedData.clearAcceleratorData()
    }
    
    func startAccelerometer() {
        clearAll()
 
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 1.0 / updateRateHz
            sharedData.accState = "initialized"
            motionManager.startAccelerometerUpdates(to: .main) { (data, error) in
                if let acceleration = data?.acceleration {
                    // Calculate the magnitude of the acceleration vector
                    let accelerationMagnitude = sqrt(pow(acceleration.x, 2) + pow(acceleration.y, 2) + pow(acceleration.z, 2))
                    
                    self.sharedData.acX = acceleration.x
                    self.sharedData.acY = acceleration.y
                    self.sharedData.acZ = acceleration.z
                    
                    // Define a threshold to determine motion
                    let motionThreshold: Double = 1.1
                    
                    // Check if the acceleration magnitude exceeds the threshold
                    if (accelerationMagnitude > motionThreshold) {
                        self.sharedData.accState = "moving"
                    }
                    else {
                        self.sharedData.accState = "stationary"
                    }
                    
                    if (abs(self.sharedData.acX) > abs(self.sharedData.maxAcX)) {
                        self.sharedData.maxAcX = self.sharedData.acX
                        //FireStoreManager.shared.sendAccelerationNotification(what: "maxX", val: String(acceleration.x))
                    }
                    
                    if (abs(self.sharedData.acY) > abs(self.sharedData.maxAcY)) {
                        self.sharedData.maxAcY = self.sharedData.acY
                        //FireStoreManager.shared.sendAccelerationNotification(what: "maxY", val: String(acceleration.y))
                    }
                    
                    if (abs(self.sharedData.acZ) > abs(self.sharedData.maxAcZ)) {
                        self.sharedData.maxAcZ = self.sharedData.acZ
                        //FireStoreManager.shared.sendAccelerationNotification(what: "maxZ", val: String(acceleration.z))
                    }
                    
                    if (accelerationMagnitude > self.sharedData.maxAc) {
                        self.sharedData.maxAc = accelerationMagnitude
                        //FireStoreManager.shared.sendAccelerationNotification(what: "maxMag", val: String(accelerationMagnitude))
                    }
                    
                    let diffX = abs(self.lastAcX - self.sharedData.acX)
                    if (diffX > self.sharedData.maxDiffAcX) {
                        self.sharedData.maxDiffAcX = diffX
                        //FireStoreManager.shared.sendAccelerationNotification(what: "maxDiffX", val: String(diffX))
                    }
                    let diffY = abs(self.lastAcY - self.sharedData.acY)
                    if (diffY > self.sharedData.maxDiffAcY) {
                        self.sharedData.maxDiffAcY = diffY
                        //FireStoreManager.shared.sendAccelerationNotification(what: "maxDiffY", val: String(diffY))
                    }
                    let diffZ = abs(self.lastAcZ - self.sharedData.acZ)
                    if (diffZ > self.sharedData.maxDiffAcZ) {
                        self.sharedData.maxDiffAcZ = diffZ
                        //FireStoreManager.shared.sendAccelerationNotification(what: "maxDiffZ", val: String(diffZ))
                    }

                    let diffTotal = self.lastAc - accelerationMagnitude
                    if (diffTotal > self.sharedData.maxDiffTotal) {
                        self.sharedData.maxDiffTotal = diffTotal
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
            sharedData.accState = "not available"
        }
    }
}
