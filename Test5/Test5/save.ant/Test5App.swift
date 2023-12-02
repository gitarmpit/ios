
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
        FireStoreManager.shared.sendDebug(msg: "before register")

        BGTaskScheduler.shared.register(forTaskWithIdentifier: "StopLocationManager", using: nil) { task in
            self.handleAppRefresh(task: task as! BGProcessingTask)
        }
        FireStoreManager.shared.sendDebug(msg: "after register")
        scheduleAppRefresh()
        return true
    }
    
    func scheduleAppRefresh() {
       let request = BGProcessingTaskRequest(identifier: "StopLocationManager")
       request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)
        do {
          try BGTaskScheduler.shared.submit(request)
            FireStoreManager.shared.sendDebug(msg: "after submit")

       } catch {
           FireStoreManager.shared.sendDebug(msg: "submit failed: " + error.localizedDescription)
       }
    }
    
    func handleAppRefresh(task: BGProcessingTask) {
        FireStoreManager.shared.sendDebug(msg: "fired!")
        scheduleAppRefresh()
    }
}
    

