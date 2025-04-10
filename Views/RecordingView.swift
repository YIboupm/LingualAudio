//
//  RecordingView.swift
//  LingualAudio
//  此页面显示实时翻译音频的详细信息
//  Created by 梁艺博 on 2/2/25.
//



import SwiftUI

enum RecordingStatus {
    case idle       // 未开始
    case recording  // 正在录音
    case paused     // 暂停中
}

struct RecordingView: View {
    @State private var recordingStatus: RecordingStatus = .idle   // 修改: 添加录音状态变量
    @State private var recordingTime: Int = 0
    @State private var timer: Timer? = nil
    
    @AppStorage("userID") private var userID: Int = 0  // 获取用户 ID
    @ObservedObject var audioCache = AudioCache.shared  // 绑定 AudioCache 实时更新内容
    
    var body: some View {
        ZStack {
            // Transcript 内容区域：全屏铺满（不设高度限制）
            VStack(spacing: 0) {
                // 顶部导航栏及切换选项（可保留或自定义）
                VStack(spacing: 0) {
                    HStack {
                        Text("Note")
                            .font(.title)
                            .bold()
                        Spacer()
                        HStack(spacing: 20) {
                            Image(systemName: "person.crop.circle.badge.plus")
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                            Image(systemName: "ellipsis")
                        }
                        .font(.title2)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    
                    HStack {
                        Text("Summary")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("Transcript")
                            .foregroundColor(.blue)
                            .bold()
                        Spacer()
                        Text("Comments")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                // 主要的 Transcript 滚动区域
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        let combinedText = (audioCache.cachedData?.transcript ?? "") + audioCache.currentHypothesis
                        if combinedText.isEmpty {
                            Text("等待识别结果...")
                                .foregroundColor(.gray)
                        } else {
                            Text(combinedText)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        
                        if let translated = audioCache.cachedData?.translation, !translated.isEmpty {
                            Divider().padding(.vertical, 4)
                            Text("翻译:")
                                .font(.headline)
                            Text(translated)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                .edgesIgnoringSafeArea(.bottom) // 内容铺满底部
            }
            
            // 底部悬浮的录音控制区域
            VStack {
                Spacer()
                HStack {
                    Button(action: toggleRecording) {
                        Group {
                            switch recordingStatus {
                            case .idle:
                                Label("Start", systemImage: "mic.fill")
                            case .recording:
                                Label("Pause", systemImage: "pause.fill")
                            case .paused:
                                Label("Resume", systemImage: "play.fill")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(colorForStatus())
                        .clipShape(Capsule())
                        .shadow(radius: 5)
                    }
                    
                    // 显示计时
                    Text(String(format: "%02d:%02d", recordingTime / 60, recordingTime % 60))
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                    
                    Button(action: stopAndUpload) {
                        Label("stop", systemImage: "stop.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .clipShape(Capsule())
                            .shadow(radius: 5)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
                .background(Color.black.opacity(0.85))
            }
        }
        .onDisappear { stopTimer() }
    }
    
    // 修改: 根据录音状态返回不同按钮背景颜色
    private func colorForStatus() -> Color {
        switch recordingStatus {
        case .idle: return Color.green
        case .recording: return Color.yellow
        case .paused: return Color.green
        }
    }
    
    // 修改: 切换录音状态，调用 Azure Speech 服务方法及定时器
    private func toggleRecording() {
        switch recordingStatus {
        case .idle:
                // 生成文件 URL，并初始化缓存数据
                let filename = "live_\(Int(Date().timeIntervalSince1970)).m4a"
                let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                AudioCache.shared.startNewSession(userID: userID, filename: filename, localURL: fileURL, startTime: Date())
                
                // 请求权限并开始录音
                AudioRecorderService.shared.requestPermission { granted in
                    if granted {
                        AudioRecorderService.shared.startRecording(to: fileURL)
                    } else {
                        print("用户拒绝录音权限")
                    }
                }
                
                // 启动语音识别
                SpeechRecognitionService.shared.startRecognition(userID: userID) { success in
                    if !success { print("启动识别失败") }
                }
                startTimer()
                recordingStatus = .recording
            
        case .recording:
            SpeechRecognitionService.shared.pauseRecognition()
            stopTimer()
            recordingStatus = .paused
            
        case .paused:
            SpeechRecognitionService.shared.resumeRecognition()
            startTimer()
            recordingStatus = .recording
        }
    }
    
    // 修改: 停止录音并上传缓存数据
    private func stopAndUpload() {
        //停止语音识别
        SpeechRecognitionService.shared.stopRecognition()
        //停止录音
        AudioRecorderService.shared.stopRecording()
        stopTimer()
        recordingStatus = .idle

        // 延时 0.5 秒后再触发上传，确保所有异步更新完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let cachedData = AudioCache.shared.cachedData,
               !cachedData.translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                UploadLiveAudioService.shared.upload(cachedData: cachedData) { success in
                    if success {
                        print("上传成功")
                        AudioCache.shared.clear()
                    } else {
                        print("上传失败")
                    }
                }
            } else {
                print("❗️翻译数据尚未更新完整，暂不触发上传")
            }
        }
    }

    
    // 定时器逻辑
    private func startTimer() {
        recordingTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            recordingTime += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct RecordingView_Previews: PreviewProvider {
    static var previews: some View {
        RecordingView()
    }
}




