//
//  ContentView.swift
//  Instant translation
//
//  Created by 不二 Jack on 2025/3/1.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var translationViewModel = TranslationViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 简化版视图（用于测试）
            SimpleTranslationView()
                .tabItem {
                    Label("简化版", systemImage: "waveform")
                }
                .tag(0)
            
            // 完整版视图
            TranslationView()
                .tabItem {
                    Label("翻译", systemImage: "mic")
                }
                .tag(1)
            
            LanguageSelectionView()
                .tabItem {
                    Label("语言", systemImage: "globe")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
                .tag(3)
        }
        .environmentObject(translationViewModel)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
