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
            // 只保留主要功能视图
            TranslationView()
                .tabItem {
                    Label("翻译", systemImage: "mic")
                }
                .tag(0)
            
            LanguageSelectionView()
                .tabItem {
                    Label("语言", systemImage: "globe")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
                .tag(2)
        }
        .environmentObject(translationViewModel)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
