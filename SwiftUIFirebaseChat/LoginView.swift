//
//  ContentView.swift
//  SwiftUIFirebaseChat
//
//  Created by Diego Mendoza on 5/3/22.
//

import SwiftUI
import Firebase


struct LoginView: View {
    
    let didCompleteLoginProcess: () -> ()
    
    
    @State private var isLoginMode = false
    @State private var email = ""
    @State private var password = ""
    @State private var shouldShowImagePicker =  false
    
    
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Picker(selection: $isLoginMode, label: Text("Picker Here")) {
                        Text("Login")
                            .tag(true)
                        Text("Create Account")
                            .tag(false)
                    }.pickerStyle(SegmentedPickerStyle())

                    
                    if !isLoginMode {
                        Button {
                            shouldShowImagePicker.toggle()
                        } label: {
                            VStack {
                                if let image = self.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .frame(width: 128, height: 128)
                                        .scaledToFill()
                                        .cornerRadius(64)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 64))
                                        .padding()
                                        .foregroundColor(.black)
                                }
                            }
                            .overlay(RoundedRectangle(cornerRadius: 64)
                                .stroke(.black, lineWidth: 3)
                            )
                                
                        }

                    }
                    Group {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            
                        SecureField("Password", text: $password)
                    }.padding(12)
                        .background(Color.white)
                    
                    
                    Button {
                        handleAction()
                    } label: {
                        HStack {
                            Spacer()
                            Text(isLoginMode ? "Log In" : "Create Account")
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                        }.background(Color.blue)
                    }
                    
                    Text(self.loginStatusMessage)
                        .foregroundColor(.red)
                }.padding()
                
                
            }
            .navigationTitle(isLoginMode ? "Login" : "Create Account")
            .background(Color(.init(white: 0, alpha: 0.05)).ignoresSafeArea())
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil) {
            ImagePicker(image: $image)
        }
    }
    
    @State var image: UIImage?
    
    private  func handleAction() {
        if isLoginMode {
            print("Should Log in")
            loginUser()
        } else {
            createNewAccount()
            print("Create Acount")
        }
    }
    
    @State var loginStatusMessage = ""
    
    private func createNewAccount() {
        if self.image == nil {
            self.loginStatusMessage = "You must select an avatar image"
        }
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password) {
            result, err in
            if let err = err {
                print("Failed to create user: ", err)
                self.loginStatusMessage = "Failed to create user: \(err)"
                return
            }
            
            print("Successfully crated user: \(result?.user.uid ?? "")")
            self.loginStatusMessage = "Successfully crated user: \(result?.user.uid ?? "")"
            
            self.persistImageToStorage()
        }
    }
    
    private func loginUser() {
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) { result, err in
            if let err = err {
                self.loginStatusMessage = "Failed to create user: \(err)"
            }
            
            print("Successfully signed in user")
            self.loginStatusMessage = "Successfully signed in user"
            self.didCompleteLoginProcess()
            
        }
    }
    
    private func persistImageToStorage() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid
            else {return}
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5)
        else {return}
        ref.putData(imageData, metadata: nil) { metadata, err in
            if let err = err  {
                self.loginStatusMessage = "Failed to upload image to storage: \(err)"
                return
            }
            ref.downloadURL { url, err in
                if let err = err  {
                    self.loginStatusMessage = "Failed to retrieve download URL: \(err)"
                    return
                }
                
                self.loginStatusMessage = "SUCCESS STORING AND DOWNLOADING IMAGE with url: \(url?.absoluteString ?? "")"
                guard let url = url else {return}
                self.storeUserInformation(imageProfileUrl: url)
            }
        }
    }
    
    private func storeUserInformation(imageProfileUrl: URL) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {return}
        
        let userData = ["email": self.email, "uid": uid, "profileImageUrl": imageProfileUrl.absoluteString]
        
        FirebaseManager.shared.firestore.collection("users")
            .document(uid).setData(userData) { err in
                if let err = err {
                    print(err)
                    self.loginStatusMessage = "\(err)"
                    return
                }
                
                self.loginStatusMessage = "SUCCESS"
                
                self.didCompleteLoginProcess()
            }
    }
     
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(didCompleteLoginProcess: {
            
        })
            .previewDevice("iPhone 13 Pro")
    }
}
