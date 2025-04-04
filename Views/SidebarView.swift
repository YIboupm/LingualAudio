//
//  SidebarView.swift
//  LingualAudio
//
//  Created by 梁艺博 on 15/1/25.
//

import SwiftUI

struct SidebarView: View {
    @Binding var isSidebarVisible: Bool // 绑定侧边栏显示状态
    @State private var isLoginViewPresented = false // 是否展示登录界面
    @ObservedObject var audioViewModel: AudioViewModel  // 监听`AudioViewModel`
    
    
    // 存储登录状态（使用AppStorage可以在App重启后保持登录）
    @AppStorage("userEmail") private var userEmail: String = ""
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @State private var isSettingsViewPresented = false //控制设置模型界面的显示
    @AppStorage("userID") private var userID: Int = 0
    @AppStorage("selectedModel") private var selectedModel : String = "Whisper"  //存储选择的模型
    
    var body: some View {
        ZStack(alignment: .leading) {
            // 背景：透明黑色遮罩，点击关闭侧边栏
            Spacer().frame(height: 60).padding(.top)
            
            // 侧边栏内容
            VStack(alignment: .leading) {
                Spacer().frame(height: 60).padding(.top)
                
                // 用户信息部分
                HStack {
                    Image(systemName: "person.crop.circle")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        if isLoggedIn {
                            Text(userEmail) // 显示登录的用户邮箱
                                .font(.headline)
                                .foregroundColor(.blue)
                        } else {
                            Text("Login") // 未登录状态显示 "Login"
                                .font(.headline)
                                .foregroundColor(.blue)
                                .onTapGesture {
                                    isLoginViewPresented = true // 点击后展示登录界面
                                }
                        }
                        
                        Text(isLoggedIn ? "Welcome Back!" : "Not Logged In") // 显示欢迎信息
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .sheet(isPresented: $isLoginViewPresented) {
                    LoginView(onLoginSuccess: { email in
                        userEmail = email
                        isLoggedIn = true
                        isLoginViewPresented = false // 关闭登录界面
                    })
                }
                
                Divider()
                
                // 功能菜单
                VStack(alignment: .leading) {
                    Button(action: {}) {
                        Label("Home", systemImage: "house")
                    }
                    .padding(.vertical, 8)
                    
                    Button(action: {}) {
                        Label("My Conversations", systemImage: "text.bubble")
                    }
                    .padding(.vertical, 8)
                    
                    Button(action: {
                        isSettingsViewPresented = true // 打开设置窗口
                    }) {
                        Label("Settings", systemImage: "gear")
                    }
                    .padding(.vertical, 8)
                    .sheet(isPresented: $isSettingsViewPresented) { // 📌 显示 `SettingsView`
                        SettingsView(isPresented: $isSettingsViewPresented)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                Divider()
                
                // 底部按钮
                HStack {
                    Spacer()
                    if isLoggedIn {
                        Button(action: {
                            logOut()  // ✅ 调用 logOut()
                        }) {
                            Text("Log Out")
                                .foregroundColor(.red)
                        }
                        .padding()
                        .padding(.bottom, 60)
                    }
                }
            }
            .frame(width: 250) // 侧边栏宽度
            .background(Color(UIColor.systemBackground))
            .edgesIgnoringSafeArea(.all)
        }
    }
    /// **退出登录逻辑**
        private func logOut() {
            print("🔴 用户退出登录，清空数据")
            userEmail = ""
            isLoggedIn = false
            userID = 0
            audioViewModel.resetPagination()  // ✅ 清空已加载的语音数据
        }
}

// 登录界面增加回调


#Preview {
    SidebarView(isSidebarVisible: .constant(true), audioViewModel: AudioViewModel())
}

