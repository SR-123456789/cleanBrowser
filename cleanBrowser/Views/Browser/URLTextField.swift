//
//  URLTextField.swift
//  cleanBrowser
//
//  Extracted from BrowserView.swift for MVVM separation.
//  UITextField wrapper that selects all on focus.
//

import SwiftUI

struct URLTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFirstResponder: Bool
    var placeholder: String = ""
    var onBeginEditing: () -> Void = {}
    var onCommit: (String) -> Void

    func makeUIView(context: Context) -> UITextField {
        let tf = CompactURLTextField(frame: .zero)
        tf.borderStyle = .none
        tf.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        tf.placeholder = placeholder
        // 長いURLでズームのような挙動が起きることがあるため、フォントの自動縮小で収める
        tf.adjustsFontSizeToFitWidth = true
        tf.minimumFontSize = 10
        tf.adjustsFontForContentSizeCategory = false
        tf.contentVerticalAlignment = .center
        tf.keyboardType = .URL
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.returnKeyType = .go
        tf.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tf.delegate = context.coordinator
        tf.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)), for: .editingChanged)
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.parent = self
        if uiView.text != text { uiView.text = text }
        if isFirstResponder && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
            // 選択は textFieldDidBeginEditing で一度だけ行う
        } else if !isFirstResponder && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: URLTextField
        init(_ parent: URLTextField) { self.parent = parent }

        @objc func editingChanged(_ sender: UITextField) {
            parent.text = sender.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            let submittedText = textField.text ?? ""
            parent.text = submittedText
            parent.onCommit(submittedText)
            // 検索後にキーボードを閉じる
            textField.resignFirstResponder()
            parent.isFirstResponder = false
            return true
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.onBeginEditing()
            parent.isFirstResponder = true
            // 開始時に全選択
            DispatchQueue.main.async {
                textField.selectAll(nil)
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.isFirstResponder = false
        }
    }
}

private final class CompactURLTextField: UITextField {
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 20)
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        bounds
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        bounds
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        bounds
    }
}
