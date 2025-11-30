// QRCodeGenerator.swift
// Generates QR code images for the dashboard.

import SwiftUI
import CoreImage.CIFilterBuiltins
import AppKit

/// Utility to generate QR code images.
enum QRCodeGenerator {
    
    /// The GitHub URL for the RoboSanta project
    static let gitHubURL = "https://github.com/pardeike/RoboSanta"
    
    /// Generates a QR code NSImage for the given string.
    /// - Parameters:
    ///   - string: The string to encode in the QR code
    ///   - size: The desired size of the QR code image
    /// - Returns: An NSImage containing the QR code, or nil if generation fails
    static func generate(for string: String, size: CGFloat = 200) -> NSImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        
        guard let outputImage = filter.outputImage else { return nil }
        
        // Scale the QR code to the desired size
        let scaleX = size / outputImage.extent.size.width
        let scaleY = size / outputImage.extent.size.height
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        
        return NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))
    }
    
    /// Generates a QR code Image for SwiftUI.
    /// - Parameters:
    ///   - string: The string to encode in the QR code
    ///   - size: The desired size of the QR code image
    /// - Returns: A SwiftUI Image containing the QR code
    static func generateSwiftUIImage(for string: String, size: CGFloat = 200) -> Image? {
        guard let nsImage = generate(for: string, size: size) else { return nil }
        return Image(nsImage: nsImage)
    }
    
    /// Generates a QR code for the GitHub project URL.
    /// - Parameter size: The desired size of the QR code image
    /// - Returns: An NSImage containing the QR code for the GitHub URL
    static func generateGitHubQRCode(size: CGFloat = 200) -> NSImage? {
        return generate(for: gitHubURL, size: size)
    }
}

/// A SwiftUI view that displays a QR code.
struct QRCodeView: View {
    let url: String
    let size: CGFloat
    let label: String
    
    init(url: String = QRCodeGenerator.gitHubURL, size: CGFloat = 150, label: String = "Skanna för mer information") {
        self.url = url
        self.size = size
        self.label = label
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if let qrImage = QRCodeGenerator.generateSwiftUIImage(for: url, size: size) {
                qrImage
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .background(Color.white)
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size, height: size)
                    .overlay(
                        Text("QR")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    )
                    .cornerRadius(8)
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Preview

#Preview {
    QRCodeView()
        .padding()
        .background(Color.black)
}
