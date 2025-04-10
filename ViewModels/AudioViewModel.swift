//
//  AudioViewModel.swift
//  LingualAudio
//
//  Created by 梁艺博 on 15/1/25.
//

import Foundation
import AVFoundation
import UniformTypeIdentifiers
import SwiftUI

class AudioViewModel: ObservableObject {
    
    @AppStorage("selectedModel") private var selectedModel: String = "Whisper"
    @AppStorage("userID") private var userID: Int = 0 // ✅ 读取本地存储的 userID
    @Published var userAudios: [AudioModel] = []
    @Published var isLoading = false
    
    @Published var selectedAudio: AudioDetailModel? // 存储从 API 获取的音频详情
    @Published var isLoadingDetail = false
    @Published var errorMessage: String?
    
    private var currentPage = 1
    private let pageSize = 6
    private var hasMoreData = true
    
    
    // ✅ 只读属性
    var canLoadMore: Bool {
        return hasMoreData && !isLoading
    }
    
    /// **重置分页 & 清空数据**
    func resetPagination() {
        DispatchQueue.main.async {
            self.userAudios = [] // ✅ 清空现有数据
            self.currentPage = 1 // ✅ 重置分页
            self.hasMoreData = true // ✅ 允许加载更多
        }
    }
    
    /// **更新音频摘要**
    func updateAudioSummary(audioID: Int, newSummary: String) {
        guard let url = URL(string: "http://liangyibodeMac-mini.local:8001/audio/update_summary/\(audioID)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["summary": newSummary]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ 提交失败:", error.localizedDescription)
            } else {
                print("✅ 摘要提交成功")
            }
        }.resume()
    }

    
    /// **请求音频详情**
    func fetchAudioDetails(audioID: Int) {
        guard let url = URL(string: "http://liangyibodeMac-mini.local:8001/audio/audio/\(audioID)") else { return }
        
        isLoadingDetail = true
        errorMessage = nil

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoadingDetail = false
            }
            if let error = error {
                print("网络请求失败: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = "请求失败: \(error.localizedDescription)"
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("服务器返回错误状态码: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                DispatchQueue.main.async {
                    self.errorMessage = "服务器返回错误状态码"
                }
                return
            }
            
            guard let data = data else {
                print("未接收到数据")
                DispatchQueue.main.async {
                    self.errorMessage = "未接收到数据"
                }
                return
            }
            
            // 打印原始 JSON 数据
            if let jsonString = String(data: data, encoding: .utf8) {
                print("接收到的 JSON: \(jsonString)")
            }
            
            do {
                let decoder = JSONDecoder()
                //decoder.keyDecodingStrategy = .convertFromSnakeCase // 确保使用下划线转驼峰
                decoder.dateDecodingStrategy = .iso8601 // 如果 uploadedAt 是 Date 类型
                
                let decodedData = try decoder.decode(AudioDetailModel.self, from: data)
                DispatchQueue.main.async {
                    self.selectedAudio = decodedData
                }
            } catch let DecodingError.keyNotFound(key, context) {
                print("字段缺失: \(key.stringValue), 上下文: \(context.debugDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = "解析失败: 字段缺失 \(key.stringValue)"
                }
            } catch let DecodingError.typeMismatch(type, context) {
                print("类型不匹配: \(type), 上下文: \(context.debugDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = "解析失败: 类型不匹配 \(type)"
                }
            } catch let DecodingError.valueNotFound(value, context) {
                print("值缺失: \(value), 上下文: \(context.debugDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = "解析失败: 值缺失 \(value)"
                }
            } catch {
                print("其他错误: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = "解析音频数据失败: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    
    
    // ✅ 获取语音列表（支持分页加载）
    func fetchUserAudios(userID: Int, loadMore: Bool = false) {
            if isLoading { return }
            if loadMore && !hasMoreData { return }
            
            isLoading = true
            let page = loadMore ? currentPage : 1
            guard let url = URL(string: "http://liangyibodeMac-mini.local:8001/audio/user_audios/\(userID)?page=\(page)&page_size=\(pageSize)") else { return }
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                if let data = data {
                    do {
                        let decodedData = try JSONDecoder().decode([AudioModel].self, from: data)
                        DispatchQueue.main.async {
                            if loadMore {
                                self.userAudios.append(contentsOf: decodedData)
                            } else {
                                self.userAudios = decodedData
                            }
                            if decodedData.count < self.pageSize {
                                self.hasMoreData = false
                            } else {
                                self.currentPage += 1
                            }
                        }
                    } catch {
                        print("解析音频数据失败:", error.localizedDescription)
                    }
                }
            }.resume()
        }
    
    
    /// **上传音频文件**
    func uploadAudioFile(url: URL, userID: Int) {
        Task {
            let duration = await getAudioDurationFormatted(url: url) // ⏳ **获取音频时长**
            await uploadAudioFile(url: url, userID: userID, duration: duration) // 📤 **上传**
        }
    }

    /// **计算音频时长 (MM:SS)，兼容 iOS 16+**
    func getAudioDurationFormatted(url: URL) async -> String {
        // 尝试开启安全作用域
        guard url.startAccessingSecurityScopedResource() else {
            print("无法访问安全作用域资源")
            return "未知时长"
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let options = [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        let asset = AVURLAsset(url: url, options: options)
        
        do {
            let duration = try await asset.load(.duration)
            let totalSeconds = CMTimeGetSeconds(duration)
            let minutes = Int(totalSeconds) / 60
            let seconds = Int(totalSeconds) % 60
            return String(format: "%02d:%02d", minutes, seconds)
        } catch {
            print("加载音频时长失败：\(error)")
            return "未知时长"
        }
    }


    /// **实际的上传逻辑**
    private func uploadAudioFile(url: URL, userID: Int, duration: String) async {
        guard let serverURL = URL(string: "http://liangyibodeMac-mini.local:8001/audio/upload/") else { return }

        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        
        //添加文件大小
        //let fileData = try? Data(contentsOf: url)
        //let fileSize = fileData?.count ?? 0
        
        
        // 添加文件大小，使用安全作用域访问文件
        var fileData: Data? = nil
        if url.startAccessingSecurityScopedResource() {
            defer { url.stopAccessingSecurityScopedResource() }
            fileData = try? Data(contentsOf: url)
            if let data = fileData {
                print("文件大小：\(data.count) bytes")
            } else {
                print("无法读取文件数据")
            }
        } else {
            print("无法访问安全作用域资源")
        }
        let fileSize = fileData?.count ?? 0


        // -- 写入 file_size 字段
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file_size\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(fileSize)\r\n".data(using: .utf8)!)



        // 添加用户 ID
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(userID)\r\n".data(using: .utf8)!)

        // 添加音频时长
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"duration\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(duration)\r\n".data(using: .utf8)!)
        
        //  upload_time
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withTimeZone]
        dateFormatter.timeZone = TimeZone.current  // ✅ 保持本地时区
        let nowString = dateFormatter.string(from: Date())  // ✅ 确保格式正确
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"uploaded_at\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(nowString)\r\n".data(using: .utf8)!)
        
        // 添加模型名
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"selected_model\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(selectedModel)\r\n".data(using: .utf8)!)
        
        // ✅ 继续添加文件
        let filename = url.lastPathComponent
        let mimetype = "audio/mpeg"


        if let fileData = fileData {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        // ✅ 调试信息
        print("📡 Sending request to: \(serverURL)")
        print("🆔 Stored User ID:", userID)
        print("🎯 Selected Model:", selectedModel)
        print("📂 Filename:", filename)
        print("⏳ Duration:", duration)
        print("📅 Upload Time:", nowString)  // 确保它的格式正确
        print("📝 HTTP Body Size:", body.count, "bytes")
        
        

        // 发送请求
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("上传失败: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ 上传成功!")
            } else {
                print("❌ 上传失败，状态码不匹配")
            }
        }.resume()
    }
}
