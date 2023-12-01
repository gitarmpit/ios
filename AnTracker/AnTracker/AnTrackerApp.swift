import SwiftUI
import Firebase

@main
struct AnTrackerApp: App {
    init() {
      FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
