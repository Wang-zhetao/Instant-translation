import SwiftUI

// 首先定义 AlertItem 结构体
struct SimpleAlertItem: Identifiable {
    let id = UUID()
    let message: String
}

struct SimpleTranslationView: View {
    @StateObject private var viewModel = SimpleTranslationViewModel()
    @State private var alertItem: SimpleAlertItem? = nil
    @State private var showDebugInfo = true // 默认显示调试信息
    
    var body: some View {
        VStack {
            Text("简化版语音识别")
                .font(.title)
                .padding()
            
            if !viewModel.transcription.isEmpty {
                Text("识别结果:")
                    .font(.headline)
                    .padding(.top)
                
                Text(viewModel.transcription)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
            } else {
                Text("等待语音输入...")
                    .foregroundColor(.gray)
                    .padding()
            }
            
            Spacer()
            
            // 录音按钮
            Button(action: {
                viewModel.toggleRecording()
            }) {
                ZStack {
                    Circle()
                        .fill(viewModel.isRecording ? Color.red : Color.blue)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
            }
            .padding()
            
            Text(viewModel.isRecording ? "点击停止" : "点击开始录音")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 调试信息开关
            Toggle("显示调试信息", isOn: $showDebugInfo)
                .padding(.horizontal)
                .padding(.top)
            
            // 调试信息区域
            if showDebugInfo {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        Group {
                            Text("调试信息:").fontWeight(.bold)
                            Text("权限状态: \(viewModel.permissionStatus)")
                            Text("录音状态: \(viewModel.isRecording ? "录音中" : "未录音")")
                            Text("音频引擎: \(viewModel.isAudioEngineRunning ? "运行中" : "已停止")")
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                        
                        Divider()
                        
                        if let debugMessage = viewModel.debugMessage {
                            Text("最新消息: \(debugMessage)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .frame(maxHeight: 150)
                .padding()
            }
        }
        .onReceive(viewModel.$errorMessage) { errorMessage in
            if let errorMessage = errorMessage {
                alertItem = SimpleAlertItem(message: errorMessage)
            }
        }
        .alert(item: $alertItem) { item in
            Alert(
                title: Text("错误"),
                message: Text(item.message),
                dismissButton: .default(Text("确定"))
            )
        }
    }
} 
