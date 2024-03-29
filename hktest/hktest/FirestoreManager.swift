import Foundation
import Firebase

class FireStoreManager: NSObject, ObservableObject {
    
    static let shared = FireStoreManager()
    private let db = Firestore.firestore()
    
    @Published var firestoreError: String = ""
    
    func sendAlertNotification(msg: String, type: String) {
        let ts = createTimeStamp()
        let data = [ "ts": ts,  "msg": msg, "type": type ]
        saveDataToFirestore(col: "alerts", doc: "alert", data: data)
    }
    
    func sendDebug(msg: String)  {
        let ts = createTimeStamp()
        let data = [ "ts": ts, "msg": msg ]
        saveDataToFirestore(col: "debug", doc: "debug", data: data)
    }
    
    func sendLocation(loc: String) {
        let ts = createTimeStamp()
        let data = [ "ts": ts, "loc": loc ]
        saveDataToFirestore(col: "debug", doc: "loc", data: data)
    }
    
    func addTrip(tripId: String) {
        let timestamp = Timestamp()
        let data: [String: Any] = [
            "id": tripId,
            "ts": timestamp,
            "distance": "",
            "speedAvg": "",
            "duration": ""
        ]
        saveDataToFirestore(col: "trips", doc: tripId, data: data)
    }

    func addPointToTrip (tripId: String, seq: Int, point: TripPoint) {

        let data: [String: Any] = [
            "lat": String(format: "%.6f", point.latitude),
            "long": String(format: "%.6f", point.longitude),
            "speed": point.speed,
            "speedAvg": point.speedAvg,
            "distance": String(format: "%.3f", point.distance),
            "duration": point.duration
        ]

        let sseq = String(format: "%06d", seq);
        let pointsCol = db.collection("trips").document(tripId).collection("points")

        pointsCol.document(sseq).setData(data) { err in
            if let err = err {
                self.firestoreError = err.localizedDescription;
            }
            self.updateTrip (tripId: tripId, distance: point.distance, speedAvg: point.speedAvg, duration: point.duration)
        }
        
        saveDataToFirestore(col: "trips", doc: "currentTrip", data: data)
    }
    
    func updateTrip (tripId: String, distance: Double, speedAvg: Double, duration: String) {
        let data: [String: Any] = [
            "speedAvg": speedAvg,
            "distance": String(format: "%.1f", distance),
            "duration": duration
        ]
        self.db.collection("trips").document(tripId).updateData(data)   { err in
            if let err = err {
                self.firestoreError = err.localizedDescription;
            }
        }

    }
    
    private func saveDataToFirestore(col: String, doc: String, data: [String: Any]) {
        let col = db.collection(col)
        col.document(doc).setData(data)   { err in
            if let err = err {
                self.firestoreError = err.localizedDescription;
            }
        }
    }
    
    private func createTimeStamp() -> String {
        let timeStamp = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: timeStamp)
    }
    
}

