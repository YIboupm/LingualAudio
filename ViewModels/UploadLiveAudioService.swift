//
//  UploadLiveAudioService.swift
//  LingualAudio
//
//  Created by 梁艺博 on 7/4/25.
//

import Foundation

class UploadLiveAudioService {
    static let shared = UploadLiveAudioService()
    private init() {}

    /// 上传实时录音 + metadata 到后端
    func upload(cachedData: CachedAudioData, completion: @escaping (Bool) -> Void) {
        
        if cachedData.translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                print("❗️警告：翻译结果为空，还未完成更新。暂不触发上传")
                completion(false)
                return
        }
        
        let url = URL(string: "http://liangyibodeMac-mini.local:8001/realtime/realtime/upload/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
 
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // ✨ 基础字段
        func appendField(name: String, value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        print("💬 translated_transcript 目前的值: \(cachedData.translation)")
        
        
        appendField(name: "user_id", value: String(cachedData.userID))
        appendField(name: "original_transcript", value: cachedData.transcript)
        appendField(name: "translated_transcript", value: cachedData.translation)
        appendField(name: "translation_model", value: cachedData.recognitionModel)
        appendField(name: "translation_quality", value: cachedData.translationQuality)
        appendField(name: "duration", value: cachedData.duration)
        appendField(name: "audio_type", value: "RECORDED")
        
        
        
        appendField(name: "filename", value: cachedData.audioFilename)
        // 时间
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
        appendField(name: "start_time", value: formatter.string(from: cachedData.startTime))
        appendField(name: "end_time", value: formatter.string(from: cachedData.endTime))
        appendField(name: "uploaded_at", value: formatter.string(from: Date()))
        
        // 👇 添加调试打印
        print("📡 准备发送上传请求")
        print("🆔 user_id:", cachedData.userID)
        print("📄 transcript:", cachedData.transcript)
        print("translation:",cachedData.translation)
        print("🌍 location:", cachedData.location ?? "无")
        print("🧾 wordTimestamps:", cachedData.wordTimestamps)
        print("📅 开始时间:", formatter.string(from: cachedData.startTime))
        print("📅 结束时间:", formatter.string(from: cachedData.endTime))
        print("📄 filename:", cachedData.audioFilename)
        print("📤 上传目标 URL:", url.absoluteString)
        
        
        // 位置 JSON
        if let loc = cachedData.location {
            let locationDict: [String: Any?] = [
                "latitude": loc.latitude,
                "longitude": loc.longitude,
                "city": loc.city,
                "country": loc.country
            ]
            if let locData = try? JSONSerialization.data(withJSONObject: locationDict, options: []),
               let jsonStr = String(data: locData, encoding: .utf8) {
                appendField(name: "location", value: jsonStr)
            }
        }

        // 词时间戳 JSON
        if let wordsData = try? JSONEncoder().encode(cachedData.wordTimestamps),
           let wordsJson = String(data: wordsData, encoding: .utf8) {
            appendField(name: "word_timestamps", value: wordsJson)
        }
        
        let filePath = cachedData.audioLocalURL.path
        let fileExists = FileManager.default.fileExists(atPath: filePath)
        print("检查文件是否存在：", fileExists)
        
        
        // 添加音频文件
        if let fileData = try? Data(contentsOf: cachedData.audioLocalURL) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(cachedData.audioFilename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
            print("Loaded file data, size: (fileData.count) bytes")
        }else{
            print("❌ 无法读取文件数据，从 (cachedData.audioLocalURL) 读取失败")
        }
        

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ 上传失败: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ 实时音频上传成功")
                DispatchQueue.main.async {
                    completion(true)
                }
            } else {
                print("❌ 服务器错误: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }.resume()
    }
}
