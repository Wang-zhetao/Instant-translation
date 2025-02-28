import SwiftUI

struct TranslationView: View {
    @EnvironmentObject var viewModel: TranslationViewModel
    @State private var isShowingHistory = false
    
    var body: some View {
        NavigationView {
            VStack {
                // 语言选择区域
                HStack {
                    Text(viewModel.sourceLanguage.name)
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    
                    Button(action: viewModel.swapLanguages) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 8)
                    
                    Text(viewModel.targetLanguage.name)
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                }
                .padding()
                
                // 转录和翻译区域
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if !viewModel.transcription.isEmpty {
                            TranscriptionCard(
                                text: viewModel.transcription,
                                language: viewModel.sourceLanguage.name
                            )
                        }
                        
                        if !viewModel.translation.isEmpty {
                            TranslationCard(
                                text: viewModel.translation,
                                language: viewModel.targetLanguage.name
                            )
                        }
                        
                        if viewModel.isTranslating {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(1.5)
                                Spacer()
                            }
                            .padding()
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .padding(.horizontal)
                
                Spacer()
                
                // 录音按钮
                VStack {
                    Button(action: {
                        if viewModel.isRecording {
                            viewModel.stopRecording()
                        } else {
                            viewModel.startRecording()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(viewModel.isRecording ? Color.red : Color.blue)
                                .frame(width: 80, height: 80)
                            
                            if viewModel.isRecording {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    Text(viewModel.isRecording ? "点击停止" : "点击开始录音")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("实时翻译")
            .navigationBarItems(
                trailing: Button(action: {
                    isShowingHistory.toggle()
                }) {
                    Image(systemName: "clock")
                        .font(.title2)
                }
            )
            .sheet(isPresented: $isShowingHistory) {
                ConversationHistoryView()
                    .environmentObject(viewModel)
            }
        }
    }
}

struct TranscriptionCard: View {
    let text: String
    let language: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(language)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(text)
                .font(.body)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
}

struct TranslationCard: View {
    let text: String
    let language: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(language)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(text)
                .font(.body)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
}

struct ConversationHistoryView: View {
    @EnvironmentObject var viewModel: TranslationViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.conversations.isEmpty {
                    Text("暂无对话历史")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(viewModel.conversations) { conversation in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(conversation.sourceLanguage.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(conversation.timestamp, style: .time)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(conversation.sourceText)
                                .font(.body)
                            
                            Divider()
                            
                            Text(conversation.targetLanguage.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(conversation.translatedText)
                                .font(.body)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("对话历史")
            .navigationBarItems(
                leading: Button("关闭") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("清除") {
                    viewModel.clearConversations()
                }
                .disabled(viewModel.conversations.isEmpty)
            )
        }
    }
} 
