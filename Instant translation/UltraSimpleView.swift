import SwiftUI

struct UltraSimpleView: View {
    @StateObject private var viewModel = UltraSimpleViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("超简版语音识别")
                .font(.title)
                .padding()
            
            Text(viewModel.statusMessage)
                .foregroundColor(.secondary)
                .padding()
            
            if !viewModel.transcription.isEmpty {
                Text(viewModel.transcription)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            Button(action: {
                if viewModel.isRecording {
                    viewModel.stopRecording()
                } else {
                    viewModel.startRecording()
                }
            }) {
                Text(viewModel.isRecording ? "停止录音" : "开始录音")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(viewModel.isRecording ? Color.red : Color.blue)
                    .cornerRadius(10)
            }
            .padding(.bottom, 40)
        }
    }
} 
