import SwiftUI
import Firebase


struct ContentView: View {
    
    @StateObject private var fsManager: FireStoreManager
    //@StateObject private var accManager: AccelerationManager
    @StateObject private var locationManager: LocationManager
    
    private var fgColor: Color {
        locationManager.isRunning ? Color (red: 0, green: 130/255, blue: 153/255) : .black
    }
    
    init() {
        let fsManager = FireStoreManager()
        //let accManager = AccelerationManager()
        let locationManager = LocationManager(fs: fsManager)
        
        _fsManager = StateObject(wrappedValue: fsManager)
        //_accManager = StateObject(wrappedValue: accManager)
        _locationManager = StateObject(wrappedValue: locationManager)
        UIDevice.current.isBatteryMonitoringEnabled = true
    }
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            VStack {
                VStack {
                    Button(action: {
                        locationManager.startStopTrip()
                    }) {
                        Text(locationManager.buttonAction)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                    
                    Text("Time:")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text(locationManager.durationString)
                        .font(.system(size: 40))
                        .fontWeight(.bold)
                        .foregroundColor(fgColor)
                }
                .padding(.bottom)
                VStack {
                    Text("Distance:")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text(String(format: "%6.3f km", locationManager.totalDistance/1000))
                        .font(.system(size: 40))
                        .fontWeight(.bold)
                        .foregroundColor(fgColor)
                }
                .padding(.bottom)
                VStack {
                    Text("Speed:")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text(String(format: "%6.1f km/h", locationManager.speed))
                        .font(.system(size: 40))
                        .fontWeight(.bold)
                        .foregroundColor(fgColor)
                }
                .padding(.bottom)
                VStack {
                    Text("Avg Speed:")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text(String(format: "%6.1f km/h", locationManager.speedAvg))
                        .font(.system(size: 40))
                        .fontWeight(.bold)
                        .foregroundColor(fgColor)
                }
                .padding(.bottom)
                VStack {
                    Text("Steps:")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text(String(locationManager.stepCount))
                        .font(.system(size: 40))
                        .fontWeight(.bold)
                        .foregroundColor(fgColor)
                }
            }
        }
        .onAppear {
            //    accManager.startAccelerometer()
        }
        .onDisappear() {
            locationManager.stop()
        }
        
    }
}

