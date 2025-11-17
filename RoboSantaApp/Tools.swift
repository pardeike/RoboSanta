import FoundationModels
import AVFoundation

protocol Think {
    func generateText(_ prompt: String, _ model: Model) async -> Answer?
}

protocol Speak {
    func say(_ label: String, _ text: String) async
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

func fixQuiz(_ answer: Answer) -> (String, String, String, String) {
    let q = answer.value("question")
    let a1 = answer.value("answer1")
    var lines = a1.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { $0 != "" }
    if lines.count == 3 {
        print("Fixing quiz answer")
        lines = lines.map { String($0.replacing(/^[ABC]: ]/, with: "")) }
        return (q, lines[0], lines[1], lines[2])
    }
    let a2 = answer.value("answer2")
    let a3 = answer.value("answer3")
    return (q, a1, a2, a3)
}

func exactTime() -> String { Date().formatted(date: .omitted, time: .shortened) }

func fuzzyEnglishTime() -> String {
    let calendar = Calendar(identifier: .gregorian)
    let comps = calendar.dateComponents([.hour, .minute], from: Date())
    guard var hour24 = comps.hour, var minute = comps.minute else { return "" }
    
    // Round to nearest 5 minutes
    let remainder = minute % 5
    if remainder < 3 {
        minute -= remainder
    } else {
        minute += (5 - remainder)
    }
    if minute == 60 {
        minute = 0
        hour24 += 1
    }
    
    // Convert to 12h format
    var hour = hour24 % 12
    if hour == 0 { hour = 12 }
    let isPM = hour24 >= 12
    let ampm = isPM ? "PM" : "AM"
    
    // Phrasing
    switch minute {
    case 0:
        return "\(hour) o’clock \(ampm)"
    case 15:
        return "quarter past \(hour) \(ampm)"
    case 30:
        return "half past \(hour) \(ampm)"
    case 45:
        return "quarter to \(hour == 12 ? 1 : hour + 1) \(ampm)"
    case 5..<30:
        return "\(minute) past \(hour) \(ampm)"
    case 35..<60:
        let toMinutes = 60 - minute
        return "\(toMinutes) to \(hour == 12 ? 1 : hour + 1) \(ampm)"
    default:
        return "\(hour):\(String(format: "%02d", minute)) \(ampm)" // fallback
    }
}

extension Character {
    var isEmoji: Bool {
        unicodeScalars.contains { $0.properties.isEmoji } &&
        (unicodeScalars.count > 1 ||
         unicodeScalars.first?.properties.isEmojiPresentation == true)
    }
}

extension String {
    func removingEmojis() -> String {
        self.filter { !$0.isEmoji }
    }
}

enum JSONValue: Swift.Encodable {
    case string(String), number(Double), bool(Bool)
    case object([String: JSONValue]), array([JSONValue])
    case null

    func encode(to encoder: Swift.Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let v): try c.encode(v)
        case .number(let v): try c.encode(v)
        case .bool(let v):   try c.encode(v)
        case .object(let v): try c.encode(v)  // [String: JSONValue] is Encodable
        case .array(let v):  try c.encode(v)  // [JSONValue] is Encodable
        case .null:          try c.encodeNil()
        }
    }
}
