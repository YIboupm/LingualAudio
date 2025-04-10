//
//  AudioDetailView.swift
//  LingualAudio
//
//  Created by 梁艺博 on 27/2/25.
//
import SwiftUI
import AVKit
import AVFoundation



struct AudioDetailView: View {
    let audioID: Int
    @StateObject private var viewModel = AudioViewModel()
    @State private var summaryText: String = "加载中..."
    @State private var isEditing: Bool = false
    @State private var highlightedWord: String = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 顶部标题和关闭按钮
            HStack {
                Text(viewModel.selectedAudio?.filename ?? "音频详情")
                    .font(.title2).bold()

                Spacer()

                Button("关闭") {
                    dismiss()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(Color.red)
                .cornerRadius(8)
            }
            .padding([.horizontal, .top])

            // 如果正在加载或加载失败，显示提示
            if viewModel.isLoadingDetail {
                ProgressView("加载中...")
                    .padding()
                Spacer()
            } else if let error = viewModel.errorMessage {
                Text("❌ \(error)")
                    .padding()
                Spacer()
            } else if let audio = viewModel.selectedAudio {
                // 播放器（缩小高度，按钮可改小）
                if let url = URL(string: "http://liangyibodeMac-mini.local:8001/audio/audio/play/\(audioID)"),
                   let wordTimestamps = audio.wordTimestamps {
                    AdvancedAudioPlayerView(
                        url: url,
                        wordTimestamps: wordTimestamps,
                        highlightWord: $highlightedWord
                    )
                    .frame(height: 120) // 控制播放器高度
                    .padding(.horizontal)
                }

                // 分割线 & 语言、时长
                Divider().padding(.horizontal)
                HStack {
                    Text("语言: \(audio.sourceLanguage)")
                        .font(.subheadline)
                    Spacer()
                    Text("时长: \(audio.duration)")
                        .font(.subheadline)
                }
                .padding(.horizontal, 16)

                // 选择显示转录 / 摘要
                Picker("显示内容", selection: $isEditing) {
                    Text("转录").tag(false)
                    Text("摘要").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)

                // 文本内容
                if isEditing {
                    TextEditor(text: $summaryText)
                        .frame(minHeight: 200)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal, 16)
                } else {
                    ScrollView {
                        Text(attributedTranscript(audio.originalTranscript, highlightedWord: highlightedWord))
                            .font(.body)
                            .padding()
                    }
                    .frame(minHeight: 200)
                    .padding(.horizontal, 16)
                }

                // 底部按钮
                HStack {
                    if isEditing {
                        Button("保存") {
                            viewModel.updateAudioSummary(audioID: audioID, newSummary: summaryText)
                            isEditing = false
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            viewModel.fetchAudioDetails(audioID: audioID)
        }
        .background(Color(UIColor.systemGroupedBackground)) // 整体浅色背景
        .edgesIgnoringSafeArea(.bottom)
    }

    // 你的高亮逻辑不变
    private func attributedTranscript(_ transcript: String, highlightedWord: String) -> AttributedString {
        guard !highlightedWord.isEmpty else {
            return AttributedString(transcript)
        }
        var attributedString = AttributedString(transcript)
        if let range = attributedString.range(of: highlightedWord,
                                              options: [.caseInsensitive, .diacriticInsensitive]) {
            attributedString[range].foregroundColor = .red
            attributedString[range].backgroundColor = .yellow.opacity(0.3)
            attributedString[range].font = .system(size: 16, weight: .bold)
        }
        return attributedString
    }
}


/// **Preview**
#Preview {
    AudioDetailView(audioID: 1)
}




