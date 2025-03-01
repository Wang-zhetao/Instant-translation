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
    
    // 语音识别
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    init() {
        checkPermissions()
    }
    
    private func checkPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                if status != .authorized {
                    self?.debugMessage = "语音识别权限未授权"
                } else {
                    self?.debugMessage = "语音识别权限已授权"
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
        
        // 检查语音识别器是否可用
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            debugMessage = "语音识别器不可用"
            errorMessage = "语音识别器不可用，请确保您的设备支持语音识别"
            return
        }
        
        // 请求麦克风权限
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            guard let self = self else { return }
            
            if !granted {
                DispatchQueue.main.async {
                    self.debugMessage = "麦克风权限被拒绝"
                    self.errorMessage = "需要麦克风权限才能使用录音功能"
                }
                return
            }
            
            DispatchQueue.main.async {
                self.debugMessage = "开始录音..."
                self.setupAudioSession()
            }
        }
    }
    
    private func setupAudioSession() {
        // 设置音频会话
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            debugMessage = "设置音频会话失败: \(error.localizedDescription)"
            return
        }
        
        // 创建识别请求
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        // 确保有输入节点
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            debugMessage = "无法创建语音识别请求"
            return
        }
        
        // 配置请求
        recognitionRequest.shouldReportPartialResults = true
        
        // 开始识别任务
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
            
            if error != nil || isFinal {
                // 停止音频引擎
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                DispatchQueue.main.async {
                    self.isRecording = false
                    if let error = error {
                        self.debugMessage = "识别错误: \(error.localizedDescription)"
                    } else {
                        self.debugMessage = "识别完成"
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
            debugMessage = "音频引擎启动成功"
        } catch {
            debugMessage = "音频引擎启动失败: \(error.localizedDescription)"
            isRecording = false
        }
    }
    
    private func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        
        // 清理资源
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        
        // 更新状态
        isRecording = false
        debugMessage = "录音已停止"
        
        // 重置音频会话
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            debugMessage = "重置音频会话失败: \(error.localizedDescription)"
        }
    }
    
    var isAudioEngineRunning: Bool {
        return audioEngine.isRunning
    }
} 
