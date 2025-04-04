//
//  SpeechRecognitionService.swift
//  LingualAudio
//
//  Created by 梁艺博 on 15/1/25.
//
import Speech
import Foundation

class SpeechRecognitionService {
    func transcribeAudio(url: URL, completion: @escaping (String?) -> Void) {
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: url)
        
        recognizer?.recognitionTask(with: request) { result, error in
            if let error = error {
                print("Speech recognition error: \(error.localizedDescription)")
                completion(nil)
            } else {
                completion(result?.bestTranscription.formattedString)
            }
        }
    }
}

