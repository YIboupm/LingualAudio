//
//  SettingsModelsView.swift
//  LingualAudio
//
//  Created by 梁艺博 on 9/2/25.
//

import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool
    @AppStorage("selectedModel") private var selectedModel: String = "Whisper"
    
    let availableModels = ["Whisper"] // 未来可以扩展 ["Whisper", "Apple", "AI Model"]

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("SPEECH RECOGNITION MODEL")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.gray)
                    ) {
                        Picker("Select Model", selection: $selectedModel) {
                            ForEach(availableModels, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                        .pickerStyle(MenuPickerStyle()) // 使用菜单样式
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.gray.opacity(0.2), radius: 5, x: 0, y: 2)
                    }
                }
                .scrollContentBackground(.hidden) // 移除默认背景
                .background(Color(UIColor.systemGray6)) // 设置更优雅的背景色
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        UserDefaults.standard.set(selectedModel, forKey: "selectedModel") // ✅ 存入本地
                        isPresented = false
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                }
            }
        }
    }
}



// 预览
#Preview {
    SettingsView(isPresented: .constant(true))
}

