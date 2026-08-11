import Foundation
import Security

// MARK: - Thread-safe iOS Keychain Helper for Biometric / Saved Auth
final class KeychainHelper {
    static let shared = KeychainHelper()
    private let serviceName = "com.ellegnote.app.auth"
    
    private init() {}
    
    // MARK: - Save Email & Password
    func saveCredentials(email: String, pass: String) {
        guard let emailData = email.data(using: .utf8),
              let passData = pass.data(using: .utf8) else { return }
        
        save(key: "userEmail", data: emailData)
        save(key: "userPass", data: passData)
    }
    
    // MARK: - Read Email & Password
    func readCredentials() -> (email: String, pass: String)? {
        guard let emailData = read(key: "userEmail"),
              let passData = read(key: "userPass"),
              let email = String(data: emailData, encoding: .utf8),
              let pass = String(data: passData, encoding: .utf8),
              !email.isEmpty, !pass.isEmpty else {
            return nil
        }
        return (email, pass)
    }
    
    // MARK: - Delete Credentials
    func deleteCredentials() {
        delete(key: "userEmail")
        delete(key: "userPass")
    }
    
    // MARK: - Low-level Keychain API wrapper
    private func save(key: String, data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        // Delete existing key if present
        SecItemDelete(query as CFDictionary)
        
        var newQuery = query
        newQuery[kSecValueData as String] = data
        newQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        
        SecItemAdd(newQuery as CFDictionary, nil)
    }
    
    private func read(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            return dataTypeRef as? Data
        }
        return nil
    }
    
    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
