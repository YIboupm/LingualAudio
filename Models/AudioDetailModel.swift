//
//  AudioDetailModel.swift
//  LingualAudio
//
//  Created by 梁艺博 on 27/2/25.
//

import Foundation



struct WordTimestamp: Codable, Identifiable {
    var id = UUID()
    let word: String
    let start: Double
    let end: Double
    
    enum CodingKeys: String , CodingKey{
        case word,start,end
    }
}

struct AudioDetailModel: Codable {
    let id: Int
    let userId: Int
    let filename: String
    let fileURL: String
    let fileSize: Int
    let audioFormat: String
    let audioType: String
    let sourceLanguage: String
    let originalTranscript: String
    let translatedTranscript: String
    let summary: String?
    let uploadedAt: String // 或者使用 Date 并配置解码器
    let duration: String
    let location: String? // 可选类型，因为 JSON 中是 null
    let wordTimestamps: [WordTimestamp]?

    // 自定义 CodingKeys（确保包含 user_id 到 userId 的映射）
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case filename
        case fileURL = "file_url"
        case fileSize = "file_size"
        case audioFormat = "audio_format"
        case audioType = "audio_type"
        case sourceLanguage = "source_language"
        case originalTranscript = "original_transcript"
        case translatedTranscript = "translated_transcript"
        case summary
        case uploadedAt = "uploaded_at"
        case duration
        case location
        case wordTimestamps = "word_timestamps"
    }
}

