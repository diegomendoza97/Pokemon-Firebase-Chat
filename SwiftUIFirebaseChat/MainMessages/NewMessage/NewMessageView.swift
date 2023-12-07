//
//  NewMessageView.swift
//  SwiftUIFirebaseChat
//
//  Created by Diego Mendoza on 5/10/22.
//

import SwiftUI
import SDWebImageSwiftUI

class NewMessageViewModel: ObservableObject {
    
    @Published var users = [ChatUser]()
    @Published var errorMessage = ""
    
    
    init() {
        fetchAllUsers()
    }
    
    private func fetchAllUsers() {
        FirebaseManager.shared.firestore.collection("users")
            .whereField("uid", isNotEqualTo: FirebaseManager.shared.auth.currentUser?.uid ?? "")
            .getDocuments { documentsSnapshot, err in
            if let err = err  {
                print("Failed to fetch users: \(err)")
                self.errorMessage = "Failed to fetch users: \(err)"
                return
            }
            
            documentsSnapshot?.documents.forEach({ snapshot in
                let data = snapshot.data()
                self.users.append(.init(data: data))
            })
            
            
        }
    }
}

struct NewMessageView: View {
    
    let didSelectNewUser: (ChatUser) -> ()
    
    @ObservedObject var vm = NewMessageViewModel()
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(vm.errorMessage)
                ForEach(vm.users) { user in
                    Button {
                        presentationMode.wrappedValue.dismiss()
                        didSelectNewUser(user)
                    } label: {
                        HStack(spacing: 16) {
                            WebImage(url: URL(string: user.profileImageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipped()
                                .cornerRadius(50)
                                .overlay(RoundedRectangle(cornerRadius: 50)
                                    .stroke(Color(.label), lineWidth: 1))
                            Text(user.email)
                            Spacer()
                        }
                        .foregroundColor(Color(.label))
                        .padding(.horizontal)
                    }

                    Divider()
                        .padding(.vertical, 8 )
                    
                }
            }.navigationTitle("New Message")
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text("Cancel")
                        }

                    }
                }
        }
    }
}

struct NewMessageView_Previews: PreviewProvider {
    static var previews: some View {
//        MainMessagesView()
        NewMessageView(didSelectNewUser: { user in
            
        })
    }
}
