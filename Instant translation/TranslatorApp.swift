import SwiftUI

struct TranslatorApp: App {
    // 创建一个持久的 ViewModel 实例
    @StateObject private var viewModel = TranslationViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
} 
