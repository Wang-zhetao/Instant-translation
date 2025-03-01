import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: TranslationViewModel
    @State private var speechRate: Double = 0.5
    @State private var autoPlay: Bool = true
    @State private var deepSeekAPIKey: String = EnvironmentManager.shared.getValue(forKey: "DEEPSEEK_API_KEY") ?? 
                                               KeychainHelper.getAPIKey(for: "DeepSeekAPI") ?? ""
    @State private var showAPIKeyAlert = false
    @State private var apiKeySaveMethod = "env" // "env" 或 "keychain"
    
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
                
                Section(header: Text("DeepSeek API 设置")) {
                    SecureField("API 密钥", text: $deepSeekAPIKey)
                    
                    Picker("存储方式", selection: $apiKeySaveMethod) {
                        Text(".env 文件").tag("env")
                        Text("钥匙串").tag("keychain")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Button("保存 API 密钥") {
                        var saveSuccess = false
                        
                        if apiKeySaveMethod == "env" {
                            saveSuccess = EnvironmentManager.shared.saveValue(deepSeekAPIKey, forKey: "DEEPSEEK_API_KEY")
                        } else {
                            saveSuccess = KeychainHelper.saveAPIKey(deepSeekAPIKey, for: "DeepSeekAPI")
                        }
                        
                        if saveSuccess {
                            showAPIKeyAlert = true
                        }
                    }
                    .alert(isPresented: $showAPIKeyAlert) {
                        Alert(
                            title: Text("成功"),
                            message: Text("API 密钥已保存到\(apiKeySaveMethod == "env" ? " .env 文件" : "钥匙串")"),
                            dismissButton: .default(Text("确定"))
                        )
                    }
                    
                    Text("请从 DeepSeek 官网获取 API 密钥")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if apiKeySaveMethod == "env" {
                        Text(".env 文件存储适合开发环境，可以与版本控制系统一起使用（记得添加到 .gitignore）")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("钥匙串存储更安全，适合生产环境")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
        }
    }
} 
