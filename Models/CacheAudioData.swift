//
//  CacheAudioData.swift
//  LingualAudio
//
//  Created by 梁艺博 on 7/4/25.
//

import Foundation
import CoreLocation

struct LocationData: Codable {
    let latitude: Double
    let longitude: Double
    let city: String?
    let country: String?
}

struct CachedAudioData: Codable {
    let userID: Int
    var transcript: String
    var translation: String
    var wordTimestamps: [WordTimestamp]  // ✅ 用你已有的定义

    var startTime: Date
    var endTime: Date
    var duration: String

    var recognitionModel: String
    var translationQuality: String

    var location: LocationData?
    
    var audioFilename: String  // ✅ 例如 "recording_2025_04_07.wav"
    var audioLocalURL: URL
}

