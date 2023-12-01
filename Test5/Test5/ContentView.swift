import SwiftUI
import Firebase

struct ContentView: View {
    
    @StateObject private var fsManager: FireStoreManager
    //@StateObject private var accManager: AccelerationManager
    @StateObject private var locationManager: LocationManager
    
    private var fgColor: Color {
        locationManager.isHome ? .black : Color (red: 0, green: 130/255, blue: 153/255) // Color(red: 0, green: 0, blue: 0.4)
    }

    init() {
        let fsManager = FireStoreManager()
        //let accManager = AccelerationManager()
        let locationManager = LocationManager(fs: fsManager)
        
        _fsManager = StateObject(wrappedValue: fsManager)
        //_accManager = StateObject(wrappedValue: accManager)
        _locationManager = StateObject(wrappedValue: locationManager)
    }
    
    var body: some View {
        VStack {
            VStack {
                Text("Time:")
                    .font(.system(size: 40))
                //.fontWeight(.bold)
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
                //.fontWeight(.bold)
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
                //.fontWeight(.bold)
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
                //.fontWeight(.bold)
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
                //.fontWeight(.bold)
                    .foregroundColor(.gray)
                Text(String(format: "%5d", locationManager.stepCount))
                    .font(.system(size: 40))
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                //Text("Status: " + locationManager.status)
            }
            //Spacer()
        }
        .onAppear {
            locationManager.initLocationManager()
            //    accManager.startAccelerometer()
        }
        
    }
    func fontSizeFor10Characters() -> CGFloat {
        let numberOfCharacters = 10
        let screenWidth = UIScreen.main.bounds.size.width
        let maxWidthPercentage: CGFloat = 0.8 // Adjust this value to control the maximum width of the text
        let availableWidth = screenWidth * maxWidthPercentage
        let desiredWidthPerCharacter = availableWidth / CGFloat(numberOfCharacters)
        let fontSize = desiredWidthPerCharacter * 0.8 // Adjust this value to fine-tune the font size
        
        return fontSize
    }
    
}

