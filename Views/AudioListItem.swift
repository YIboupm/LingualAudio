//
//  AudioListItem.swift
//  LingualAudio
//
//  Created by 梁艺博 on 20/2/25.
//

import SwiftUI

struct AudioListItem: View {
    let audio: AudioModel

    //  计算背景颜色
    var backgroundColor: Color {
        let lowercasedLang = audio.sourceLanguage.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        print("🔍 Detected Language:", lowercasedLang)
        switch audio.sourceLanguage.lowercased() {
        case "spanish":
            return Color.yellow
        case "english":
            return Color.blue.opacity(0.3)
        default:
            return Color.gray.opacity(0.2)
        }
    }

    var body: some View {
        HStack {
            if audio.audioType == "UPLOADED" {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(.green)
                    .padding(.trailing, 5)
            }else if audio.audioType == "RECORDED"{
                Image (systemName: "mic.circle.fill")
                    .foregroundColor(.red)
                    .padding(.trailing,5)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(audio.filename)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(audio.sourceLanguage.uppercased())
                        .font(.caption)
                        .bold()
                        .padding(5)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(5)
                }

                Text(formatDate(audio.uploadedAt))
                    .font(.footnote)
                    .foregroundColor(.gray)

                HStack {
                    Text("⏳ \(audio.duration)")
                        .font(.subheadline)
                        .foregroundColor(.blue)

                    Text("📝 \(audio.originalTranscript.prefix(5))...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(10)
        }
    }

    //  解析时间
    private func formatDate(_ isoDate: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        guard let date = isoFormatter.date(from: isoDate) else { return "未知时间" }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}
