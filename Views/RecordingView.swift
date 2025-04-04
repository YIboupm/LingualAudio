//
//  RecordingView.swift
//  LingualAudio
//  此页面显示实时翻译音频的详细信息
//  Created by 梁艺博 on 2/2/25.
//



import SwiftUI

struct RecordingView: View {
    @Binding var isRecording: Bool
    @State private var recordingTime: Int = 0
    @State private var timer: Timer? = nil
    
    var body: some View {
        VStack {
            HStack {
                Text("Note")
                    .font(.title)
                    .bold()

                Spacer()

                HStack(spacing: 20) {
                    Image(systemName: "person.crop.circle.badge.plus")
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                    Image(systemName: "ellipsis")
                }
                .font(.title2)
            }
            .padding()

            HStack {
                Text("Summary")
                    .foregroundColor(.gray)
                Spacer()
                Text("Transcript")
                    .foregroundColor(.blue)
                    .bold()
                Spacer()
                Text("Comments")
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.bottom, 10)

            Spacer()

            Text("Ask Otter or @mention people")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)

            HStack {
                Button(action: {
                    if isRecording {
                        stopTimer()
                    } else {
                        startTimer()
                    }
                    isRecording.toggle()
                }) {
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .padding()
                        .background(isRecording ? Color.red : Color.green)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }

                Text(String(format: "%02d:%02d", recordingTime / 60, recordingTime % 60))
                    .font(.headline)
                    .padding(.leading, 10)

                Spacer()
            }
            .padding()
        }
        .onDisappear {
            stopTimer()
        }
    }

    private func startTimer() {
        recordingTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            recordingTime += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct RecordingView_Previews: PreviewProvider {
    @State static var isRecording = false

    static var previews: some View {
        RecordingView(isRecording: $isRecording)
    }
}

