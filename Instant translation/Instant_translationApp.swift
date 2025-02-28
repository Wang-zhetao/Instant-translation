//
//  Instant_translationApp.swift
//  Instant translation
//
//  Created by 不二 Jack on 2025/3/1.
//

import SwiftUI

@main
struct Instant_translationApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(TranslationViewModel())
        }
    }
}
