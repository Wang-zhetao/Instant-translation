import Foundation
import Speech
import AVFoundation
import Combine

class TranslationViewModel: ObservableObject {
    // 可用语言
    let availableLanguages = [
        Language(code: "zh-CN", name: "中文"),
        Language(code: "en-US", name: "英语"),
        Language(code: "ja-JP", name: "日语"),
        Language(code: "ko-KR", name: "韩语"),
        Language(code: "fr-FR", name: "法语"),
        Language(code: "de-DE", name: "德语"),
        Language(code: "es-ES", name: "西班牙语"),
        Language(code: "ru-RU", name: "俄语")
    ]
    
    // 发布的属性
    @Published var sourceLanguage: Language
    @Published var targetLanguage: Language
    @Published var isRecording = false
    @Published var transcription = ""
    @Published var translation = ""
    @Published var conversations: [Conversation] = []
    @Published var errorMessage: String?
    @Published var hasPermission = false
    @Published var isTranslating = false
    
    // 语音识别
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // 语音合成
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    init() {
        self.sourceLanguage = availableLanguages[0] // 默认中文
        self.targetLanguage = availableLanguages[1] // 默认英语
        
        // 设置语音识别器
        updateSpeechRecognizer()
        
        // 请求语音识别权限
        requestSpeechAuthorization()
    }
    
    private func updateSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: sourceLanguage.code))
    }
    
    // 请求语音识别权限
    func requestSpeechAuthorization() {
        // 确保在主线程请求权限
        DispatchQueue.main.async {
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    self.hasPermission = status == .authorized
                    if !self.hasPermission {
                        self.errorMessage = "需要语音识别权限才能使用此应用"
                    }
                }
            }
        }
    }
    
    // 交换语言
    func swapLanguages() {
        let temp = sourceLanguage
        sourceLanguage = targetLanguage
        targetLanguage = temp
        updateSpeechRecognizer()
    }
    
    // 设置源语言
    func setSourceLanguage(_ language: Language) {
        sourceLanguage = language
        updateSpeechRecognizer()
    }
    
    // 设置目标语言
    func setTargetLanguage(_ language: Language) {
        targetLanguage = language
    }
    
    // 开始录音和识别
    func startRecording() {
        // 首先检查权限
        guard hasPermission else {
            errorMessage = "需要语音识别权限才能使用此功能"
            return
        }
        
        // 确保没有正在进行的识别任务
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // 创建音频会话
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "设置音频会话失败: \(error.localizedDescription)"
            return
        }
        
        // 创建识别请求
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        // 确保语音识别器已初始化
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "语音识别器不可用"
            return
        }
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "无法创建语音识别请求"
            return
        }
        
        // 配置请求
        recognitionRequest.shouldReportPartialResults = true
        
        // 开始识别
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                // 更新转录文本
                DispatchQueue.main.async {
                    self.transcription = result.bestTranscription.formattedString
                }
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                // 停止音频引擎
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                DispatchQueue.main.async {
                    self.isRecording = false
                    
                    // 如果有转录文本，则进行翻译
                    if !self.transcription.isEmpty {
                        self.translateText()
                    }
                }
            }
        }
        
        // 配置音频
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // 启动音频引擎
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isRecording = true
            transcription = ""
            translation = ""
        } catch {
            errorMessage = "音频引擎启动失败: \(error.localizedDescription)"
            isRecording = false
        }
    }
    
    // 停止录音
    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            isRecording = false
        }
    }
    
    // 翻译文本
    func translateText() {
        guard !transcription.isEmpty else { return }
        
        isTranslating = true
        
        // 这里使用模拟翻译，实际应用中应该调用翻译API
        // 例如 Apple 的 Translation 框架或第三方 API 如 Google Translate
        simulateTranslation(text: transcription) { [weak self] translatedText in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.translation = translatedText
                self.isTranslating = false
                
                // 添加到对话历史
                let conversation = Conversation(
                    sourceText: self.transcription,
                    translatedText: translatedText,
                    sourceLanguage: self.sourceLanguage,
                    targetLanguage: self.targetLanguage
                )
                self.conversations.append(conversation)
                
                // 朗读翻译结果
                self.speakTranslation()
            }
        }
    }
    
    // 模拟翻译过程（实际应用中应替换为真实的翻译API调用）
    private func simulateTranslation(text: String, completion: @escaping (String) -> Void) {
        // 模拟网络延迟
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            // 简单的模拟翻译，实际应用中应使用真实的翻译API
            let translatedText: String
            
            if self.sourceLanguage.code.starts(with: "zh") && self.targetLanguage.code.starts(with: "en") {
                // 中文到英文的简单映射
                let translations = [
                    "你好": "Hello",
                    "早上好": "Good morning",
                    "晚上好": "Good evening",
                    "谢谢": "Thank you",
                    "再见": "Goodbye"
                ]
                translatedText = translations[text] ?? "Translation not available"
            } else if self.sourceLanguage.code.starts(with: "en") && self.targetLanguage.code.starts(with: "zh") {
                // 英文到中文的简单映射
                let translations = [
                    "Hello": "你好",
                    "Good morning": "早上好",
                    "Good evening": "晚上好",
                    "Thank you": "谢谢",
                    "Goodbye": "再见"
                ]
                translatedText = translations[text] ?? "翻译不可用"
            } else {
                translatedText = "Translation from \(self.sourceLanguage.name) to \(self.targetLanguage.name): \(text)"
            }
            
            completion(translatedText)
        }
    }
    
    // 朗读翻译结果
    func speakTranslation() {
        guard !translation.isEmpty else { return }
        
        let utterance = AVSpeechUtterance(string: translation)
        utterance.voice = AVSpeechSynthesisVoice(language: targetLanguage.code)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        speechSynthesizer.speak(utterance)
    }
    
    // 清除对话历史
    func clearConversations() {
        conversations.removeAll()
    }
} 
