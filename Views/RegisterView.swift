//
//  RegisterView.swift
//  LingualAudio
//
//  Created by 梁艺博 on 16/1/25.
//

import SwiftUI

struct RegisterView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccessAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer().frame(height: 50)
                
                Text("Register")
                    .font(.largeTitle)
                    .bold()
                
                Spacer().frame(height: 20)
                
                TextField("Full Name", text: $fullName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                    .padding(.horizontal, 40)

                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(.horizontal, 40)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 40)
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 40)
                
                Spacer().frame(height: 20)
                
                Button(action: {
                    if email.isEmpty || password.isEmpty || confirmPassword.isEmpty || fullName.isEmpty {
                        errorMessage = "All fields are required."
                        showError = true
                    } else if password != confirmPassword {
                        errorMessage = "Passwords do not match."
                        showError = true
                    } else {
                        registerUser(email: email, password: password, fullName: fullName)
                    }
                }) {
                    Text("Register")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(email.isEmpty || password.isEmpty || confirmPassword.isEmpty || fullName.isEmpty ? Color.gray : Color.green)
                        .cornerRadius(10)
                }
                .disabled(email.isEmpty || password.isEmpty || confirmPassword.isEmpty || fullName.isEmpty)
                .padding(.horizontal, 40)
                
                Spacer().frame(height: 10)
                
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
            }
            .navigationBarTitle("Register", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showSuccessAlert) {
                Alert(title: Text("Success"), message: Text("Registration successful!"), dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                })
            }
        }
    }
    
    func registerUser(email: String, password: String, fullName: String) {
        guard let url = URL(string: "http://liangyibodeMac-mini.local:8000/auth/register") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email, "password": password, "full_name": fullName]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "Network error. Please try again."
                    self.showError = true
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    DispatchQueue.main.async {
                        if let token = json["access_token"] as? String {
                            self.showSuccessAlert = true
                        } else if let detail = json["detail"] as? [String: Any], let error = detail["error"] as? String {
                            self.errorMessage = error
                            self.showError = true
                        } else {
                            self.errorMessage = "Unexpected error. Please try again."
                            self.showError = true
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Error processing response. Please try again."
                    self.showError = true
                }
            }
        }.resume()
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}

