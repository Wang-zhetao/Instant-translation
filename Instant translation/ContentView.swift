//
//  ContentView.swift
//  Instant translation
//
//  Created by 不二 Jack on 2025/3/1.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: TranslationViewModel
    @State private var selectedTab = 0
    @State private var showAlert = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
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
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("错误"),
                message: Text(viewModel.errorMessage ?? "未知错误"),
                dismissButton: .default(Text("确定"))
            )
        }
        .onReceive(viewModel.$errorMessage) { newValue in
            showAlert = newValue != nil
        }
    }
}

struct AlertItem: Identifiable {
    let id: UUID
    let title: String
    let message: String
}

#Preview {
    ContentView()
}
