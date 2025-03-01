import SwiftUI

// 首先定义 AlertItem 结构体
struct SimpleAlertItem: Identifiable {
    let id = UUID()
    let message: String
}

struct SimpleTranslationView: View {
    @StateObject private var viewModel = SimpleTranslationViewModel()
    @State private var alertItem: SimpleAlertItem? = nil
    
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
            }
            
            Spacer()
            
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
            
            if let debugMessage = viewModel.debugMessage {
                Text("调试: \(debugMessage)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
            }
            
            Spacer()
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
