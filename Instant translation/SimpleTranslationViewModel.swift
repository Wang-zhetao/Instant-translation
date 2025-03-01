import Foundation
import Speech
import AVFoundation
import Combine

class SimpleTranslationViewModel: ObservableObject {
    // 基本属性
    @Published var isRecording = false
    @Published var transcription = ""
    @Published var errorMessage: String?
    @Published var debugMessage: String?
    @Published var permissionStatus: String = "未知"
    
    // 语音识别
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // 内部状态跟踪
    private var hasSetupAudioSession = false
    
    init() {
        debugMessage = "初始化模型..."
        checkPermissions()
    }
    
    private func checkPermissions() {
        debugMessage = "检查权限..."
        
        // 检查语音识别权限
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch status {
                case .authorized:
                    self.permissionStatus = "语音识别: 已授权"
                    self.debugMessage = "语音识别权限已授权"
                case .denied:
                    self.permissionStatus = "语音识别: 被拒绝"
                    self.debugMessage = "语音识别权限被拒绝"
                case .restricted:
                    self.permissionStatus = "语音识别: 受限"
                    self.debugMessage = "语音识别权限受限"
                case .notDetermined:
                    self.permissionStatus = "语音识别: 未确定"
                    self.debugMessage = "语音识别权限未确定"
                @unknown default:
                    self.permissionStatus = "语音识别: 未知状态"
                    self.debugMessage = "语音识别权限状态未知"
                }
            }
        }
    }
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        // 重置状态
        transcription = ""
        debugMessage = "准备开始录音..."
        
        // 检查语音识别器是否存在
        guard let speechRecognizer = speechRecognizer else {
            debugMessage = "语音识别器未初始化"
            errorMessage = "语音识别器未初始化"
            return
        }
        
        // 检查语音识别器是否可用
        guard speechRecognizer.isAvailable else {
            debugMessage = "语音识别器不可用"
            errorMessage = "语音识别器不可用，请确保您的设备支持语音识别"
            return
        }
        
        // 检查是否已经正在录音
        if isRecording {
            debugMessage = "已经在录音中，无需重复启动"
            return
        }
        
        // 确保之前的录音已经停止
        stopRecording()
        
        // 请求麦克风权限
        requestMicrophonePermission()
    }
    
    private func requestMicrophonePermission() {
        debugMessage = "请求麦克风权限..."
        
        // 针对不同 iOS 版本使用不同的 API
        if #available(iOS 17.0, *) {
            // iOS 17+ 使用新的 API
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if granted {
                        self.debugMessage = "麦克风权限已授权"
                        self.setupAudioSession()
                    } else {
                        self.debugMessage = "麦克风权限被拒绝"
                        self.errorMessage = "需要麦克风权限才能使用录音功能"
                    }
                }
            }
        } else {
            // iOS 16 及以下使用旧的 API
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if granted {
                        self.debugMessage = "麦克风权限已授权"
                        self.setupAudioSession()
                    } else {
                        self.debugMessage = "麦克风权限被拒绝"
                        self.errorMessage = "需要麦克风权限才能使用录音功能"
                    }
                }
            }
        }
    }
    
    private func setupAudioSession() {
        debugMessage = "设置音频会话..."
        
        // 验证我们是否已经在主线程上
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.setupAudioSession()
            }
            return
        }
        
        // 设置音频会话
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // 使用最简单的配置
            try audioSession.setCategory(.record)
            try audioSession.setMode(.default)
            try audioSession.setActive(true)
            debugMessage = "音频会话配置成功"
            hasSetupAudioSession = true
            
            // 继续设置语音识别
            setupSpeechRecognition()
        } catch let error as NSError {
            debugMessage = "设置音频会话失败: \(error.localizedDescription), 错误码: \(error.code)"
            errorMessage = "无法设置录音环境，请重试"
            hasSetupAudioSession = false
        }
    }
    
    private func setupSpeechRecognition() {
        debugMessage = "设置语音识别..."
        
        // 创建识别请求
        do {
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        } catch {
            debugMessage = "创建语音识别请求失败: \(error.localizedDescription)"
            errorMessage = "无法创建语音识别请求"
            return
        }
        
        guard let recognitionRequest = recognitionRequest else {
            debugMessage = "无法创建语音识别请求"
            errorMessage = "无法创建语音识别请求"
            return
        }
        
        // 配置请求
        recognitionRequest.shouldReportPartialResults = true
        
        // 确保有输入节点
        let inputNode = audioEngine.inputNode
        debugMessage = "获取到音频输入节点"
        
        // 配置音频格式
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        debugMessage = "音频格式: \(recordingFormat.description)"
        
        // 安装音频 tap
        do {
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }
            debugMessage = "音频 tap 安装成功"
        } catch {
            debugMessage = "安装音频 tap 失败: \(error.localizedDescription)"
            errorMessage = "无法设置音频输入"
            return
        }
        
        // 开始识别任务
        debugMessage = "启动语音识别任务..."
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                // 更新转录文本
                DispatchQueue.main.async {
                    self.transcription = result.bestTranscription.formattedString
                    self.debugMessage = "识别到: \(self.transcription)"
                }
                isFinal = result.isFinal
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.debugMessage = "识别错误: \(error.localizedDescription)"
                }
            }
            
            if error != nil || isFinal {
                DispatchQueue.main.async {
                    self.stopRecording()
                    self.debugMessage = error != nil ? "因错误停止录音" : "识别完成"
                }
            }
        }
        
        // 启动音频引擎
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            debugMessage = "音频引擎启动成功"
            isRecording = true
        } catch {
            debugMessage = "音频引擎启动失败: \(error.localizedDescription)"
            errorMessage = "无法启动录音"
            isRecording = false
            
            // 清理资源
            cleanupAudioSession()
        }
    }
    
    private func stopRecording() {
        debugMessage = "停止录音..."
        
        // 停止音频引擎
        if audioEngine.isRunning {
            audioEngine.stop()
            debugMessage = "音频引擎已停止"
        }
        
        // 结束语音识别请求
        if let recognitionRequest = recognitionRequest {
            recognitionRequest.endAudio()
            debugMessage = "语音识别请求已结束"
        }
        
        // 取消语音识别任务
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            debugMessage = "语音识别任务已取消"
        }
        
        // 清理资源
        self.recognitionRequest = nil
        self.recognitionTask = nil
        
        // 更新状态
        isRecording = false
        
        // 清理音频会话
        cleanupAudioSession()
    }
    
    private func cleanupAudioSession() {
        debugMessage = "清理音频会话..."
        
        if hasSetupAudioSession {
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                debugMessage = "音频会话已禁用"
                hasSetupAudioSession = false
            } catch {
                debugMessage = "禁用音频会话失败: \(error.localizedDescription)"
            }
        }
    }
    
    var isAudioEngineRunning: Bool {
        return audioEngine.isRunning
    }
    
    deinit {
        debugMessage = "释放 ViewModel 资源"
        stopRecording()
    }
} 
