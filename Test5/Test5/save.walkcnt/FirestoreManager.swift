import Foundation
import Firebase

class FireStoreManager: ObservableObject {
    
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
    
    /*
    func sendLocation(ts: String, loc: String) {
        let col = "trips"
        let doc = "trip_" + ts
        let docRef = db.collection(col).document(doc)
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                // Document exists, update the list field
                var list = document.data()?["coords"] as? [String] ?? []
                list.append(loc)
                
                docRef.setData(["coords": list]) { error in
                    if let error = error {
                        self.firestoreError = error.localizedDescription
                    }
                    else {
                        self.firestoreError = "updated"
                    }
                }
            }
            else {
                let list = [loc]
                
                docRef.setData(["coords": list]) { error in
                    if let error = error {
                        self.firestoreError = error.localizedDescription
                    }
                    else {
                        self.firestoreError = "added new"
                    }
                }
            }
        }
        
    }
     */
    
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
