//
//  AdvancedAudioPlayerView.swift
//  LingualAudio
//
//  Created by 梁艺博 on 6/4/25.
//

import SwiftUI
import AVFoundation

struct AdvancedAudioPlayerView: View {
    let url: URL
    let wordTimestamps: [WordTimestamp]
    @Binding var highlightWord: String
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 1

    var body: some View {
        VStack(spacing: 10) {
            // 时间显示
            HStack {
                Text(formatTime(currentTime))
                Spacer()
                Text(formatTime(duration))
            }
            .font(.caption)

            // 进度条
            Slider(value: $currentTime, in: 0...duration, onEditingChanged: { editing in
                if !editing {
                    seekTo(seconds: currentTime)
                }
            })

            // 控制按钮
            HStack(spacing: 40) {
                Button(action: { skip(by: -10) }) {
                    Image(systemName: "gobackward.10")
                }

                Button(action: togglePlayPause) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                }

                Button(action: { skip(by: 10) }) {
                    Image(systemName: "goforward.10")
                }
            }
            .padding(.top, 10)
            .font(.title)
        }
        .padding()
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    private func setupPlayer() {
        player = AVPlayer(url: url)

        Task {
            if let asset = player?.currentItem?.asset {
                do {
                    let loadedDuration = try await asset.load(.duration)
                    let durationInSeconds = CMTimeGetSeconds(loadedDuration)
                    DispatchQueue.main.async {
                        self.duration = durationInSeconds
                    }
                } catch {
                    print("❌ 加载 duration 失败: \(error)")
                }
            }
        }

        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
                let seconds = CMTimeGetSeconds(time)
                self.currentTime = seconds

                // 根据当前时间检查对应的单词
                if let currentTimestamp = wordTimestamps.first(where: { seconds >= $0.start && seconds <= $0.end }) {
                    self.highlightWord = currentTimestamp.word
                } else {
                    self.highlightWord = ""
                }
            }
    }

    private func togglePlayPause() {
        guard let player = player else { return }
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }

    private func skip(by seconds: Double) {
        guard let player = player else { return }
        let current = CMTimeGetSeconds(player.currentTime())
        let newTime = max(0, min(current + seconds, duration))
        seekTo(seconds: newTime)
    }

    private func seekTo(seconds: Double) {
        let targetTime = CMTime(seconds: seconds, preferredTimescale: 600)
        player?.seek(to: targetTime)
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "00:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}


#Preview {
    AdvancedAudioPlayerView(
        url: URL(string: "https://example.com/audio.mp3")!,
        wordTimestamps: [],
        highlightWord: .constant("")
    )
}

