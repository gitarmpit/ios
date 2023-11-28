import Foundation
import Firebase

class FireStoreManager: NSObject, ObservableObject {
    
    private let db = Firestore.firestore()
    
    @Published var firestoreError: String = ""
    
    func sendAlertNotification(msg: String, type: String) {
        let ts = createTimeStamp()
        let data = [ "ts": ts,  "msg": msg, "type": type ]
        saveDataToFirestore(col: "alerts", doc: ts, data: data)
    }
    
    func sendDebug(msg: String)  {
        let ts = createTimeStamp()
        let data = [ "ts": ts, "msg": msg ]
        saveDataToFirestore(col: "debug", doc: "debug", data: data)
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
