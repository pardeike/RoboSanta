// StdoutMonitor.swift
// Captures process stdout for display in the dashboard.

import Foundation
import Combine
import Darwin

/// Tees stdout into an in-memory buffer so the dashboard can render recent lines.
final class StdoutMonitor: ObservableObject {
    static let shared = StdoutMonitor()
    
    @Published private(set) var lines: [String] = []
    
    private let maxLines: Int
    private let captureQueue = DispatchQueue(label: "StdoutMonitor.CaptureQueue")
    private var pendingFragment = ""
    private var stdoutPipe: Pipe?
    private var originalStdout: Int32 = -1
    private var originalStdoutHandle: FileHandle?
    
    private init(maxLines: Int = 400) {
        self.maxLines = maxLines
        startCapture()
    }
    
    private func startCapture() {
        guard stdoutPipe == nil else { return }
        
        let pipe = Pipe()
        stdoutPipe = pipe
        
        originalStdout = dup(STDOUT_FILENO)
        if originalStdout != -1 {
            originalStdoutHandle = FileHandle(fileDescriptor: originalStdout, closeOnDealloc: false)
        }
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            guard let self else { return }
            let data = handle.availableData
            guard !data.isEmpty else { return }
            self.captureQueue.async { [weak self] in
                self?.handleIncoming(data)
            }
        }
    }
    
    private func handleIncoming(_ data: Data) {
        mirrorToOriginal(data: data)
        guard let text = String(data: data, encoding: .utf8) else { return }
        ingest(text)
    }
    
    private func mirrorToOriginal(data: Data) {
        originalStdoutHandle?.write(data)
    }
    
    private func ingest(_ text: String) {
        let combined = pendingFragment + text
        let segments = combined.components(separatedBy: .newlines)
        pendingFragment = segments.last ?? ""
        
        for line in segments.dropLast() {
            appendLine(line)
        }
    }
    
    private func appendLine(_ line: String) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.lines.append(line)
            if self.lines.count > self.maxLines {
                self.lines.removeFirst(self.lines.count - self.maxLines)
            }
        }
    }
}
