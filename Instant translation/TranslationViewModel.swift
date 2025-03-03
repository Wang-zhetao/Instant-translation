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
    @Published var microphonePermissionGranted = false
    @Published var debugMessage: String?
    
    // 语音识别
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // 语音合成
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    // 在 TranslationViewModel 类中添加 DeepSeek 翻译服务
    private let deepSeekTranslator: DeepSeekTranslator
    private var translationCancellable: AnyCancellable?
    
    init() {
        // 初始化 DeepSeek 翻译服务（不再需要传递 API 密钥）
        self.deepSeekTranslator = DeepSeekTranslator()
        
        self.sourceLanguage = availableLanguages[0] // 默认中文
        self.targetLanguage = availableLanguages[1] // 默认英语
        
        // 设置语音识别器
        updateSpeechRecognizer()
        
        // 请求所有必要的权限
        initializePermissions()
    }
    
    private func updateSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: sourceLanguage.code))
    }
    
    private func initializePermissions() {
        requestPermissions()
    }
    
    // 公共方法，用于从设置界面请求权限
    func requestPermissions() {
        // 请求麦克风权限
        #if swift(>=5.9) && canImport(AVFAudio) && os(iOS)
        if #available(iOS 17.0, *) {
            // iOS 17+ 使用新的 API
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.microphonePermissionGranted = granted
                    if !granted {
                        self?.errorMessage = "需要麦克风权限才能使用录音功能"
                        self?.debugMessage = "麦克风权限被拒绝"
                    } else {
                        self?.debugMessage = "麦克风权限已授权"
                    }
                }
            }
        } else {
            // iOS 16 及以下使用旧的 API
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.microphonePermissionGranted = granted
                    if !granted {
                        self?.errorMessage = "需要麦克风权限才能使用录音功能"
                        self?.debugMessage = "麦克风权限被拒绝"
                    } else {
                        self?.debugMessage = "麦克风权限已授权"
                    }
                }
            }
        }
        #else
        // 非 iOS 17 环境
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.microphonePermissionGranted = granted
                if !granted {
                    self?.errorMessage = "需要麦克风权限才能使用录音功能"
                    self?.debugMessage = "麦克风权限被拒绝"
                } else {
                    self?.debugMessage = "麦克风权限已授权"
                }
            }
        }
        #endif
        
        // 请求语音识别权限
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.hasPermission = status == .authorized
                if status != .authorized {
                    self?.errorMessage = "需要语音识别权限才能使用此应用"
                    self?.debugMessage = "语音识别权限状态: \(status.rawValue)"
                } else {
                    self?.debugMessage = "语音识别权限已授权"
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
        debugMessage = "开始录音函数被调用"
        
        // 检查权限
        guard microphonePermissionGranted && hasPermission else {
            errorMessage = "需要麦克风和语音识别权限"
            return
        }
        
        // 停止任何正在进行的任务
        stopRecording()
        
        // 设置音频会话
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setPreferredIOBufferDuration(0.005) // 5ms buffer duration
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "设置音频会话失败"
            return
        }
        
        // 创建识别请求
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        // 设置语音识别器
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: sourceLanguage.code))
        
        guard let recognitionRequest = recognitionRequest, 
              let speechRecognizer = speechRecognizer else {
            errorMessage = "无法创建语音识别请求"
            return
        }
        
        // 配置音频
        let inputNode = audioEngine.inputNode
        
        // 使用输入节点的原始格式
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        debugMessage = "使用音频格式: \(recordingFormat.description)"
        
        // 移除现有的 tap
        inputNode.removeTap(onBus: 0)
        
        // 安装音频 tap，使用较大的缓冲区
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // 启动音频引擎
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isRecording = true
            
            // 开始识别
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    DispatchQueue.main.async {
                        self.transcription = result.bestTranscription.formattedString
                    }
                }
                
                if error != nil || (result?.isFinal ?? false) {
                    self.stopRecording()
                    
                    if !self.transcription.isEmpty {
                        self.translateText()
                    }
                }
            }
        } catch {
            errorMessage = "启动音频引擎失败"
            stopRecording()
        }
    }
    
    // 停止录音
    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            recognitionRequest?.endAudio()
        }
        
        recognitionTask?.cancel()
        
        // 清理资源
        recognitionRequest = nil
        recognitionTask = nil
        
        isRecording = false
    }
    
    // 翻译文本
    func translateText() {
        guard !transcription.isEmpty else { return }
        
        isTranslating = true
        
        // 使用 DeepSeek 进行翻译
        translationCancellable = deepSeekTranslator.translate(
            text: transcription,
            from: sourceLanguage.name,
            to: targetLanguage.name
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                self.isTranslating = false
                
                if case .failure(let error) = completion {
                    self.errorMessage = "翻译失败: \(error.localizedDescription)"
                    // 如果 DeepSeek 翻译失败，可以回退到模拟翻译
                    self.simulateTranslation(text: self.transcription) { translatedText in
                        self.handleTranslationResult(translatedText)
                    }
                }
            },
            receiveValue: { [weak self] translatedText in
                guard let self = self else { return }
                
                self.handleTranslationResult(translatedText)
            }
        )
    }
    
    // 处理翻译结果的辅助方法
    private func handleTranslationResult(_ translatedText: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.translation = translatedText
            
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
    
    // 添加这个计算属性，使 audioEngine.isRunning 可以从视图访问
    var isAudioEngineRunning: Bool {
        return audioEngine.isRunning
    }
} 
