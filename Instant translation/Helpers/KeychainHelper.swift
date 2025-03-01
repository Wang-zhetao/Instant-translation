import Foundation
import Security

class KeychainHelper {
    static func saveAPIKey(_ apiKey: String, for service: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecValueData as String: apiKey.data(using: .utf8)!
        ]
        
        // 删除可能存在的旧密钥
        SecItemDelete(query as CFDictionary)
        
        // 添加新密钥
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    static func getAPIKey(for service: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let data = result as? Data, let apiKey = String(data: data, encoding: .utf8) {
            return apiKey
        }
        
        return nil
    }
} 
