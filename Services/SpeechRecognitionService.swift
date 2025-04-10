//
//  SpeechRecognitionService.swift
//  LingualAudio
//
//  Created by 梁艺博 on 07/04/25.
//

import Foundation
import MicrosoftCognitiveServicesSpeech
import CoreLocation

class SpeechRecognitionService: ObservableObject {
    static let shared = SpeechRecognitionService()

    private var speechRecognizer: SPXTranslationRecognizer?
    private var audioConfig: SPXAudioConfiguration?
    private var speechConfig: SPXSpeechTranslationConfiguration?

    private var startTime: Date = Date()

    func startRecognition(userID: Int, completion: @escaping (Bool) -> Void) {
            // ✅ 修改：直接硬编码你的 Azure 订阅 key 和区域（后续建议从配置中读取）
            let subscriptionKey = "xxxxxxx" // 替换为真实 key
            let region = "xxxxx" // 区域保持不变
            
            // ✅ 读取用户设置的语言
            let selectedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "en-US"
            print("🌐 使用识别语言：", selectedLanguage)

            // 初始化配置
            speechConfig = try? SPXSpeechTranslationConfiguration(subscription: subscriptionKey, region: region)
            speechConfig?.speechRecognitionLanguage = selectedLanguage
            speechConfig?.addTargetLanguage("zh-CN")
            
            

            audioConfig = SPXAudioConfiguration()

            guard let config = speechConfig, let audio = audioConfig else {
                print("❌ 配置失败")
                completion(false)
                return
            }

            // 初始化识别器
            speechRecognizer = try? SPXTranslationRecognizer(speechTranslationConfiguration: config, audioConfiguration: audio)

            guard let recognizer = speechRecognizer else {
                print("❌ 创建识别器失败")
                completion(false)
                return
            }

            // 初始化缓存
            let filename = "live_\(Int(Date().timeIntervalSince1970)).m4a"
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            startTime = Date()
            AudioCache.shared.startNewSession(userID: userID, filename: filename, localURL: fileURL, startTime: startTime)

            // 添加interim事件处理--实时更新原始语言字幕
            recognizer.addRecognizingEventHandler { _, event in
                    if let interimText = event.result.text, !interimText.isEmpty {
                        DispatchQueue.main.async {
                            AudioCache.shared.updateHypothesis(interimText)  // 更新临时显示内容
                        }
                        print("interim 识别到文本: \(interimText)")
                    }
            }
            
            
        
            
            recognizer.addRecognizedEventHandler { _, event in
                if let text = event.result.text, !text.isEmpty {
                    // 修改: 使用 DispatchQueue.main.async 确保 UI 更新在主线程上执行
                    DispatchQueue.main.async {
                        AudioCache.shared.updateTranscript(text + " ")
                    }
                    print("识别到文本: \(text)") // 修改: 增加日志打印识别到的文本
                }

                if let translated = event.result.translations["zh-CN"] as? String {
                    // 修改: 使用 DispatchQueue.main.async 确保 UI 更新在主线程上执行
                    DispatchQueue.main.async {
                        AudioCache.shared.updateTranslation(translated + " ")
                    }
                    print("识别到翻译: \(translated)") // 修改: 增加日志打印识别到的翻译
                }
            }

            recognizer.addCanceledEventHandler { _, event in
                print("⚠️ 识别取消: \(event.errorDetails ?? "未知错误")")
            }

            recognizer.addSessionStoppedEventHandler { _, _ in
                print("🛑 识别会话结束")
            }

            // 启动识别
            do {
                try recognizer.startContinuousRecognition()
                print("🎤 开始实时语音识别")
                completion(true)
            } catch {
                print("❌ 启动识别失败: \(error.localizedDescription)")
                completion(false)
            }
        }
    
    
    // MARK: - 暂停识别（不调用 endSession）
    func pauseRecognition() {
            guard let recognizer = speechRecognizer else { return }
            do {
                try recognizer.stopContinuousRecognition()
                print("⏸ 识别已暂停（缓存仍保留）")
            } catch {
                print("❌ 暂停识别失败: \(error.localizedDescription)")
            }
    }
    
    
    // MARK: - 继续识别（复用同一个 recognizer & 缓存）
    func resumeRecognition() {
        guard let recognizer = speechRecognizer else { return }
        
        do {
            try recognizer.startContinuousRecognition()
            print("▶️ 识别已继续")
        } catch {
            print("❌ 继续识别失败: \(error.localizedDescription)")
        }
    }
    
    
    func stopRecognition() {
            guard let recognizer = speechRecognizer else { return }
            do {
                try recognizer.stopContinuousRecognition()
            } catch {
                print("❌ 停止识别失败: \(error.localizedDescription)")
            }

            let stopTime = Date()
            let durationString = formatDuration(from: startTime, to: stopTime)

            // 修改: 确保更新 UI 数据在主线程中执行
            DispatchQueue.main.async {
                AudioCache.shared.endSession(endTime: stopTime, duration: durationString)
            }
            print("✅ 识别结束，缓存数据已更新")
        }

    private func formatDuration(from start: Date, to end: Date) -> String {
        let interval = Int(end.timeIntervalSince(start))
        let minutes = interval / 60
        let seconds = interval % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
