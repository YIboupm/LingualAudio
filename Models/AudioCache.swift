//
//  AudioCache.swift
//  LingualAudio
//
//  Created by 梁艺博 on 7/4/25.
//

import Foundation
import Combine

class AudioCache: ObservableObject {
    static let shared = AudioCache() // 🔒 单例

    @Published var cachedData: CachedAudioData?
    @Published var currentHypothesis: String = ""  // 新增：用于存储 interim 识别结果


    private init() {}

    // 设置初始值
    func startNewSession(userID: Int, filename: String, localURL: URL, startTime: Date) {
        self.cachedData = CachedAudioData(
            userID: userID,
            transcript: "",
            translation: "",
            wordTimestamps: [],
            startTime: startTime,
            endTime: Date(),
            duration: "00:00",
            recognitionModel: "Azure-SDK",
            translationQuality: "basic",
            location: nil,
            audioFilename: filename,
            audioLocalURL: localURL
        )
        self.currentHypothesis = ""
    }

    func updateTranscript(_ text: String) {
            DispatchQueue.main.async {
                self.cachedData?.transcript += text
                self.currentHypothesis = ""
            }
    }
    
    func updateHypothesis(_ text: String) {
            DispatchQueue.main.async {
                self.currentHypothesis = text
            }
    }
    
    func clearHypothesis() {
            DispatchQueue.main.async {
                self.currentHypothesis = ""
            }
    }
    
    func updateTranslation(_ text: String) {
        DispatchQueue.main.async {
            self.cachedData?.translation += text
        }
    }

    func addWordTimestamp(word: String, start: Double, end: Double) {
        let ts = WordTimestamp(word: word, start: start, end: end)
        DispatchQueue.main.async {
            self.cachedData?.wordTimestamps.append(ts)
        }
    }

    func endSession(endTime: Date, duration: String) {
        DispatchQueue.main.async {
            self.cachedData?.endTime = endTime
            self.cachedData?.duration = duration
        }
    }

    func setLocation(latitude: Double, longitude: Double, city: String?, country: String?) {
        DispatchQueue.main.async {
                    self.cachedData?.location = LocationData(
                        latitude: latitude,
                        longitude: longitude,
                        city: city,
                        country: country
                    )
                }
    }

    func clear() {
            
            DispatchQueue.main.async {
                self.cachedData = nil
                self.currentHypothesis = ""
            }
        }
}
