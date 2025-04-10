//
//  FloatingButtons.swift
//  LingualAudio
//
//  Created by 梁艺博 on 16/1/25.
//

import SwiftUI
import Foundation
import UniformTypeIdentifiers

struct FloatingButtons: View {
    
    @Binding var isShowingFilePicker: Bool
    
    var uploadFile: (URL, Int) -> Void  //  确保上传时带上 userID
    @ObservedObject var audioViewModel: AudioViewModel  //  让 FloatingButtons 访问 ViewModel

    @State private var showRecordingView = false
    @State private var showLoginView = false
    @State private var selectedFileURL: URL? = nil  //  存储选中的文件
    @State private var showConfirmationDialog = false //  确认上传对话框

    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("userID") private var userID: Int = 0  //  读取用户 ID

    var body: some View {
        HStack {
            // 左侧的“上传文件”按钮
            Button(action: {
                if isLoggedIn {
                    isShowingFilePicker = true
                } else {
                    showLoginView = true
                }
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .clipShape(Circle())
                    .shadow(radius: 5)
            }
            .sheet(isPresented: $isShowingFilePicker) {
                FilePicker { selectedURL in
                    if let url = selectedURL {
                        selectedFileURL = url  // ✅ 存储文件
                        showConfirmationDialog = true // ✅ 显示确认对话框
                    }
                }
            }
            .alert(isPresented: $showConfirmationDialog) {
                Alert(
                    title: Text("Confirm Upload"),
                    message: Text("Are you sure you want to upload this file?"),
                    primaryButton: .default(Text("Upload")) {
                        if let url = selectedFileURL {
                            audioViewModel.uploadAudioFile(url: url, userID: userID) // ✅ 通过实例调用
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .sheet(isPresented: $showLoginView) {
                LoginView()
            }

            Spacer()

            // 右侧的“录音”按钮
            Button(action: {
                if isLoggedIn {
                    showRecordingView = true
                } else {
                    showLoginView = true
                }
            }) {
                Image(systemName: "mic.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.green)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
            }
            .sheet(isPresented: $showRecordingView) {
                RecordingView()
            }
            .sheet(isPresented: $showLoginView) {
                LoginView()
            }
        }
        .padding(.horizontal, 40)
    }
}

struct FloatingButtons_Previews: PreviewProvider {
    @State static var isRecording = false
    @State static var isShowingFilePicker = false
    static let sampleAudioViewModel = AudioViewModel() // ✅ 创建一个示例 ViewModel

    static var previews: some View {
        FloatingButtons(
            isShowingFilePicker: $isShowingFilePicker,
            uploadFile: {_,_ in },
            audioViewModel: sampleAudioViewModel // ✅ 传入示例实例
        )
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}

