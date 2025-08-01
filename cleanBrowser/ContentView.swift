//
//  ContentView.swift
//  cleanBrowser
//
//  Created by NakataniSoshi on 2025/08/01.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            ZStack {
                // 背景グラデーション
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                VStack(spacing: 24) {
                    Image(systemName: "safari")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.white, Color.blue]), startPoint: .top, endPoint: .bottom))
                        .shadow(radius: 10)
                    Text("Clean Browser")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                    Text("A minimal & beautiful web experience.")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.85))
                    Spacer()
                    NavigationLink(destination: BrowserView()) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Start Browsing")
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.15))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(radius: 5)
                    }
                    .padding(.horizontal, 32)
                    Spacer()
                }
                .padding(.top, 60)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    ContentView()
}
