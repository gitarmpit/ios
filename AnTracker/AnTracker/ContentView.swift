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
            Text(locationManager.durationString).padding()
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
            Text("Alert: " + locationManager.alertMsg).padding()
            HStack {
                VStack(alignment: .leading) {
                    Text("IsHome:")
                    Text("Distance from home:")
                    Text("Total distance:")
                    Text("Speed: ")
                    Text("Speed calc: ")
                    Text("Speed avg: ")
                    Text("Course:")
                    Text("Course diff:")
                    Text("Missed course:")
                    // Add more views for the left column as needed
                }
                
                Spacer() // Add spacing between the columns
                
                VStack(alignment: .trailing) {
                    Text(String(locationManager.isHome))
                    Text(String(Int(locationManager.distanceFromHome)))
                    Text(String(Int(locationManager.totalDistance)))
                    Text(String(format: "%6.2f", locationManager.speed))
                    Text(String(format: "%6.2f", locationManager.speedCalc))
                    Text(String(format: "%6.2f", locationManager.speedAvg))
                    Text(String(format: "%6.2f", locationManager.course))
                    Text(String(format: "%6.2f", locationManager.courseDiff))
                    Text(String(format: "%6d", locationManager.missedCourseCount))
                    // Add more views for the right column as needed
                }
            }.padding(50)
        }
        .onAppear {
            locationManager.startUpdatingLocation()
            //    accManager.startAccelerometer()
        }
        
    }
    
}

