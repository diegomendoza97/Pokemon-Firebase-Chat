//
//  RecentMessage.swift
//  SwiftUIFirebaseChat
//
//  Created by Diego Mendoza on 5/19/22.
//

import Firebase
import FirebaseFirestoreSwift
struct RecentMessage: Codable,  Identifiable {


    @DocumentID var id: String?
    let text, email: String
    let fromId, toId: String
    let profileImageUrl: String
    let timestamp: Date
    
    
    

//    init(documentId: String, data: [String: Any]) {
//        self.documentId = documentId
//        self.text = data["text"] as? String ?? ""
//        self.fromId = data[FirebaseConstants.FROMID] as? String ?? ""
//        self.toId = data[FirebaseConstants.TOID] as? String ?? ""
//        self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
//        self.email = data["email"] as? String ?? ""
////        self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date())
//    }
}
