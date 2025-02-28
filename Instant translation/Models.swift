import Foundation

// 语言模型
struct Language: Identifiable, Hashable {
    let id = UUID()
    let code: String
    let name: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
    
    static func == (lhs: Language, rhs: Language) -> Bool {
        return lhs.code == rhs.code
    }
}

// 对话模型
struct Conversation: Identifiable {
    let id = UUID()
    let sourceText: String
    let translatedText: String
    let sourceLanguage: Language
    let targetLanguage: Language
    let timestamp: Date
    
    init(sourceText: String, translatedText: String, sourceLanguage: Language, targetLanguage: Language) {
        self.sourceText = sourceText
        self.translatedText = translatedText
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.timestamp = Date()
    }
} 
