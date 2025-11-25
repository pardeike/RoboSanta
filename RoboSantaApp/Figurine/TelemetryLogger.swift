import Foundation

final class TelemetryLogger {
    static let shared = TelemetryLogger()
    
    private let queue = DispatchQueue(label: "RoboSanta.TelemetryLogger")
    private let fileURL: URL
    private var fileHandle: FileHandle?
    
    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? TelemetryLogger.resolveDefaultURL()
        prepareFile()
    }
    
    deinit {
        queue.sync {
            try? fileHandle?.close()
            fileHandle = nil
        }
    }
    
    func serialize(_ payload: [String: Any]) -> String? {
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]),
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }
    
    func write(line: String) {
        if ProcessInfo.isRunningInSwiftUIPreview { return }
        queue.async {
            guard let data = (line + "\n").data(using: .utf8) else { return }
            if self.fileHandle == nil {
                self.fileHandle = try? FileHandle(forWritingTo: self.fileURL)
            }
            guard let handle = self.fileHandle else { return }
            do {
                try handle.seekToEnd()
                handle.write(data)
            } catch {
                print("Telemetry write error: \(error)")
            }
        }
    }
    
    private func prepareFile() {
        if ProcessInfo.isRunningInSwiftUIPreview { return }
        queue.sync {
            let fm = FileManager.default
            let dir = fileURL.deletingLastPathComponent()
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
            if fm.fileExists(atPath: fileURL.path) {
                try? fm.removeItem(at: fileURL)
            }
            fm.createFile(atPath: fileURL.path, contents: nil)
            fileHandle = try? FileHandle(forWritingTo: fileURL)
        }
    }
    
    private static func resolveDefaultURL() -> URL {
        return URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // now in Figurine
            .deletingLastPathComponent() // now in RoboSantaApp
            .appendingPathComponent("telemetry.json")
    }
}
