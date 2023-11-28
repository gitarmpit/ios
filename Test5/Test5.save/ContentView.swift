import SwiftUI
import Firebase

struct ContentView: View {
    //@StateObject private var fsManager = FireStoreManager()
    //@StateObject private var accManager = AccelerationManager()
    //@StateObject private var locationManager = LocationManager()
    
    @StateObject private var fsManager: FireStoreManager
    @StateObject private var accManager: AccelerationManager
    @StateObject private var locationManager: LocationManager

    /*
    init() {
        //locationManager = LocationManager()
        //accManager = accManager()
        //locationManager.fs = fsManager
        _fsManager = StateObject(wrappedValue: FireStoreManager())
        _accManager = StateObject(wrappedValue: AccelerationManager())
        _locationManager = StateObject(wrappedValue: LocationManager(fs: fsManager))
    }
    */
    
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

            if (locationManager.homeLocation != nil) {
                Text("To Home / Total:")
                    .font(.title)
                    .lineLimit(1)
                Text(String(format: "%10.2f   %10.2f", locationManager.distanceFromHome, locationManager.totalDistance))
                    .font(.title)
                    .lineLimit(1)
                    .padding()
            }
            
            Text(String(format: "max:%7.2f %7.2f %7.2f %7.2f", accManager.maxAcX, accManager.maxAcY, accManager.maxAcZ, accManager.maxAc))
                .padding()
            Text(String(format: "maxd:%7.2f %7.2f %7.2f %7.2f", accManager.maxDiffAcZ, accManager.maxDiffAcY, accManager.maxDiffAcZ, accManager.maxDiffTotal))
                .padding()

            //Text("acX: " + String(accManager.acX))
            //Text("acY: " + String(accManager.acY))
            //Text("acZ: " + String(accManager.acZ))
            Text("accState: " + accManager.accState)
                .padding()
            Text("Fs error:" + fsManager.firestoreError).foregroundColor(.red).padding()
             //   .padding()
            Text("GPS rate: "  + String((locationManager.updateRate)))
        }
        .onAppear {
            //locationManager.fs = fsManager
            locationManager.startUpdatingLocation()
            accManager.startAccelerometer()
        }
        
    }
    
}

