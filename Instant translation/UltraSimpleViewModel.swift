import Foundation
import Speech
import AVFoundation

class UltraSimpleViewModel: ObservableObject {
    @Published var transcription = ""
    @Published var isRecording = false
    @Published var statusMessage = "准备就绪"
    
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    
    func startRecording() {
        // 重置状态
        transcription = ""
        isRecording = true
        statusMessage = "开始录音..."
        
        // 请求权限
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if status != .authorized {
                    self.statusMessage = "语音识别权限未授权"
                    self.isRecording = false
                    return
                }
                
                // 继续设置录音
                self.setupRecording()
            }
        }
    }
    
    private func setupRecording() {
        // 停止任何现有的任务
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        // 设置音频会话
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            statusMessage = "设置音频会话失败"
            isRecording = false
            return
        }
        
        // 创建识别请求
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest,
              let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            statusMessage = "语音识别不可用"
            isRecording = false
            return
        }
        
        // 配置音频输入
        let inputNode = audioEngine.inputNode
        recognitionRequest.shouldReportPartialResults = true
        
        // 开始识别任务
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    self.transcription = result.bestTranscription.formattedString
                }
            }
            
            if error != nil || (result?.isFinal ?? false) {
                DispatchQueue.main.async {
                    self.stopRecording()
                    self.statusMessage = error != nil ? "识别出错" : "识别完成"
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
            statusMessage = "正在录音..."
        } catch {
            statusMessage = "启动录音失败"
            isRecording = false
            stopRecording()
        }
    }
    
    func stopRecording() {
        // 停止音频引擎
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // 结束识别请求
        recognitionRequest?.endAudio()
        
        // 取消识别任务
        recognitionTask?.cancel()
        
        // 清理资源
        recognitionRequest = nil
        recognitionTask = nil
        
        // 更新状态
        isRecording = false
        statusMessage = "录音已停止"
        
        // 重置音频会话
        try? AVAudioSession.sharedInstance().setActive(false)
    }
} 
