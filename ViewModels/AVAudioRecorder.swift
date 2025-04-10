//
//  AVAudioRecorder.swift
//  LingualAudio
//
//  Created by 梁艺博 on 9/4/25.
//

import AVFoundation

class AudioRecorderService: NSObject, AVAudioRecorderDelegate {
    static let shared = AudioRecorderService()
    private var recorder: AVAudioRecorder?
    
    // 请求录音权限
    func requestPermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    // 开始录音，保存到指定 URL
    func startRecording(to url: URL) {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.delegate = self
            recorder?.record()
            print("🎙️ 录音开始")
        } catch {
            print("❌ 录音启动失败：\(error)")
        }
    }
    
    // 停止录音
    func stopRecording() {
        recorder?.stop()
        print("🛑 录音结束")
    }
}
