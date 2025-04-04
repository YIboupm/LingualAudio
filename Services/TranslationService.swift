//
//  TranslationService.swift
//  LingualAudio
//
//  Created by 梁艺博 on 15/1/25.
//
import Foundation

class TranslationService {
    func translate(text: String, targetLanguage: String, completion: @escaping (String?) -> Void) {
        // 假设后续接入翻译 API
        let translatedText = "这是翻译的内容"
        completion(translatedText)
    }
}

