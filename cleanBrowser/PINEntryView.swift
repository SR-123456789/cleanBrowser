//
//  PINEntryView.swift
//  cleanBrowser
//
//  Created by NakataniSoshi on 2025/08/08.
//

import SwiftUI

struct PINEntryView: View {
    let title: String
    let correctPIN: String
    let onResult: (Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var input: String = ""
    @State private var error: String?

    private let pinLength = 4  // 4桁例。correctPINの桁数に合わせてもOK

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.indigo.opacity(0.7)]),
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Text(title)
                    .font(.title2).bold()
                    .foregroundColor(.white)

                // ●●●● 表示
                HStack(spacing: 16) {
                    ForEach(0..<pinLength, id: \.self) { i in
                        Circle()
                            .strokeBorder(Color.white.opacity(0.6), lineWidth: 1.5)
                            .background(
                                Circle().foregroundColor(i < input.count ? .white : .clear)
                            )
                            .frame(width: 18, height: 18)
                    }
                }
                .padding(.vertical, 8)

                if let error = error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                }

                // 数字キー
                VStack(spacing: 16) {
                    ForEach([[ "1","2","3" ],[ "4","5","6" ],[ "7","8","9" ]], id: \.self) { row in
                        HStack(spacing: 16) {
                            ForEach(row, id: \.self) { key in
                                numKey(key)
                            }
                        }
                    }
                    HStack(spacing: 16) {
                        Spacer(minLength: 0)
                        numKey("0")
                        Button {
                            if !input.isEmpty { input.removeLast() }
                        } label: {
                            Image(systemName: "delete.left")
                                .font(.title2)
                                .frame(width: 72, height: 56)
                                .background(Color.white.opacity(0.12))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                }

                Button {
                    validate()
                } label: {
                    Text("Unlock")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(input.count == pinLength ? Color.white : Color.white.opacity(0.3))
                        .foregroundColor(.black.opacity(input.count == pinLength ? 1 : 0.6))
                        .cornerRadius(14)
                }
                .disabled(input.count != pinLength)
                .padding(.top, 8)

                Button("Cancel") { onResult(false) }
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 4)
            }
            .padding(24)
        }
        .onChange(of: input) { _, newValue in
            // 4桁に制限 & 自動判定したい場合はここで
            if newValue.count > pinLength {
                input = String(newValue.prefix(pinLength))
            }
            if newValue.count == pinLength {
                // タイピング完了で即判定したいなら↓を有効化
                // validate()
            }
        }
    }

    private func numKey(_ s: String) -> some View {
        Button {
            guard input.count < pinLength else { return }
            input.append(s)
        } label: {
            Text(s)
                .font(.title2).bold()
                .frame(width: 72, height: 56)
                .background(Color.white.opacity(0.12))
                .foregroundColor(.white)
                .cornerRadius(12)
        }
    }

    private func validate() {
        if input == correctPIN {
            error = nil
            onResult(true)
        } else {
            error = "PINが違います"
            // 震わせ演出など入れたい場合はwithAnimationで
            input.removeAll()
        }
    }
}
