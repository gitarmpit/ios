import SwiftUI
import Firebase

struct ContentView: View {
    //@StateObject private var fsManager = FireStoreManager()
    //@StateObject private var accManager = AccelerationManager()
    //@StateObject private var locationManager = LocationManager()
    
    @StateObject private var fsManager: FireStoreManager
    @StateObject private var accManager: AccelerationManager
    @StateObject private var locationManager: LocationManager
    
    init() {
        let fsManager = FireStoreManager()
        let accManager = AccelerationManager()
        let locationManager = LocationManager(fs: fsManager)
        
        _fsManager = StateObject(wrappedValue: fsManager)
        _accManager = StateObject(wrappedValue: accManager)
        _locationManager = StateObject(wrappedValue: locationManager)
    }
    
    var body: some View {
        VStack {
            
            Text(locationManager.durationString)
            Button(action: {
                locationManager.setHome()
            }) {
                Text("Home")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            /*
            Button(action: {
                accManager.clearAll()
            }) {
                Text("Clear ACC")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            */
            
            //Text("IsHome: " + String(locationManager.isHome))
            Text("To Home / Total:")
            Text(String(format: "%10.2f   %10.2f", locationManager.distanceFromHome, locationManager.totalDistance))
            Text("Speed/Calc/Avg:")
            Text(String(format: "%6.2f %6.2f %6.2f", locationManager.speed, locationManager.speedCalc,locationManager.speedAvg))
            Text("Course/diff/Max diff:")
            Text(String(format: "%6.2f %6.2f %6.2f", locationManager.course, locationManager.courseDiff, locationManager.maxCourseDiff))
            Text(String(format: "Total / missed: %5d %5d", locationManager.totalCount, locationManager.missedCourseCount))

            //Text(String(format: "max:%7.2f %7.2f %7.2f %7.2f", accManager.maxAcX, accManager.maxAcY, accManager.maxAcZ, accManager.maxAc))
            //    .padding()
            //Text(String(format: "maxd:%7.2f %7.2f %7.2f %7.2f", accManager.maxDiffAcZ, accManager.maxDiffAcY, accManager.maxDiffAcZ, accManager.maxDiffTotal))
            //    .padding()
            
            //Text("acX: " + String(accManager.acX))
            //Text("acY: " + String(accManager.acY))
            //Text("acZ: " + String(accManager.acZ))
            //Text("accState: " + accManager.accState)
            //    .padding()
            //Text("Fs error:" + fsManager.firestoreError).foregroundColor(.red).padding()
            //   .padding()
            //Text("GPS rate: "  + String((locationManager.updateRate)))
        }
        .onAppear {
            locationManager.startUpdatingLocation()
            accManager.startAccelerometer()
        }
        
    }
    
}

