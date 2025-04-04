//
//  AudioModel.swift
//  LingualAudio
//
//  Created by 梁艺博 on 15/1/25.
//

import Foundation

struct AudioModel: Identifiable, Codable {
    let id: Int
    let filename: String
    let duration: String
    let uploadedAt: String
    let sourceLanguage: String
    let audioType: String
    let originalTranscript: String
}

