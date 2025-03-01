import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: TranslationViewModel
    @State private var speechRate: Double = 0.5
    @State private var autoPlay: Bool = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("语音设置")) {
                    VStack(alignment: .leading) {
                        Text("语音速度: \(String(format: "%.1f", speechRate))")
                        Slider(value: $speechRate, in: 0.1...1.0, step: 0.1)
                    }
                    
                    Toggle("自动朗读翻译结果", isOn: $autoPlay)
                }
                
                Section(header: Text("权限")) {
                    HStack {
                        Text("麦克风权限")
                        Spacer()
                        if viewModel.microphonePermissionGranted {
                            Text("已授权")
                                .foregroundColor(.green)
                        } else {
                            Button("请求权限") {
                                viewModel.requestPermissions()
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    
                    HStack {
                        Text("语音识别权限")
                        Spacer()
                        if viewModel.hasPermission {
                            Text("已授权")
                                .foregroundColor(.green)
                        } else {
                            Button("请求权限") {
                                viewModel.requestPermissions()
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
                
                Section(header: Text("关于")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("隐私政策", destination: URL(string: "https://example.com/privacy")!)
                    
                    Link("使用条款", destination: URL(string: "https://example.com/terms")!)
                }
            }
            .navigationTitle("设置")
        }
    }
} 
