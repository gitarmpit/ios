
import SwiftUI
import Firebase

@main
struct Test5App: App {
    init() {
      FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
