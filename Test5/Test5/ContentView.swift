import SwiftUI
import Firebase

struct SettingsView: View {
    @AppStorage("isMph") var isMph: Bool = false
    @AppStorage("updateInterval") private var updateInterval: Int = 10
    
    var body: some View {
        VStack {
            Text("Settings")
                .font(.system(size: 30))
                .fontWeight(.bold)
                .padding()
            HStack {
                Text("Speed units: ")
                    .fontWeight(.bold)
                    .padding()
                Button(action: {
                    isMph = true
                }) {
                    HStack {
                        Image(systemName: isMph ? "largecircle.fill.circle" : "circle")
                        Text("mph")
                    }
                }
                .foregroundColor(.primary)
                
                Button(action: {
                    isMph = false
                }) {
                    HStack {
                        Image(systemName: isMph ? "circle" : "largecircle.fill.circle")
                        Text("km/h")
                    }
                }
                .foregroundColor(.primary)
                
            }
            Stepper(value: $updateInterval, in: 1...100) {
                Text("Update interval:")
                    .fontWeight(.bold)
                    .padding(.trailing, 10)
                Text("\(updateInterval)")
                    .fontWeight(.bold)
                    .padding(.horizontal, 10)
            }
            Spacer()

        }
    }
    
}
struct ContentView: View {
    var body: some View {
        TabView {
            MainView()
                .tabItem {
                    Image(systemName: "figure.walk")
                }
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                }
        }
    }
}

struct MainView: View {
    
    @StateObject private var locationManager: LocationManager = LocationManager()
    private let fontSize: CGFloat = 30
    private var fgColor: Color {
        locationManager.isRunning ? Color (red: 0, green: 130/255, blue: 153/255) : .black
    }
    
    init() {
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
                            .frame(minWidth: 200)
                    }
                    .padding()
                    
                    Text("Time:")
                        .font(.system(size: fontSize-10))
                        .foregroundColor(.gray)
                    Text(locationManager.durationString)
                        .font(.system(size: fontSize))
                        .fontWeight(.bold)
                        .foregroundColor(fgColor)
                }
                .padding(.bottom)
                VStack {
                    Text("Distance:")
                        .font(.system(size: fontSize-10))
                        .foregroundColor(.gray)
                    Text(locationManager.distanceString)
                        .font(.system(size: fontSize))
                        .fontWeight(.bold)
                        .foregroundColor(fgColor)
                }
                .padding(.bottom)
                VStack {
                    Text("Speed:")
                        .font(.system(size: fontSize-10))
                        .foregroundColor(.gray)
                    Text(locationManager.speedString)
                        .font(.system(size: fontSize))
                        .fontWeight(.bold)
                        .foregroundColor(fgColor)
                }
                .padding(.bottom)
                VStack {
                    Text("Avg Speed:")
                        .font(.system(size: fontSize-10))
                        .foregroundColor(.gray)
                    Text(locationManager.speedAvgString)
                        .font(.system(size: fontSize))
                        .fontWeight(.bold)
                        .foregroundColor(fgColor)
                }
                .padding(.bottom)
                VStack {
                    Text("Avg Pace:")
                        .font(.system(size: fontSize-10))
                        .foregroundColor(.gray)
                    Text(locationManager.paceAvgString)
                        .font(.system(size: fontSize))
                        .fontWeight(.bold)
                        .foregroundColor(fgColor)
                }
                .padding(.bottom)
                VStack {
                    Text("Steps:")
                        .font(.system(size: fontSize-10))
                        .foregroundColor(.gray)
                    Text(String(locationManager.stepCount))
                        .font(.system(size: fontSize))
                        .fontWeight(.bold)
                        .foregroundColor(fgColor)
                }
                .padding(.bottom)
                Spacer()
            }
        }
        .onAppear {
        }
        .onDisappear() {
        }
        
    }
}
