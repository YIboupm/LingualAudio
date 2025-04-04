//
//  LoginView.swift
//  LingualAudio
//
//  Created by 梁艺博 on 16/1/25.
//

import SwiftUI

struct LoginView: View {
    var onLoginSuccess: ((String) -> Void)? // 登录成功回调
    
    @Environment(\.presentationMode) var presentationMode // 用于关闭当前视图
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false  // ✅ 共享状态
    @AppStorage("userEmail") private var userEmail: String = ""  // ✅ 记住邮箱
    @AppStorage("userID") private var userID: Int = 0
    
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showRegisterView = false//用于控制是否显示注册界面
    
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer().frame(height: 50)

                // 标题
                Text("Login")
                    .font(.largeTitle)
                    .bold()

                Spacer().frame(height: 20)

                // 输入框
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(.horizontal, 40)

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 40)

                Spacer().frame(height: 20)

                // 登录按钮
                Button(action: {
                    if email.isEmpty || password.isEmpty {
                        errorMessage = "Please enter both email and password."
                        showError = true
                    } else {
                        loginUser(email: email, password: password)
                    }
                }) {
                    Text("Login")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 40)

                Spacer().frame(height: 10)

                // 错误提示
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                }

                Spacer().frame(height: 20)
                
                // 注册按钮
                Button(action: {
                    showRegisterView = true
                }) {
                                    
                    Text("Don't have an account? Register here.")
                                        .foregroundColor(.blue)
                                        .font(.subheadline)
                    }
                    .padding()
                    .sheet(isPresented: $showRegisterView){
                    RegisterView()
                }
                                
                Spacer().frame(height: 10)

                // Google 登录按钮
                Button(action: {
                    // 处理 Google 登录
                    print("Login with Google")
                }) {
                    HStack {
                        Image(systemName: "globe")
                            .font(.title2)
                            .foregroundColor(.white)
                        Text("Continue with Google")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 40)

                Spacer()
            }
            .navigationBarTitle("Login", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss() // 关闭界面
            })
        }
    }

    // 登录用户函数
    private func loginUser(email: String, password: String) {
        guard let url = URL(string: "http://127.0.0.1:8000/auth/login") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["email": email, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    errorMessage = "No response from server."
                    showError = true
                }
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               
               let user = json["user"] as? [String: Any], // ✅ 解析 "user" 字段
               let userID = user["id"] as? Int { // ✅ 获取 user["id"]

                DispatchQueue.main.async {
                    isLoggedIn = true
                    userEmail = email
                    self.userID = userID // ✅ 正确存储 userID

                    print("✅ UserID received and stored:", self.userID)
                    print("✅ Dismissing LoginView")

                    onLoginSuccess?(email)
                    presentationMode.wrappedValue.dismiss() // 关闭登录界面
                }
            } else {
                DispatchQueue.main.async {
                    errorMessage = "Invalid email or password."
                    showError = true
                }
            }
        }.resume()
    }

}
