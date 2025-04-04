//
//  ContentView.swift
//  LingualAudio
//
//  Created by 梁艺博 on 15/1/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var audioViewModel = AudioViewModel()
    @State private var isRecording = false
    @State private var isShowingFilePicker = false
    @State private var isSidebarVisible = false

    @AppStorage("userID") private var userID: Int = 0  // 读取用户 ID

    // ✅ 排序选项
    @State private var sortOption: SortOption = .byDate

    // ✅ 计算排序后的数据
    var sortedAudios: [AudioModel] {
        switch sortOption {
        case .byDate:
            return audioViewModel.userAudios.sorted { $0.uploadedAt > $1.uploadedAt }
        case .byDuration:
            return audioViewModel.userAudios.sorted { $0.duration > $1.duration }
        case .byName:
            return audioViewModel.userAudios.sorted { $0.filename < $1.filename }
        }
    }

    var body: some View {
        ZStack(alignment: .leading) {
            NavigationStack {
                VStack {
                    // ✅ 侧边栏按钮
                    HStack {
                        Button(action: {
                            withAnimation {
                                isSidebarVisible.toggle()
                            }
                        }) {
                            Image(systemName: "line.horizontal.3")
                                .font(.title2)
                                .padding()
                        }
                        Spacer()
                    }
                    
                    

                    // ✅ 排序选项
                    Picker("排序方式", selection: $sortOption) {
                        Text("按时间").tag(SortOption.byDate)
                        Text("按时长").tag(SortOption.byDuration)
                        Text("按名称").tag(SortOption.byName)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()

                    // ✅ 语音列表
                    List {
                        ForEach(sortedAudios) { audio in
                            NavigationLink(destination: AudioDetailView(audioID: audio.id)) {
                                                        AudioListItem(audio: audio)
                                }
                                    .onAppear {
                                        if let last = sortedAudios.last, audio.id == last.id,
                                           audioViewModel.canLoadMore, !audioViewModel.isLoading{
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                if let last2 = sortedAudios.last, audio.id == last2.id {
                                                    audioViewModel.fetchUserAudios(userID: userID, loadMore: true)
                                                }
                                            }
                                        }
                                    }
                            }
                        if audioViewModel.isLoading {
                            ProgressView("加载中...")
                        }
                    }
                    .refreshable {
                        if userID != 0 {
                                audioViewModel.resetPagination()
                                audioViewModel.fetchUserAudios(userID: userID)
                            }
                    }
                    .onAppear {
                        if userID != 0 && audioViewModel.userAudios.isEmpty {
                            audioViewModel.fetchUserAudios(userID: userID) // ✅ 初始加载
                        }
                    }
                    .onChange(of: userID) { oldUserID, newUserID in
                        print("🔄 用户 ID 变化, 重新加载数据: \(oldUserID) -> \(newUserID)")
                        if newUserID != 0{
                            audioViewModel.resetPagination()
                            audioViewModel.fetchUserAudios(userID: newUserID)
                        }else{
                            audioViewModel.resetPagination()
                        }
                        
                    }
                    Spacer()
                }
            }
            .blur(radius: isSidebarVisible ? 5 : 0)
            .animation(.easeInOut, value: isSidebarVisible)
            

            // ✅ 侧边栏
            if isSidebarVisible {
                            // 半透明背景
                        Color.black
                            .opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation {
                                    isSidebarVisible = false
                                }
                            }

                        // 侧边栏内容
                    SidebarView(isSidebarVisible:$isSidebarVisible, audioViewModel: audioViewModel)
                            .frame(width: 250)
                    .background(.ultraThinMaterial)//  毛玻璃效果
                    .transition(.move(edge: .leading))
           }

            // ✅ 录音 & 上传文件按钮
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingButtons(
                        isRecording: $isRecording,
                        isShowingFilePicker: $isShowingFilePicker,
                        startRecording: startRecording,
                        stopRecording: stopRecording,
                        uploadFile: uploadFile,
                        audioViewModel: audioViewModel
                    )
                    .padding()
                }
            }
        }
    }

    // ✅ 录音功能
    private func startRecording() {
        print("🎤 开始录音...")
        isRecording = true
    }

    private func stopRecording() {
        print("🛑 停止录音...")
        isRecording = false
    }

    // ✅ 上传文件功能
    private func uploadFile(url: URL, userID: Int) {
        audioViewModel.uploadAudioFile(url: url, userID: userID)
    }
}

// ✅ 定义排序选项
enum SortOption {
    case byDate
    case byDuration
    case byName
}

#Preview {
    HomeView()
}



