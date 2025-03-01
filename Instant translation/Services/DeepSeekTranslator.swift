import Foundation
import Combine

class DeepSeekTranslator {
    private var apiKey: String {
        // 优先从环境变量获取 API 密钥
        return EnvironmentManager.shared.getValue(forKey: "DEEPSEEK_API_KEY") ?? 
               KeychainHelper.getAPIKey(for: "DeepSeekAPI") ?? ""
    }
    private let apiEndpoint = "https://api.deepseek.com/v1/chat/completions"  // 请替换为实际的 DeepSeek API 端点
    
    init() {
        // 不再需要在初始化时传递 API 密钥
    }
    
    func translate(text: String, from sourceLanguage: String, to targetLanguage: String) -> AnyPublisher<String, Error> {
        // 检查 API 密钥是否为空
        guard !apiKey.isEmpty else {
            return Fail(error: NSError(domain: "DeepSeekTranslator", code: 401, 
                                      userInfo: [NSLocalizedDescriptionKey: "API 密钥未设置"]))
                .eraseToAnyPublisher()
        }
        
        // 构建请求
        var request = URLRequest(url: URL(string: apiEndpoint)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // 构建请求体
        let requestBody: [String: Any] = [
            "model": "deepseek-chat",  // 使用适当的 DeepSeek 模型
            "messages": [
                ["role": "system", "content": "你是一个专业的翻译助手，请将以下文本从\(sourceLanguage)翻译成\(targetLanguage)，只返回翻译结果，不要添加任何解释或额外内容。"],
                ["role": "user", "content": text]
            ],
            "temperature": 0.3  // 较低的温度以获得更确定的翻译
        ]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: requestBody)
        request.httpBody = jsonData
        
        // 发送请求并处理响应
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: DeepSeekResponse.self, decoder: JSONDecoder())
            .map { response in
                // 从响应中提取翻译文本
                if let content = response.choices.first?.message.content {
                    return content
                } else {
                    return "翻译失败"
                }
            }
            .eraseToAnyPublisher()
    }
}

// DeepSeek API 响应模型
struct DeepSeekResponse: Decodable {
    let choices: [Choice]
    
    struct Choice: Decodable {
        let message: Message
    }
    
    struct Message: Decodable {
        let content: String
    }
} 
