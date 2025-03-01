import Foundation

class EnvironmentManager {
    static let shared = EnvironmentManager()
    
    private var variables: [String: String] = [:]
    
    private init() {
        loadEnvironmentVariables()
    }
    
    // 从 .env 文件加载环境变量
    private func loadEnvironmentVariables() {
        guard let envPath = Bundle.main.path(forResource: ".env", ofType: nil) else {
            print("未找到 .env 文件")
            return
        }
        
        do {
            let envContent = try String(contentsOfFile: envPath, encoding: .utf8)
            let lines = envContent.components(separatedBy: .newlines)
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // 跳过空行和注释
                if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                    continue
                }
                
                // 解析 KEY=VALUE 格式
                let components = trimmedLine.components(separatedBy: "=")
                if components.count >= 2 {
                    let key = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    // 将剩余部分作为值（处理值中可能包含 = 的情况）
                    let value = components[1...].joined(separator: "=").trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // 移除可能的引号
                    let cleanValue = value.replacingOccurrences(of: "\"", with: "")
                                         .replacingOccurrences(of: "'", with: "")
                    
                    variables[key] = cleanValue
                }
            }
            
            print("成功加载 \(variables.count) 个环境变量")
        } catch {
            print("读取 .env 文件失败: \(error.localizedDescription)")
        }
    }
    
    // 获取环境变量
    func getValue(forKey key: String) -> String? {
        return variables[key]
    }
    
    // 保存环境变量到 .env 文件
    func saveValue(_ value: String, forKey key: String) -> Bool {
        variables[key] = value
        
        // 构建 .env 文件内容
        var envContent = ""
        for (k, v) in variables {
            envContent += "\(k)=\(v)\n"
        }
        
        // 获取 Documents 目录中的 .env 文件路径
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("无法访问 Documents 目录")
            return false
        }
        
        let envFileURL = documentsDirectory.appendingPathComponent(".env")
        
        do {
            try envContent.write(to: envFileURL, atomically: true, encoding: .utf8)
            print("环境变量已保存到 \(envFileURL.path)")
            
            // 复制到 Bundle 目录（仅用于开发阶段，生产环境不会生效）
            if let bundlePath = Bundle.main.path(forResource: ".env", ofType: nil) {
                try envContent.write(toFile: bundlePath, atomically: true, encoding: .utf8)
                print("环境变量已复制到 Bundle 目录")
            }
            
            return true
        } catch {
            print("保存环境变量失败: \(error.localizedDescription)")
            return false
        }
    }
} 
