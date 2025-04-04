//
//  AudioDetailView.swift
//  LingualAudio
//
//  Created by 梁艺博 on 27/2/25.
//
import SwiftUI
import AVKit

struct AudioDetailView: View {
    let audioID: Int
    @StateObject private var viewModel = AudioViewModel()
    @State private var summaryText: String = "加载中..."
    @State private var isEditing: Bool = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 15) {
            if let audio = viewModel.selectedAudio {
                // ✅ 语音文件名
                Text(audio.filename)
                    .font(.title)
                    .bold()
                    .padding()

                // ✅ 语言和时长
                HStack {
                    Text("🌍 语言: \(audio.sourceLanguage)")
                        .font(.headline)
                    Spacer()
                    Text("⏳ 时长: \(audio.duration)")
                        .font(.headline)
                }
                .padding(.horizontal)

                Divider()

                // ✅ 音频播放器
                if let url = URL(string: audio.fileURL) {
                    AudioPlayerView(url: url)
                        .frame(height: 50)
                        .padding()
                }

                Divider()

                // ✅ 转录内容 & 摘要
                Picker("显示内容", selection: $isEditing) {
                    Text("🎤 转录内容").tag(false)
                    Text("📝 摘要").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        if isEditing {
                            TextEditor(text: $summaryText)
                                .frame(minHeight: 150)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        } else {
                            Text(audio.originalTranscript)
                                .font(.body)
                                .padding()
                        }
                    }
                }

                Spacer()

                // ✅ 底部按钮
                HStack {
                    if isEditing {
                        Button(action: {
                            viewModel.updateAudioSummary(audioID: audioID, newSummary: summaryText)
                            isEditing = false
                        }) {
                            Text("保存")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                    }
                    
                    Button(action: { dismiss() }) {
                        Text("关闭")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                }
                .padding()
            } else {
                if viewModel.isLoadingDetail {
                    ProgressView("加载中...")
                } else {
                    Text("❌ \(viewModel.errorMessage ?? "加载失败")")
                }
            }
        }
        .onAppear {
            viewModel.fetchAudioDetails(audioID: audioID)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding(.horizontal, 20)
    }
}

/// **音频播放器**
struct AudioPlayerView: View {
    let url: URL
    private var player: AVPlayer { AVPlayer(url: url) }

    var body: some View {
        VideoPlayer(player: player)
            .onAppear { player.play() }
            .onDisappear { player.pause() }
    }
}

/// **Preview**
#Preview {
    AudioDetailView(audioID: 1)
}




