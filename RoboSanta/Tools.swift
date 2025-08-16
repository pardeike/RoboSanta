import FoundationModels
import AVFoundation

protocol Think {
    func generateText(_ prompt: String) async -> String?
}

protocol Speak {
    func say(_ text: String) async
}

func outputError(errorDescription: String, errorCode: UInt32) {
    print("### ERROR \(errorCode): \(errorDescription)")
}

func getAPIKey(_ name: String) -> String? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrLabel as String: name,
        kSecReturnData as String: kCFBooleanTrue!,
        kSecMatchLimit as String: kSecMatchLimitOne
    ]
    
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    
    guard status == errSecSuccess else {
        print("Error getting keychain item: \(SecCopyErrorMessageString(status, nil) ?? "Unknown error" as CFString)")
        return nil
    }
    
    if let data = item as? Data,
       let key = String(data: data, encoding: .utf8) {
        return key
    }
    
    return nil
}
