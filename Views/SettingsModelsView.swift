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
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "en-US" // 默认语言

    let availableModels = ["Whisper"]
    let availableLanguages = [
        (label: "English", code: "en-US"),
        (label: "Spanish", code: "es-ES")
    ]

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("AUDIO RECOGNITION MODEL")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.gray)) {

                        Picker("Select Model", selection: $selectedModel) {
                            ForEach(availableModels, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.gray.opacity(0.2), radius: 5, x: 0, y: 2)
                    }

                    Section(header: Text("SPEECH INPUT LANGUAGE")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.gray)) {

                        Picker("Select Language", selection: $selectedLanguage) {
                            ForEach(availableLanguages, id: \.code) { lang in
                                Text(lang.label).tag(lang.code)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.vertical)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color(UIColor.systemGray6))
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        UserDefaults.standard.set(selectedModel, forKey: "selectedModel")
                        UserDefaults.standard.set(selectedLanguage, forKey: "selectedLanguage")
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
