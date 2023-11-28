import Foundation
import Firebase

class FireStoreManager: NSObject, ObservableObject {
    
    private let db = Firestore.firestore()
    private var isMoving: Bool = false
    private var lastNotification: TimeInterval = 0
    private var minimumIntervalSec: TimeInterval = 1
    
    @Published var firestoreError: String = ""

    
    func sendHomeLocationSetNotification(loc: String) {
        firestoreError = "home"
        let ts = createTimeStamp()
        let data = [ "ts": ts, "loc": loc ]
        saveDataToFirestore(col: "locations", doc: "home", data: data)
    }

    func sendDistanceFromHomeNotification(distanceFromHome: String, totalDistance: String)  {
        let ts = createTimeStamp()
        let data = [
            "ts": ts,
            "distanceFromHome": distanceFromHome,
            "totalDistance": totalDistance
        ]
        saveDataToFirestore(col: "locations", doc: "distance", data: data)
    }
    
    func sendDepartureNotification() {
        let ts = createTimeStamp()
        let data = [ "ts": ts ]
        saveDataToFirestore(col: "departures", doc: ts, data: data)
    }

    func sendArrivalNotification(duration: String) {
        let ts = createTimeStamp()
        let data = [ "ts": ts,  "duration": duration ]
        saveDataToFirestore(col: "arrivals", doc: ts, data: data)
    }
    
    func sendAlertNotification(msg: String) {
        let ts = createTimeStamp()
        let data = [ "ts": ts,  "msg": msg ]
        saveDataToFirestore(col: "alerts", doc: ts, data: data)
    }
    
    func sendRefreshUpdateStat(msg: String) {
        let col = "log"
        let doc = "GPS_refresh_rate"
        let ts = createTimeStamp()
        var data = [ "msg": ts + " " + msg ]
        let docRef = db.collection(col).document(doc)

        firestoreError = "err0"
        docRef.getDocument { (snapshot, error) in
            self.firestoreError = "err1"
            if error == nil, let document = snapshot, document.exists {
                self.firestoreError = "err2"
                var tmpData = document.data() ?? [:]
                if let existingMsg = tmpData["msg"] as? String {
                    let updatedMsg = existingMsg + " " + data["msg"]!
                    tmpData["msg"] = updatedMsg
                    self.firestoreError = "err5"
                } else {
                    tmpData["msg"] = data["msg"]
                    self.firestoreError = "err6"
                }
                data = tmpData as? [String: String] ?? [:]
            }
            else {
                self.firestoreError = "err3"
            }
        }
        self.saveDataToFirestore(col: col, doc: doc, data: data)
    }

    private func saveDataToFirestore(col: String, doc: String, data: [String: Any]) {
        if (Date().timeIntervalSince1970 - lastNotification > minimumIntervalSec) {
            let col = db.collection(col)
            col.document(doc).setData(data)   { err in
                if let err = err {
                    self.firestoreError = err.localizedDescription;
                }
            }
            lastNotification = Date().timeIntervalSince1970
        }
    }

    private func createTimeStamp() -> String {
        let timeStamp = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: timeStamp)
    }

}
