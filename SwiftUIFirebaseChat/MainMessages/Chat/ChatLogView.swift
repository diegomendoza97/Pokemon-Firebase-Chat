//
//  ChatLogView.swift
//  SwiftUIFirebaseChat
//
//  Created by Diego Mendoza on 5/12/22.
//

import SwiftUI
import Firebase


struct FirebaseConstants  {
    static let FROMID = "fromId"
    static let TOID = "toId"
    static let TEXT = "text"
    static let TIMESTAMP = "timestamp"
}

struct ChatMessage: Identifiable {
    
    var id: String { documentId }
    
    let documentId: String
    let toId: String
    let fromId: String
    let timestamp: String?
    let text: String
    
    init(data: [String: Any], documentId: String) {
        self.fromId = data[FirebaseConstants.FROMID] as? String ?? ""
        self.documentId = documentId
        self.toId = data[FirebaseConstants.TOID] as? String ?? ""
        self.timestamp = data[FirebaseConstants.TIMESTAMP] as? String ?? ""
        self.text = data[FirebaseConstants.TEXT] as? String ?? ""
    }
}

class ChatLogViewModel: ObservableObject {
    
    @Published var chatText = ""
    
    @Published var errorMessage = ""
    
    @Published var chatMessages = [ChatMessage]()
    
    @Published var count = 0
    
    let chatUser: ChatUser?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        fetchMessages()
    }
    
    private func fetchMessages() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else {return}
        guard let toId = chatUser?.uid else {return}
        FirebaseManager.shared.firestore.collection("messages").document(fromId).collection(toId)
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to listen to messages  \(error)"
                    return
                }
                
                snapshot?.documentChanges.forEach({ change in
                    if change.type == .added {
                        let data = change.document.data()
                        let chatMessage = ChatMessage(data: data,documentId: change.document.documentID)
                        self.chatMessages.append(chatMessage)
                    }
                })
                DispatchQueue.main.async {
                    self.count += 1
                }
                
            }
    }
    
    func handleSend() {
        print(chatText)
        
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else {return}
        
        guard let toId = chatUser?.uid else {return}
        
        let document = FirebaseManager.shared.firestore
            .collection("messages")
            .document(fromId)
            .collection(toId)
            .document()
        

        let messageData = [FirebaseConstants.FROMID: fromId, FirebaseConstants.TOID: toId, FirebaseConstants.TEXT: self.chatText, FirebaseConstants.TIMESTAMP: Timestamp()] as [String : Any]
        
        
        document.setData(messageData) { error in
            if let error = error  {
                self.errorMessage = "Failed to save message into Firestore: \(error)"
            }
        }
        
        let recipientMessageDocument = FirebaseManager.shared.firestore
            .collection("messages")
            .document(toId)
            .collection(fromId)
            .document()
        
        recipientMessageDocument.setData(messageData) { error in
            if let error = error  {
                self.errorMessage = "Failed to save message into Firestore: \(error)"
            }
        }
        
        
        self.persistRecentMessage(uid: fromId, toId: toId)
        
        self.chatText = ""
        self.count += 1
        
    }
    
    private func persistRecentMessage(uid: String, toId: String) {
        
        let document = FirebaseManager.shared.firestore
            .collection("recent_messages")
            .document(uid)
            .collection("messages")
            .document(toId)
        
        let data = [
            "timestamp": Timestamp(),
            "text": self.chatText,
            FirebaseConstants.FROMID: uid,
            FirebaseConstants.TOID: toId,
            "profileImageUrl": chatUser?.profileImageUrl ?? "",
            "email": chatUser?.email ?? ""
        ] as [String: Any]
        
        document.setData(data) { error in
            if let err = error {
                print(err)
                self.errorMessage = "Failed to save recent message: \(err)"
                return
            }
            
        }
        
        
//        guard let currentUser = FirebaseManager.shared.currentUser else {return}
//        let recipientRecentMessageDictionary = [
//                    "timestamp": Timestamp(),
//                    "text": self.chatText,
//                    FirebaseConstants.FROMID: uid,
//                    FirebaseConstants.TOID: toId,
//                    "profileImageUrl": currentUser.profileImageUrl ?? "",
//                    "email": currentUser.email
//                ] as [String : Any]
//
//        FirebaseManager.shared.firestore
//            .collection("recent_messages")
//            .document(toId)
//            .collection("messages")
//            .document(currentUser.uid)
//            .setData(recipientRecentMessageDictionary) { error in
//                if let error = error {
//                    print("Failed to save recipient recent message: \(error)")
//                    return
//                }
//            }
    }
}

struct ChatLogView: View {
    
    let chatUser: ChatUser?
    
    
    init(chatUser: ChatUser) {
        self.chatUser = chatUser
        self.vm = ChatLogViewModel(chatUser: chatUser)
    }
    
    @ObservedObject var vm: ChatLogViewModel
    
    static let emptyScrollTo = "Empty"
    
    var body: some View {
        messagesView
            .navigationTitle(chatUser?.email ?? "")
            .navigationBarTitleDisplayMode(.inline)
        }
    
    
    
    private var messagesView: some View {
        VStack {
            if #available(iOS 15.0, *) {
                ScrollView {
                    VStack {
                        ScrollViewReader {scrollViewProxy in
                            ForEach(vm.chatMessages) { message in
                                MessageView(message: message)
                                
                            }
                            HStack { Spacer() }
                                .id(Self.emptyScrollTo)
                                .onReceive(vm.$count) { _ in
                                    withAnimation(.easeOut(duration: 0.5)) {
                                        scrollViewProxy.scrollTo(Self.emptyScrollTo, anchor: .bottom)
                                    }
                                        
                                }
                        }
                    }
                    
                }.background(Color(.init(white: 0.95, alpha: 1)))
                    .safeAreaInset(edge: .bottom) {
                        chatBottomBar.background(Color(.systemBackground).ignoresSafeArea())
                    }
            }
        }
    }
    
    struct MessageView: View {
        let message: ChatMessage
        var body: some View {
            VStack {
                if message.fromId == FirebaseManager.shared.auth.currentUser?.uid {
                    HStack {
                        Spacer()
                        HStack {
                            Text(message.text)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(.blue)
                        .cornerRadius(8)
                    }
                } else {
                    HStack {
                        HStack {
                            Text(message.text)
                                .foregroundColor(Color(.label))
                        }
                        .padding()
                        .background(.white)
                        .cornerRadius(8)
                        Spacer()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
    
    private var chatBottomBar: some View {
        HStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .foregroundColor(Color(.darkGray))
                .font(.system(size: 20))
            ZStack {
                DescriptionPlaceholder()
                TextEditor(text: $vm.chatText)
                    .opacity(vm.chatText.isEmpty ? 0.5 : 1)
            }
            .frame(height: 40)
            Button {
                vm.handleSend()
            } label: {
                Text("Send")
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color.blue)
            .cornerRadius(5)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

private struct DescriptionPlaceholder: View {
    var body: some View {
        HStack {
            Text("Description")
                .foregroundColor(Color(.gray))
                .font(.system(size: 17))
                .padding(.leading, 5)
                .padding(.top, -4)
            Spacer()
        }
    }
}

struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
//        NavigationView {
//            ChatLogView(chatUser: .init(data: ["email": "mew@gmail.com", "uid": "ECrEtEiuuIWCppuFWRCEolqe2Vh1"]))
//                .previewDevice("iPhone 13 Pro")
//                .previewDisplayName("Iphone 13")
//                .previewInterfaceOrientation(.portrait)
//        }
//        .previewDevice("iPhone 13 Pro")
        
        MainMessagesView()
            .previewDevice("iPhone 13 Pro")
            .previewDisplayName("Iphone 13")
            .previewInterfaceOrientation(.portrait)
    }
}
