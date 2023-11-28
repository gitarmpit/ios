import SwiftUI
import Firebase

struct ContentView: View {
    
    @StateObject private var sharedData: SharedObservableData

    private var fsManager: FireStoreManager
    private var accManager: AccelerationManager
    private var locationManager: LocationManager

    init() {
        let sharedData = SharedObservableData()
        fsManager = FireStoreManager(sharedData: sharedData)
        accManager = AccelerationManager(sharedData: sharedData)
        locationManager = LocationManager(fs: fsManager, sharedData: sharedData)
        _sharedData = StateObject(wrappedValue: sharedData)
    }
    
    var body: some View {
        VStack {
            
            Text(sharedData.tripDurationString)
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

            if (sharedData.homeLocation != nil) {
                Text("To Home / Total:")
                    .font(.title)
                    .lineLimit(1)
                Text(String(format: "%10.2f   %10.2f", sharedData.distanceFromHome, sharedData.totalDistance))
                    .font(.title)
                    .lineLimit(1)
                    .padding()
            }
            
            Text(String(format: "max:%7.2f %7.2f %7.2f %7.2f", sharedData.maxAcX, sharedData.maxAcY, sharedData.maxAcZ, sharedData.maxAc))
                .padding()
            Text(String(format: "maxd:%7.2f %7.2f %7.2f %7.2f", sharedData.maxDiffAcZ, sharedData.maxDiffAcY, sharedData.maxDiffAcZ, sharedData.maxDiffTotal))
                .padding()

            //Text("acX: " + String(sharedData.acX))
            //Text("acY: " + String(sharedData.acY))
            //Text("acZ: " + String(sharedData.acZ))
            Text("accState: " + sharedData.accState)
                .padding()
            Text("Fs error:" + sharedData.firestoreError).foregroundColor(.red).padding()
             //   .padding()
            Text("GPS rate: "  + String(sharedData.GPS_updateRate))
        }
        .onAppear {
            //locationManager.fs = fsManager
            locationManager.startUpdatingLocation()
            accManager.startAccelerometer()
        }
        
    }
    
}

