
import SwiftUI
import Firebase
import BackgroundTasks
import UIKit

@main
struct Test5App: App {

    @UIApplicationDelegateAdaptor(MyAppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

}

final class MyAppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    
        FirebaseApp.configure()
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "StopLocationManager", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        scheduleAppRefresh()
        return true
    }
    
    func scheduleAppRefresh() {
       let request = BGAppRefreshTaskRequest(identifier: "StopLocationManager")
       // Fetch no earlier than 15 minutes from now.
       request.earliestBeginDate = Date(timeIntervalSinceNow: 5 * 60)
        do {
          try BGTaskScheduler.shared.submit(request)
       } catch {
          print("Could not schedule app refresh: \(error)")
       }
    }
    
    func handleAppRefresh(task: BGAppRefreshTask) {
        FireStoreManager.shared.sendDebug(msg: "msg")
        scheduleAppRefresh()
    }
}
    

