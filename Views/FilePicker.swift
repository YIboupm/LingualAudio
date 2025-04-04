//
//  FilePicker.swift
//  LingualAudio
//
//  Created by 梁艺博 on 15/1/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct FilePicker: UIViewControllerRepresentable {
    var onPicked: (URL?) -> Void // 选中文件后的回调

    func makeCoordinator() -> Coordinator {
        return Coordinator(onPicked: onPicked)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.audio]) // 支持音频文件类型
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // 不需要实现
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onPicked: (URL?) -> Void

        init(onPicked: @escaping (URL?) -> Void) {
            self.onPicked = onPicked
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
                    if let selectedFileURL = urls.first {
                        print("📂 用户选择的文件路径: \(selectedFileURL)")
                        onPicked(selectedFileURL) // 调用回调，执行上传
                    }
                }


        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onPicked(nil) // 如果取消选择，返回 nil
        }
    }
}
