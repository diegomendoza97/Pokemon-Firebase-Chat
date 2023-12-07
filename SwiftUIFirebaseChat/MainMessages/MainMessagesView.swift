//
//  MainMessagesView.swift
//  SwiftUIFirebaseChat
//
//  Created by Diego Mendoza on 5/3/22.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseFirestoreSwift



class MainMessagesViewModel: ObservableObject {
    
    @Published var errorMessage = ""
    @Published var chatUser: ChatUser?
    @Published var isCurrentlyLoggedOut = false
    @Published var recentMessages = [RecentMessage]()
    
    init() {
        DispatchQueue.main.async {
            self.isCurrentlyLoggedOut = FirebaseManager.shared.auth.currentUser?.uid == nil
        }
        fetchCurrentUser()
        fetchRecentMessages()
    }
    
    private func fetchRecentMessages() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {return}
        
        FirebaseManager.shared.firestore.collection("recent_messages")
            .document(uid)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { querySnapshot, err in
                if let err = err  {
                    print(err)
                    self.errorMessage = "Failed to recent messages: \(err)"
                }
                querySnapshot?.documentChanges.forEach({ change in
                    let docId = change.document.documentID
                    
                    if let index = self.recentMessages.firstIndex(where: { rm in
                        return rm.id == docId
                    }) {
                        self.recentMessages.remove(at: index)
                    }
                    
                    let rm  = try? change.document.data(as: RecentMessage.self)
                    self.recentMessages.insert(rm!, at: 0)
                        
                })
                
            }
    }
    
    func fetchCurrentUser() {
        guard let uid =  FirebaseManager.shared.auth.currentUser?.uid else {
            self.errorMessage = "Fetching Current User"
            return
        }
        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapthot, err in
            if let err = err {
                print("Failed to fetch current user: \(err)")
                self.errorMessage = "Failed to fetch current user: \(err)"
                return
            }
            
            guard let data = snapthot?.data() else {return }
            
            print(data)
            
            self.chatUser = .init(data: data)
            
        }
    }
    func handleSignout() {
        isCurrentlyLoggedOut.toggle()
        try? FirebaseManager.shared.auth.signOut()
        
    }
}

struct MainMessagesView: View {
    @State var shouldLogoutOptions = false
    
    @State var shouldNavigaToChatLogView = false
    
    @ObservedObject private var vm = MainMessagesViewModel()
    
    
    var body: some View {
        NavigationView {
            VStack {
                customNavBar
                messagesView
                
                NavigationLink("", isActive: $shouldNavigaToChatLogView) {
                    ChatLogView(chatUser: self.chatUser ?? .init(data: ["email": "mew@gmail.com", "uid": "ECrEtEiuuIWCppuFWRCEolqe2Vh1"]))
                    
                }
            }
            .overlay(
               newMessageButton, alignment: .bottom)
            .navigationBarHidden(true)
        
        }
    }
    
    
    private var customNavBar: some View {
        HStack(spacing: 16) {
            WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? ""))
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipped()
                .cornerRadius(50)
                .overlay(((RoundedRectangle(cornerRadius: 50)
                    .stroke(Color(.label), lineWidth: 1))))
                .shadow(radius: 4)
            
            VStack(alignment: .leading, spacing: 4) {
                let email = "\(vm.chatUser?.email.replacingOccurrences(of: "@gmail.com", with: "") ?? "")"
                Text(email)
                    .font(.system(size: 24, weight: .bold))
                HStack {
                    Circle()
                        .foregroundColor(.green)
                        .frame(width: 14, height: 14)
                    Text("online")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.lightGray))
                }
                
            }
            
            Spacer()
            Button {
                shouldLogoutOptions.toggle()
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(.label))
            }
            
            
        }
        .padding()
        .actionSheet(isPresented: $shouldLogoutOptions) {
            .init(title: Text("Settings"), message: Text("What do tou want to do"), buttons: [
                .destructive(Text("Sign Out"), action: {
                    print("Handle Sign Out")
                    vm.handleSignout()
                }),
                .cancel()
            ])
        }
        .fullScreenCover(isPresented: $vm.isCurrentlyLoggedOut) {

        } content: {
            LoginView(didCompleteLoginProcess: {
                self.vm.isCurrentlyLoggedOut = false
                vm.fetchCurrentUser()
            })
        }

    }
    
    
    private var messagesView: some View {
        ScrollView {
            ForEach(vm.recentMessages) { recentMessage in
                VStack {
                    NavigationLink {
                        Text("Destination") 
                    } label: {
                        HStack(spacing: 16) {
                            WebImage(url: URL(string: recentMessage.profileImageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipped()
                                .cornerRadius(64)
                                .overlay(((RoundedRectangle(cornerRadius: 64)
                                    .stroke(Color(.label), lineWidth: 1))))
                                .shadow(radius: 4)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(recentMessage.email)
                                    .foregroundColor(.black)
                                    .font(.system(size: 16, weight: .bold))
                                    .multilineTextAlignment(.leading)
                                Text(recentMessage.text)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(.darkGray))
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            
                            Text(recentMessage.timestamp.description)
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }

                    Divider()
                        .padding(.vertical, 8)
                }.padding(.horizontal)
                
            }.padding(.bottom, 50)
        }
    }
    @State var shouldShowNewMessageScreen = false
    
    private var newMessageButton: some View {
        Button {
            shouldShowNewMessageScreen.toggle()
            
        } label: {
            HStack {
                Spacer()
                Text("+ New Message")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical)
            .background(.blue)
            .cornerRadius(32)
            .padding(.horizontal)
            .shadow(radius: 15)
            
        }
        .fullScreenCover(isPresented: $shouldShowNewMessageScreen, onDismiss: nil) {
            NewMessageView(didSelectNewUser: { user
                in
                print(user.email)
                self.shouldNavigaToChatLogView.toggle()
                self.chatUser = user
//                ChatLogview(chatUser: self.chatUser)
            })
        }
    }
    
    @State var chatUser: ChatUser?
}


struct MainMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MainMessagesView()
                .previewDevice("iPhone 13 Pro")
                .previewDisplayName("Iphone 13")
                .previewInterfaceOrientation(.portrait)
        }

    }
}


